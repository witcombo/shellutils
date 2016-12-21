#!/bin/sh
SouHost=http://192.168.1.100:83
HtPasswd='--http-user=oradt --http-passwd='!@#qwe''
eval $(/sbin/ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}' | awk -F. '{printf("AREA1=%s AREA2=%s NET=%s IP=%s",$1,$2,$3,$4)}')

function RM {

        test -f $0 && rm -f $0
}

function Set_Res {

		sed -i 's/172.20.0.2/$AREA1.$AREA2.0.2/g' /etc/resolv.conf
}

function Set_S3fs {

		[ -d /etc/yum.repos.d ] && rm -f /etc/yum.repos.d/epel*
		#yum -y install automake fuse fuse-devel gcc gcc-c++ git libcurl-devel libxml2-devel make openssl-devel
		cd /root/
		wget $HtPasswd $SouHost/s3fs-fuse.tar.gz
		tar zxf s3fs-fuse.tar.gz
		cd s3fs-fuse
		./autogen.sh
		./configure
		make
		make install
}

function Judge_Service (){

        if   [ $NET -eq 10 -o $NET -eq 100 ];then
			 if [ $IP -ge 50 -a $IP -le 99  ];then
				USE=Service
			 else
				USE=Api
			 fi
        elif [ $NET -eq 11 -o $NET -eq 110 ];then
			 if [ $IP -ge 220 ];then
				USE=Card
			 elif [ $IP -ge 50 -a $IP -le 99  ];then
				USE=Service
			 else
				USE=Web
			 fi
			 fi
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
	     Set_Res
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

	     authconfig --enableldap --enableldapauth --ldapserver=192.168.1.13 --ldapbasedn="dc=oradt,dc=com" --enablemkhomedir --update
		
	     sed -i 's/^Hostname=.*/Hostname='$HOSTNAME'/g' /etc/zabbix/zabbix_agentd.conf
	     sed -i 's/add_header.*/add_header ServerID '$HOSTNAME";"'/g' /usr/local/tengine/conf/nginx.conf
		
	if [ $USE=Api | $USE=Web | $USE=Card | $USE=DB ];then
		if [ $AREA1 -eq 172 -a $AREA2 -eq 20 ];then
				
		     Set_S3fs
				
		     echo AKIAOEBVVPEIOGSCIZ5Q:++kVhlWLylfyUdstM0QlzJ7gtxDW9SzWS93Fg+9i > /root/.passwd-s3fs
		     chmod 600 /root/.passwd-s3fs
		     s3fs oradt-s /data/images -o passwd_file=/root/.passwd-s3fs -o url=http://s3.cn-north-1.amazonaws.com.cn -o endpoint=cn-north-1
		     echo '/usr/local/bin/s3fs#oradt-s /data/images/ fuse allow_other,url=http://s3.cn-north-1.amazonaws.com.cn,endpoint=cn-north-1 0 0' >> /etc/fstab
		     cat /root/.passwd-s3fs > /etc/passwd-s3fs && chmod 600 /etc/passwd-s3fs
				
		elif [ $AREA1 -eq 10 -a $AREA2 -eq 10 ];then
		     Set_S3fs	
		fi
	fi
		
}

Set_HostName

/etc/init.d/zabbix_agentd restart
/etc/init.d/salt-minion restart
/etc/init.d/nginxd restart
/etc/init.d/phpfpm restart

RM
