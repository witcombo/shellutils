#!/bin/bash
yum -y install openldap-clients nss-pam-ldapd 
/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"|head -n 1 >>/etc/motd
authconfig --enableldap --enableldapauth --ldapserver=192.168.1.13 --ldapbasedn="dc=oradt,dc=com" --enablemkhomedir --update
echo "sudoers: files ldap" >>/etc/nsswitch.conf
echo "uri ldap://192.168.1.13/" >>/etc/sudo-ldap.conf
echo "sudoers_base dc=oradt,dc=com" >>/etc/sudo-ldap.conf
release=`awk '{print $(NF-1)}' /etc/redhat-release | awk -F'.' '{print $1}'`
if [ $release -eq 6 ];then
	/etc/init.d/nslcd status
	chkconfig nslcd on
else
	systemctl enable nslcd
fi

cat >> /etc/profile <<EOF
####User Login Log###
if ! test -z "\$BASH_EXECUTION_STRING" ; then
        echo "===== \$(date "+%F %T") \$USER nologin cmd:  \$BASH_EXECUTION_STRING" >>/var/log/command.log
elif  shopt -q login_shell ; then
        printf "====== \$(date "+%F %T") new login the last cmd: ">>/var/log/command.log
else
        printf "====== \$(date "+%F %T") su  the last cmd: ">>/var/log/command.log
fi
export HISTTIMEFORMAT="%F %T  \$USER \${SSH_TTY:5} \${SSH_CLIENT%% *}  "
export PROMPT_COMMAND="history 1|tail -1|sed 's/^[ ]\+[0-9]\+  //'>> /var/log/command.log"
EOF

touch /var/log/command.log
chmod 766 /var/log/command.log
