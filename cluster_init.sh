#!/bin/sh
eval $(/sbin/ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}' | awk -F. '{printf("AREA1=%s AREA2=%s NET=%s IP=%s",$1,$2,$3,$4)}')

function RM {

        test -f $0 && rm -f $0

}

function Judge_Service (){

        if   [ $NET -eq 10 -o $NET -eq 100 ];then
                 USE=Api
        elif [ $NET -eq 11 -o $NET -eq 110 ];then
                 USE=Web
        elif [ $NET -eq 12 -o $NET -eq 120 ];then
                 USE=DB
        elif [ $NET -eq 13 -o $NET -eq 130 ];then
                 USE=IM
        fi
}

function Set_HostName (){

        if [ $AREA1 -eq 172 -a $AREA2 -eq 20 ];then
                ORADT=Simu
                Judge_Service
        else
                ORADT=Oradt
                Judge_Service
        fi

        if [[ $NET = 10 || $NET = 11 || $NET = 12 || $NET = 13 ]];then
                AREA=A
        else
                AREA=B
        fi

        sysctl kernel.hostname=$ORADT-$USE-$AREA$IP
        sed -i 's/HOSTNAME=.*/HOSTNAME='$ORADT'-'$USE'-'$AREA''$IP'/' /etc/sysconfig/network

        HOSTNAME=$ORADT-$USE-$AREA$IP
	sed -i "s/^id:.*/id: $HOSTNAME/g" /etc/salt/minion

	sed -i 's/^PasswordAuthentication no$/PasswordAuthentication yes/g' /etc/ssh/sshd_config

	authconfig --enableldap --enableldapauth --ldapserver=192.168.1.13 --ldapbasedn="dc=oradt,dc=com" --enablemkhomedir --update

	sed -i 's/add_header.*/add_header ServerID '$HOSTNAME";"'/g' /usr/local/tengine/conf/nginx.conf
}

Set_HostName

/etc/init.d/zabbix_agentd restart
/etc/init.d/salt-minion restart
/etc/init.d/nginxd restart
/etc/init.d/phpfpm restart
/etc/init.d/sshd restart
