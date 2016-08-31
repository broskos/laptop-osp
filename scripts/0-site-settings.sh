
export webserver_url='http://192.168.115.1/pub'

# satellite config
export hostname='undercloud'
export ip_address='192.168.100.10'
export domain='home.brentandkrysti.com'
export stack_password='redhat'
export stack_name='laptop'
export ntp_server='0.centos.pool.ntp.org'

## ldap config
#export ldap_url='ldaps://192.168.2.5:389/'
#export ldap_user='uid=openstack-ldap,cn=users,cn=accounts,dc=homelab,dc=brentandkrysti,dc=com'
#export ldap_password='p@ssword'
#export ldap_suffix='dc=homelab,dc=brentandkrysti,dc=com'
#export ldap_user_tree_dn='cn=users,cn=accounts,dc=homelab,dc=brentandkrysti,dc=com'
#export ldap_group_tree_dn='cn=groups,cn=accounts,dc=homelab,dc=brentandkrysti,dc=com'
#export ldap_user_filter='(memberof=cn=openstack_enabled,cn=groups,cn=accounts,dc=homelab,dc=brentandkrysti,dc=com)'
#

home=~
rcfile=$home/$stack_name
rcfile+="rc"
export rcfile