#!/usr/bin/env bash

source ~/laptop-osp/va/scripts/0-site-settings.sh

# install necessary packages and start up libvirt
yum install -y rhel-guest-image-7 libguestfs-tools libvirt qemu-kvm \
   virt-manager virt-install xorg-x11-apps xauth virt-viewer libguestfs-xfs
systemctl enable libvirtd && systemctl start libvirtd

#create empty qcow2 file for a base image
cd /virt1

# create a clone of the base image and use it for the undercloud
qemu-img create -f qcow2 -b rhel7.4-guest.qcow2 undercloud.qcow2

qemu-img create -f qcow2 controller.qcow2 50G
qemu-img create -f qcow2 compute1.qcow2 50G
qemu-img create -f qcow2 compute2.qcow2 50G
qemu-img create -f qcow2 compute2.qcow2 50G
qemu-img create -f qcow2 ceph.qcow2 50G
qemu-img create -f qcow2 ceph-data1.qcow2 50G
qemu-img create -f qcow2 ceph-data2.qcow2 50G
qemu-img create -f qcow2 ceph-data3.qcow2 50G

# remove cloud-init (causes delays and problems when not used on a cloud)
virt-customize -a undercloud.qcow2 --run-command 'yum remove cloud-init* -y' --root-password password:redhat


# Create undercloud guest VM eth0 file
virt-customize -a undercloud.qcow2 --run-command 'cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth1
DEVICE="eth1"
ONBOOT="yes"
TYPE="Ethernet"
PEERDNS="yes"
IPV6INIT="no"
IPADDR=192.168.100.10
NETMASK=255.255.255.0
EOF'

#virt-customize -a undercloud.qcow2 --run-command 'cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth2
#DEVICE="eth2"
#ONBOOT="yes"
#TYPE="Ethernet"
#PEERDNS="yes"
#IPV6INIT="no"
#IPADDR=192.168.101.10
#NETMASK=255.255.255.0
#EOF'

# build undercloud VM
sudo virt-install --ram 16000 --vcpus 4 --os-variant rhel7 \
    --disk path=/mnt/nvme/undercloud.qcow2,device=disk,bus=virtio,format=qcow2 \
    --import --noautoconsole --vnc \
    --network  network=default \
    --network  network=provision \
    --name undercloud

# Build controller, compute and ceph vms
sudo virt-install --ram 20000 --vcpus 4 --os-variant rhel7 \
    --disk path=/mnt/nvme/controller.qcow2,device=disk,bus=virtio,format=qcow2 \
    --import --noautoconsole --vnc \
    --network  network=provision \
    --name controller

sudo virt-install --ram 10240 --vcpus 4 --os-variant rhel7 \
    --disk path=/mnt/ssd/compute1.qcow2,device=disk,bus=virtio,format=qcow2 \
    --cpu host-passthrough \
    --virt-type kvm \
    --import --noautoconsole --vnc \
    --network  network=provision \
    --name compute1

sudo virt-install --ram 10240 --vcpus 4 --os-variant rhel7 \
    --disk path=/mnt/ssd/compute2.qcow2,device=disk,bus=virtio,format=qcow2 \
    --cpu host-passthrough \
    --virt-type kvm \
    --import --noautoconsole --vnc \
    --network  network=provision \
    --name compute2

sudo virt-install --ram 10240 --vcpus 4 --os-variant rhel7 \
    --disk path=/mnt/ssd/compute3.qcow2,device=disk,bus=virtio,format=qcow2 \
    --cpu host-passthrough \
    --virt-type kvm \
    --import --noautoconsole --vnc \
    --network  network=provision \
    --name compute3

sudo virt-install --ram 4096 --vcpus 4 --os-variant rhel7 \
    --disk path=/mnt/ssd/ceph.qcow2,device=disk,bus=virtio,format=qcow2 \
    --disk path=/mnt/ssd/ceph-data1.qcow2,device=disk,bus=virtio,format=qcow2 \
    --disk path=/mnt/ssd/ceph-data2.qcow2,device=disk,bus=virtio,format=qcow2 \
    --disk path=/mnt/ssd/ceph-data3.qcow2,device=disk,bus=virtio,format=qcow2 \
    --import --noautoconsole --vnc \
    --network  network=provision \
    --name ceph
