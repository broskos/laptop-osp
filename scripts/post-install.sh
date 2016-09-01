#!/usr/bin/env bash

source ~/laptop-osp8/scripts/0-site-settings.sh
export webserver_url="$webserver_url/images"

## update IDs in assignment table to be the ldap usernames, easiest to just hop on a controller and do it as root.
#source ~/stackrc
#controller_ip=$(nova list  | grep controller-0|awk '{print $12}' |sed 's/ctlplane=//g')
#ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -l heat-admin $controller_ip << EOF_ALL
#sudo mysql keystone << EOF
#update assignment set actor_id = 'cinder' where actor_id = ( select id from user where name = 'cinder');
#update assignment set actor_id = 'neutron' where actor_id = ( select id from user where name = 'neutron');
#update assignment set actor_id = 'glance' where actor_id = ( select id from user where name = 'glance');
#update assignment set actor_id = 'nova' where actor_id = ( select id from user where name = 'nova');
#update assignment set actor_id = 'swift' where actor_id = ( select id from user where name = 'swift');
#update assignment set actor_id = 'admin' where actor_id = ( select id from user where name = 'admin');
#update assignment set actor_id = 'ceilometer' where actor_id = ( select id from user where name = 'ceilometer');
#update assignment set actor_id = 'heat' where actor_id = ( select id from user where name = 'heat');
#update assignment set actor_id = 'ceilometer' where actor_id = ( select id from user where name = 'ceilometer');
#update assignment set actor_id = 'cinderv2' where actor_id = ( select id from user where name = 'cinderv2');
#EOF
#
#sleep 2
#pcs resource restart openstack-keystone-clone --all
#sleep 2
#exit
#EOF_ALL


# become admin user
source $rcfile

# Load images
curl -O http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
#curl -O $webserver_url/rhel-guest-image-7.1-20150224.0.x86_64.qcow2
curl -O http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2

glance image-create --name cirros --disk-format qcow2 \
    --container-format bare --visibility public \
    --file cirros-0.3.4-x86_64-disk.img
#glance image-create --name rhel7 --min-ram 2048 --disk-format qcow2 \
#    --container-format bare --visibility public --file \
#      rhel-guest-image-7.1-20150224.0.x86_64.qcow2
glance image-create --name centos7 --min-ram 2048 --disk-format qcow2 \
    --container-format bare --is-public true --file \
      CentOS-7-x86_64-GenericCloud.qcow2

sleep 5
rm -f cirros-0.3.4-x86_64-disk.img rhel-guest-image-7.1-20150224.0.x86_64.qcow2 CentOS-7-x86_64-GenericCloud.qcow2c

# Create Public network
neutron net-create public --router:external=true \
  --provider:physical_network=datacentre --provider:network_type=flat
neutron subnet-create public 192.168.113.0/24 \
    --name public_subnet --disable-dhcp --allocation-pool \
    start=192.168.113.150,end=192.168.113.200 --gateway 192.168.113.1

# create test tenant
keystone tenant-create --name tenant1 --description "Demo Tenant1"

# cant create user from keystone after ldap integration
keystone user-create --name tenant1 --tenant tenant1 --pass p@ssw0rd

# add ldap user tenant one (created in ipa-server-create-accounts.sh) to newly created tenant1 project
openstack role add --project tenant1 --user tenant1 _member_

cp ~/homelabrc ~/tenant1rc
sed -i 's/admin/tenant1/g' ~/tenant1rc
sed -i 's/OS_PASSWORD.*/OS_PASSWORD=p@ssw0rd/g' ~/tenant1rc

#change to tenant1 credentials
source ~/tenant1rc

#create tenant1 network
neutron net-create tenant1-net
neutron subnet-create tenant1-net 192.168.5.0/24 --name tenant1-subnet --dns-nameserver 192.168.2.2
neutron router-create tenant1-router
neutron router-gateway-set tenant1-router public
neutron router-interface-add tenant1-router tenant1-subnet

# Create security groups
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0

#add ssh key
nova keypair-add --pub-key ~/.ssh/id_rsa.pub undercloud-key

# Boot test image
nova boot --flavor m1.tiny --image cirros --key-name undercloud-key tenant1-test1
sleep 5
neutron floatingip-create public
nova add-floating-ip tenant1-test1 192.168.113.151

## create sensu tenant and user for overcloud
#source $rcfile
#keystone tenant-create --name monitoring --description "Sensu Tenant"
#keystone user-create --name sensu --tenant monitoring --pass sensu

# create sensu tenant and user for undercloud
#source ~/stackrc
#keystone tenant-create --name monitoring --description "Sensu Tenant"
#keystone user-create --name sensu --tenant monitoring --pass sensu
