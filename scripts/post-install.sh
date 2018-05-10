#!/usr/bin/env bash

if [ ! -f /home/stack/overcloudrc ] ; then echo "No overcloudrc!" ; exit 1 ; fi

source /home/stack/overcloudrc

##########################
# Create Default Flavors #
##########################
nova flavor-create m1.tiny   auto   512   1  1
nova flavor-create m1.small  auto  1024  20  1
nova flavor-create m1.medium auto  4096  40  2
nova flavor-create m1.large  auto  8192  80  4
nova flavor-create m1.xlarge auto 16384 160  8

###################################
# create keypair from stack users public key
###################################
openstack keypair create --public-key ~/.ssh/id_rsa.pub undercloud

###########################
# Create Provider Networks #
###########################
#openstack network create --no-share --external --project admin --provider-network-type vlan --provider-segment 1708 --provider-physical-network datacentre Presentation
#openstack subnet create --allocation-pool start=172.16.40.10,end=172.16.40.240  --ip-version 4 --subnet-range 172.16.40.0/24 --gateway 172.16.40.1 --network Presentation Presentation-Subnet
#openstack network create --no-share --external --project admin --provider-network-type vlan --provider-segment 1709 --provider-physical-network datacentre Application
#openstack subnet create --allocation-pool start=172.16.41.10,end=172.16.41.240  --ip-version 4 --subnet-range 172.16.41.0/24 --gateway 172.16.41.1 --network Application Application-Subnet
#openstack network create --no-share --external --project admin --provider-network-type vlan --provider-segment 1710 --provider-physical-network datacentre Data
#openstack subnet create --allocation-pool start=172.16.42.10,end=172.16.42.240  --ip-version 4 --subnet-range 172.16.42.0/24 --gateway 172.16.42.1 --network Data Data-Subnet

#################################
# Upload RHEL 7 & Cirros Image to Glance
#################################
openstack image create --public --file ~/images/rhel-server-7.4-x86_64-kvm.qcow2 --disk-format qcow2 --container bare rhel74

openstack project create  demo2
openstack user create --project demo2 --password redhat demo2user
openstack network create --project demo2 --no-share demo2-net
openstack subnet create --project demo2 --network demo2-net --dhcp --subnet-range 172.17.100.0/24  demo2-subnet
openstack router create --project demo2 demo2-router

openstack network create --project admin --no-share admin-net
openstack subnet create --project admin --network admin-net --dhcp --subnet-range 172.17.101.0/24   admin-subnet
#openstack router create --project admin admin-router


openstack flavor create --ram 1024 --vcpus 2 --disk 20 --property evacuable=true flavor_evacuable
openstack flavor create --ram 1024 --vcpus 2 --disk 20 --property evacuable=false flavor_evacuable_false

openstack server create --flavor m1.small --key-name undercloud --image rhel74 --min 4 --max 4 no-tag
openstack server create --flavor flavor_evacuable --key-name undercloud --image rhel74 --min 2 --max 2 evacuable
openstack server create --flavor flavor_evacuable_false --key-name undercloud --image rhel74 --min 2 --max 2 not-evacuable

openstack server create --flavor m1.small --key-name undercloud --image rhel74 host1-a

openstack server create --flavor m1.small --key-name undercloud --image rhel74 host2-a

openstack server create --flavor m1.small --key-name undercloud --image rhel74 host0-a

openstack server create --flavor m1.small --key-name undercloud --image rhel74 --hint group=01ac7e74-67df-4b74-bc2a-4aebbe03125e host1-a
openstack server create --flavor m1.small --key-name undercloud --image rhel74 --hint group=01ac7e74-67df-4b74-bc2a-4aebbe03125e host1-b

openstack server create --flavor m1.small --key-name undercloud --image rhel74 --hint group=e32a046e-b8ec-43dd-9723-2f280fc54867 host2-a
openstack server create --flavor m1.small --key-name undercloud --image rhel74 --hint group=e32a046e-b8ec-43dd-9723-2f280fc54867 host2-b

openstack server create --flavor m1.small --key-name undercloud --image rhel74 --hint group=f850d07f-2cdd-4b7f-aa2a-60ebaa171c26 host0-a
openstack server create --flavor m1.small --key-name undercloud --image rhel74 --hint group=f850d07f-2cdd-4b7f-aa2a-60ebaa171c26 host0-b
