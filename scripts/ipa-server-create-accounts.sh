#!/usr/bin/env bash

# run this on the ipa-server, copy over the tripleo-overcloud-passwords file from undercloud to /root
echo "Enter IPA Directory Manager Password:"
read -s DIRPASS

echo "Enter IPA Admin Password:"
read -s ADMINPASS


# install ipa-client and join my undercloud vm to ipa-server
# this gets the tools I need on my undercloud server and makes it easy
# to create accounts and do what is needed.
sudo yum install -y ipa-client ipa-admintools openldap-clients
sudo sh -c  'echo "192.168.2.5 ipa-server.homelab.brentandkrysti.com ipa-server" >> /etc/hosts'
sudo ipa-client-install --no-ntp --server=ipa-server.homelab.brentandkrysti.com --domain=homelab.brentandkrysti.com --password=$ADMINPASS --principal=admin --unattended

echo $ADMINPASS | kinit admin

# add inetorgperson to IPA admin account
# this is necesssary because otherwise the admin account can't be used for the
# OpenStack admin account - and changing out the OpenStack account for something else
# seems difficult during the deploy
cat <<EOF > ~/ldap-admin
dn: uid=admin,cn=users,cn=accounts,dc=homelab,dc=brentandkrysti,dc=com
changetype: modify
add: objectClass
objectClass: inetorgperson
EOF

ldapmodify -x -D 'cn=directory manager' -w $DIRPASS -f ~/ldap-admin

#create ldap-template
cat <<EOF > ~/ldap-template
dn: uid=USER,cn=users,cn=accounts,dc=homelab,dc=brentandkrysti,dc=com
changetype: modify
replace: krbPasswordExpiration
krbPasswordExpiration: 20380101000000Z
EOF

# make a function called create_users, it takes username and password as params
create_users () {
    # create user (it's ok if it already exists)
    /usr/bin/ipa user-add "$1" --first="$1" --last="$1"

    # add user to proper groups
    /usr/bin/ipa group-add-member openstack_enabled --users="$1"
    /usr/bin/ipa group-add-member service_accounts --users="$1"

    # set password
    echo "$2" | /usr/bin/ipa user-mod "$1" --password

    # now we have a hack to set password expiration way in the future
    # this can only be done with the directory manager credential
    sed "s/USER/$1/g" ~/ldap-template > ~/ldap-current
    ldapmodify -x -D 'cn=directory manager' -w $DIRPASS -f ~/ldap-current
}

# loop through service accounts in tripleo-overcloud-passwords file
for i in $( cat ~/tripleo-overcloud-passwords |grep PASSWORD |grep -v HEAT_STACK);do
    # filter out what we don't want, then reduce to account=password
    user="$(echo $i | awk '{print tolower($0)}' | sed 's/overcloud_//g' | sed 's/_password//g')"
    # split on the = and return user, password
    IFS='=' read -r -a array <<< "$user"

    # call create_users pass in user and password
    create_users "${array[0]}" "${array[1]}"
done

# add my openstack-ldap and test users here..
create_users "openstack-ldap" "p@ssw0rd"
create_users "tenant1" "p@ssw0rd"


# cleanup files
rm -f ~/ldap-template ~/ldap-current ~/ldap-admin