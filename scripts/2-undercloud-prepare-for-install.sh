#!/usr/bin/env bash
# ssh to undercloud and run this script
#
source ~/laptop-osp8/scripts/0-site-settings.sh

# register with satellite
#echo "$satellite_server_ip $satellite_server.$domain $satellite_server" >> /etc/hosts
#rpm -ivh http://$satellite_server.$domain/pub/katello-ca-consumer-latest.noarch.rpm
#subscription-manager register --org "$organization" --activationkey $activation_key
## subscription-manager attach --pool=1fcf540c50f247380150f255242d01de
#subscription-manager repos --enable rhel-7-server-openstack-8-director-rpms

subscription-manager register
subscription-manager attach --pool

sudo subscription-manager repos --disable=*
sudo subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-7-server-extras-rpms \
    --enable=rhel-7-server-openstack-9-rpms --enable=rhel-7-server-openstack-9-director-rpms \
    --enable=rhel-7-server-rh-common-rpms

# set hostname
hostnamectl set-hostname $hostname.$domain
echo "$ip_address $hostname.$domain $hostname" >> /etc/hosts

# add stack user
useradd stack
echo $stack_password | passwd stack --stdin
echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack

# install director installer package
yum install python-tripleoclient git -y

# update all packages and reboot
yum -y update && reboot

