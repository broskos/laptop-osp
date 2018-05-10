#!/usr/bin/env bash

# are we root?  that's bad
if [[ $EUID -eq 0 ]]; then
  echo "Do not run as root; su - stack" 2>&1
  exit 1
fi

# are we in /home/stack? if not exit
if [ $PWD != $HOME ] ; then echo "USAGE: $0 Must be run from $HOME"; exit 1 ; fi

source ~/laptop-osp/scripts/0-site-settings.sh

source ~/stackrc
cd ~
openstack overcloud deploy --templates \
    --stack $stack_name \
    --ntp-server $ntp_server \
    --control-flavor control --compute-flavor compute --ceph-storage-flavor ceph-storage \
    --control-scale 1 --compute-scale 2 --ceph-storage-scale 1 \
    --neutron-tunnel-types vxlan --neutron-network-type vxlan \
    -e /usr/share/openstack-tripleo-heat-templates/environments/storage-environment.yaml \
    -e ~/laptop-osp/templates/environments/network-environment.yaml \
    -e ~/laptop-osp/templates/environments/cadf.yaml
#    -e ~/laptop-osp/templates/environments/network-isolation.yaml \
#    -e ~/laptop-osp/templates/environments/network-environment.yaml \
#    -e /usr/share/openstack-tripleo-heat-templates/environments/storage-environment.yaml