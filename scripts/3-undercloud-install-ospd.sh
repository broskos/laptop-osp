#!/usr/bin/env bash
# after reboot
# run as STACK user su - stack

source ~/laptop-osp/scripts/0-site-settings.sh

# are we root?  that's bad
if [[ $EUID -eq 0 ]]; then
  echo "Do not run as root; su - stack" 2>&1
  exit 1
fi

echo "Please enter your password for the stack account on your laptop: "
read -sr stack_pw
export stack_pw

# we store files in git that need to be in the
# stack users home directory, fetch them out
cp ~/laptop-osp/stack-home/* ~

# Install openstack undercloud
cd ~
openstack undercloud install
source ~/stackrc

# get images, upload to undercloud
sudo sudo yum -y install rhosp-director-images rhosp-director-images-ipa
mkdir ~/images
cd ~/images
for i in /usr/share/rhosp-director-images/overcloud-full-latest-${osp_version}.0.tar \
  /usr/share/rhosp-director-images/ironic-python-agent-latest-${osp_version}.0.tar; \
  do tar -xvf $i; done

openstack overcloud image upload

#copy your keys to your host
ssh-copy-id stack@192.168.100.1

# pull mac addresses from virsh
for i in controller compute ceph; do \
	virsh -c qemu+ssh://stack@192.168.100.1/system domiflist overcloud-$i | awk '$3 == "provision" {print $5};'; \
	done > /tmp/nodes.txt

cd ~

# Create instack file
jq . << EOF > ~/instackenv.json
{
  "ssh-user": "stack",
  "ssh-key": "$(cat ~/.ssh/id_rsa)",
  "power_manager": "nova.virt.baremetal.virtual_power_driver.VirtualPowerManager",
  "host-ip": "192.168.100.1",
  "arch": "x86_64",
  "nodes": [
    {
      "name": "overcloud-controller",
      "pm_addr": "192.168.100.1",
      "pm_password": "$(cat ~/.ssh/id_rsa)",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(sed -n 1p /tmp/nodes.txt)"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "stack"
    },
    {
      "name": "overcloud-compute",
      "pm_addr": "192.168.100.1",
      "pm_password": "$(cat ~/.ssh/id_rsa)",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(sed -n 2p /tmp/nodes.txt)"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "stack"
    },
    {
      "name": "overcloud-ceph",
      "pm_addr": "192.168.100.1",
      "pm_password": "$(cat ~/.ssh/id_rsa)",
      "pm_type": "pxe_ssh",
      "mac": [
        "$(sed -n 3p /tmp/nodes.txt)"
      ],
      "cpu": "4",
      "memory": "8192",
      "disk": "60",
      "arch": "x86_64",
      "pm_user": "stack"
    }
  ]
}
EOF

# import hardware, configure boot and introspect
openstack baremetal import --json ~/instackenv.json
openstack baremetal configure boot
openstack baremetal introspection bulk start

# tag nodes to roles, first 3 ceph, next 3 control, the rest compute
export count=0
for i in $(ironic node-list | grep -v UUID | awk '{print $2;}' \
    | sed -e /^$/d); do count=$((count + 1))
    if [ "$count" -lt 2 ]; then
        role='profile:control,boot_option:local'
    elif  [ "$count" -lt 3 ] && [ "$count" -lt 7 ]; then
        role='profile:compute,boot_option:local'
    else
        role='profile:ceph-storage,boot_option:local'
    fi
    ironic node-update $i replace properties/capabilities=\"$role\" ; done

# review tagged nodes
openstack overcloud profiles list
