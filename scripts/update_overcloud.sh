#!/usr/bin/env bash
if [ $PWD != $HOME ] ; then echo "USAGE: $0 Must be run from $HOME"; exit 1 ; fi

source ~/stackrc
cd ~
openstack overcloud update stack -i --templates \
    -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
    -e ~/laptop-osp8/templates/environments/network-environment.yaml \
    -e /usr/share/openstack-tripleo-heat-templates/environments/storage-environment.yaml \
    -e ~/laptop-osp8/templates/environments/homelab-environment.yaml \
    homelab
