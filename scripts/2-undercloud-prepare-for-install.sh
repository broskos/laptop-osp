#!/usr/bin/env bash
# ssh to undercloud and run this script
#
source ~/laptop-osp/scripts/0-site-settings.sh

echo "Please enter your RH cdn password: "
read -sr cdn_password
export cdn_password

subscription-manager register  --username ${cdn_username} --password ${cdn_password}
subscription-manager attach --pool ${cdn_pool}

sudo subscription-manager repos --disable=*
sudo subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-7-server-extras-rpms \
    --enable=rhel-7-server-openstack-${osp_version}-rpms --enable=rhel-7-server-openstack-${osp_version}-director-rpms \
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

