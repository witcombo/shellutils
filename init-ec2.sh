#/bin/sh
#Initialize the script for ec2
#
#LastModify 2016/11/24
#githup: https://github.com/witcombo/shellutils.git

SouHost=http://192.168.1.100:83
HtPasswd='--http-user=oradt --http-passwd='!@#qwe''
#IP=`/sbin/ifconfig  | grep -oP '(?<=inet addr:172.17.1.)\w+(\w+)'`
#IP=`/sbin/ifconfig | grep -E '(^*inet addr:(.*) Bcast*)' | awk -F"[.]" '{print $4}' | awk '{print $1}'`
eval $(/sbin/ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}' | awk -F. '{printf("AREA1=%s AREA2=%s NET=%s IP=%s",$1,$2,$3,$4)}')
SLEEP=`sleep 2`
USE=$1

function check_root () {
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
  fi
}

function check_net () {
	timeout=5
	target=www.baidu.com
	ret_code=`curl -I -s --connect-timeout $timeout $target -w %{http_code} | tail -n1`
	if [ "x$ret_code" != "x200" ];then
		echo "Network unreasonable,Script quit" 1>&2
		exit 1
	fi
	sysver=`if [ -f /etc/redhat-release ];then awk -F'[ |.]' '{print $4}' /etc/redhat-release;fi`
}

function print_help () {
  echo "Usage: ${0} -n $1(API | WWW | Card | LoadBalance | Basic) -t $2(cluster | manage)"
  echo "Examples:"
  echo "${0} -n API -t cluster"
  echo "${0} -n LoadBalance -t manage"
  echo "${0} -n IM -t cluster"
  exit 1
}

function Set_HostName (){
        if [ $AREA1 -eq 172 -a $AREA2 -eq 20 ];then
                ORADT=Simu
        else
                ORADT=Oradt
        fi

        if [[ $NET = 10 || $NET = 11 || $NET = 12 || $NET = 13 ]];then
                AREA=A
        else
                AREA=B
        fi

        sed -i 's/HOSTNAME=.*/HOSTNAME='$ORADT'-'$USE'-'$AREA''$IP'/' /etc/sysconfig/network
        sysctl kernel.hostname=$ORADT-$USE-$AREA$IP
        HOSTNAME=$ORADT-$USE-$AREA$IP
}

function Sys_UpDate (){
	yum-config-manager --enable epel
	yum-config-manager --enable epel-source
	yum repolist all
	yum update -y
}

function Sys_Init () {
	echo -e "\033[32m 设置root远程登陆 \033[0m"
	sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
	sed -i 's/PermitRootLogin forced-commands-only/PermitRootLogin yes/g' /etc/ssh/sshd_config
	if [[ ${sysver} -eq 7 ]];then
		systemctl restart sshd.service
	else
		/etc/init.d/sshd restart
	fi

	echo '4pfd!cs3$,D8' | passwd --stdin ec2-user || echo '4pfd!cs3$,D8' | passwd --stdin centos
	echo '4pfd!cs3$,D8' | passwd --stdin root

	#配置时区
	sed -i 's/ZONE="UTC"/ZONE="Asia\/Shanghai"/g' /etc/sysconfig/clock
	rm -rf /etc/localtime
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
		
	echo -e "\033[32m DNS配置 \033[0m"
	$SLEEP
if [ $AREA1.$AREA2.$NET -eq 192.168.1 ];then
	echo -e "options timeout:2 attempts:1\nnameserver 192.168.1.10\nnameserver 192.168.1.11\nsearch cn-north-1.compute.internal\nnameserver $AREA1.$AREA2.1.2\nnameserver 8.8.4.4" > /etc/resolv.conf
	echo 'echo -e "options timeout:2 attempts:1\nnameserver 192.168.1.10\nnameserver 192.168.1.11\nsearch cn-north-1.compute.internal\nnameserver '$AREA1'.'AREA2'.1.2\nnameserver 8.8.4.4"' >>/etc/rc.local
else
	echo -e "options timeout:2 attempts:1\nnameserver 192.168.1.10\nnameserver 192.168.1.11\nsearch cn-north-1.compute.internal\nnameserver $AREA1.$AREA2.0.2\nnameserver 8.8.4.4" > /etc/resolv.conf
	echo 'echo -e "options timeout:2 attempts:1\nnameserver 192.168.1.10\nnameserver 192.168.1.11\nsearch cn-north-1.compute.internal\nnameserver '$AREA1'.'AREA2'.0.2\nnameserver 8.8.4.4"' >>/etc/rc.local
fi
	#设置HISTORY
	echo '''export HISTFILESIZE=1000000000
	export HISTSIZE=1000000
	export PROMPT_COMMAND="history -a"
	export HISTTIMEFORMAT="%Y-%m-%d_%H:%M:%S  "''' >> /etc/profile

	#关闭iptables,selinux
	if [[ ${sysver} -eq 7 ]];then
		systemctl stop firewalld.service
		systemctl disable firewalld.service
	else
		/etc/init.d/iptables stop
		chkconfig iptables off
	fi

	setenforce 0
	if [ -f /etc/selinux/config ];then
		sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
	else 
		:
	fi 

	#设置crond
	cd /var/spool/postfix/maildrop;ls | xargs rm -rf
	sed 's/MAILTO=root/MAILTO=""/g' /etc/crontab
	service crond restart

	echo "添加定时任务"
	test ! -d /data/sh && mkdir /data/sh
	cd /data/sh/
	#echo   '# * */1 * * * /usr/sbin/ntpdate 172.17.1.100;/sbin/hwclock -w >/dev/null 2>&1' >> /var/spool/cron/root

	wget $HtPasswd $SouHost/ops/scripts.tar.gz
    tar zxf scripts.tar.gz && rm -f scripts.tar.gz
	chmod +x *.sh

	echo -e "\033[32m 内核参数配置 \033[0m"
	$SLEEP
	echo ulimit -SHn 65536 >> /etc/profile
	source /etc/profile
	
	echo '''alias net-pf-10 off
	alias ipv6 off''' >> /etc/modprobe.d/dist.conf
	echo 'NETWORKING_IPV6=no' >> /etc/sysconfig/network
	echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf
	sysctl net.ipv6.conf.all.disable_ipv6=1
	
	if [[ ${sysver} -ne 7 ]];then
	service ip6tables stop
	chkconfig ip6tables off
	fi

	echo '''* soft nproc 11000
	* hard nproc 11000
	* soft nofile 655350
	* hard nofile 655350''' >> /etc/security/limits.conf

	echo 1 > /proc/sys/net/ipv4/tcp_syncookies
	echo 8192 > /proc/sys/net/ipv4/tcp_max_syn_backlog
	echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
	echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
	echo 1800000 > /proc/sys/net/ipv4/tcp_max_tw_buckets
	echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout
	echo 1 > /proc/sys/net/ipv4/tcp_timestamps
	echo 0 > /proc/sys/net/ipv4/tcp_sack
	echo 0 > /proc/sys/net/ipv4/tcp_window_scaling 
	echo 0 > /proc/sys/net/ipv4/tcp_ecn

	echo 600 > /proc/sys/net/ipv4/tcp_keepalive_time
	echo 30 > /proc/sys/net/ipv4/tcp_keepalive_intvl
	echo 3 > /proc/sys/net/ipv4/tcp_keepalive_probes
	echo 655360 > /proc/sys/net/ipv4/tcp_max_orphans
	echo 100 > /proc/sys/net/ipv4/route/gc_timeout
	echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects
	echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
	echo "786432 1048576 8388608" > /proc/sys/net/ipv4/tcp_mem
	echo "4096 87380 16777216" > /proc/sys/net/ipv4/tcp_rmem
	echo "4096 65536 16777216" > /proc/sys/net/ipv4/tcp_wmem

	echo 10240 > /proc/sys/net/core/somaxconn
	echo "65536" > /proc/sys/net/core/rmem_default
	echo "16777216" > /proc/sys/net/core/rmem_max
	echo "65536" > /proc/sys/net/core/wmem_default
	echo "16777216" > /proc/sys/net/core/wmem_max
	# recommended to increase this for 1000 BT or higher
	echo "2500" > /proc/sys/net/core/netdev_max_backlog
	# for 10 GigE, use this net.core.netdev_max_backlog = 30000
	echo "10000 65535" > /proc/sys/net/ipv4/ip_local_port_range
	echo "2097152" > /proc/sys/fs/file-max

	#echo deadline > /sys/block/sda/queue/scheduler
	#echo deadline > /sys/block/sdb/queue/scheduler
	echo 0 > /proc/sys/vm/zone_reclaim_mode
	echo 0 > /proc/sys/vm/swappiness
}

function Sys_Setup () {
	wget $HtPasswd $SouHost/ops/jumpserver.key
	cp jumpserver.key /root/.ssh/authorized_keys
	chown root.root /root/.ssh -R
	chmod 600 /root/.ssh/authorized_keys

	mkdir /data/images/
	chown nginx.nginx /data/images -R
	echo '%op ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
}

function Set_python () {
	yum install readline readline-devel readline-static openssl openssl-devel openssl-static sqlite-devel bzip2-devel bzip2-libs git -y

	git clone git://github.com/yyuu/pyenv.git ~/.pyenv
	echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
	echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
	echo 'eval "$(pyenv init -)"' >> ~/.bashrc
	exec $SHELL -l
	
	pyenv install 2.7.9 -v
	pyenv rehash
	
	mv /usr/bin/python /usr/bin/python.bak
	ln -s ~/.pyenv/versions/2.7.9/bin/python /usr/bin/python
}

function Set_zabbix () {
	echo "安装Zabbix agent"
	cd /root/
	groupadd zabbix
	useradd zabbix -g zabbix

	mkdir -p /data/logs/zabbix
	chown zabbix.zabbix /data/logs/zabbix -R

	wget $HtPasswd $SouHost/ops/zabbix-3.0.5.tar.gz
	tar -xzf zabbix-3.0.5.tar.gz
	cd zabbix-3.0.5
	yum install -y gcc gcc-c++ autoconf
	./configure --prefix=/usr/local/zabbix --enable-agent
	make install
	
	wget $HtPasswd $SouHost/ops/zabbix_agentd
	chmod +x zabbix_agentd && cp zabbix_agentd /etc/init.d/

	wget $HtPasswd $SouHost/ops/zabbix_agentd.conf
	sed -i 's/Hostname=.*/Hostname='$HOSTNAME'/g' zabbix_agentd.conf
	/bin/cp -f zabbix_agentd.conf  /usr/local/zabbix/etc/
	ln -s /usr/local/zabbix/etc /etc/zabbix
	chkconfig --add zabbix_agentd
	chkconfig zabbix_agentd on

	echo 'zabbix ALL=NOPASSWD:/bin/netstat' >> /etc/sudoers
}

function Set_saltstack () {
	
	yum install -y salt-minion
	sed -i "s/^#id:*/id: '$HOSTNAME'/g" /etc/salt/minion
	sed -i "16 amaster: 192.168.1.100" /etc/salt/minion
	/etc/init.d/salt-minion start
	chkconfig salt-minion on
	
}

function Set_ldap () {
	yum -y install openldap-clients nss-pam-ldapd 
	/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"|head -n 1 >>/etc/motd
	authconfig --enableldap --enableldapauth --ldapserver=192.168.1.13 --ldapbasedn="dc=oradt,dc=com" --enablemkhomedir --update
	echo "sudoers: files ldap" >>/etc/nsswitch.conf
	echo "uri ldap://192.168.1.13/" >>/etc/sudo-ldap.conf
	echo "sudoers_base dc=oradt,dc=com" >>/etc/sudo-ldap.conf
	#release=`awk '{print $(NF-1)}' /etc/redhat-release | awk -F'.' '{print $1}'`
	#if [ $release -eq 6 ];then
	#	/etc/init.d/nslcd status
	#	chkconfig nslcd on
	#else
	#	systemctl enable nslcd
	#fi

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
}

function Set_php () {
	
	echo -e "\033[32m Installing PHP . \033[0m"
	yum -y install libxml2 libxml2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libmcrypt libmcrypt-devel openssl openssl-devel gcc make gcc-c++
	cd
	wget $HtPasswd $SouHost/php-5.6.6.tar.gz
	tar -zxf php-5.6.6.tar.gz
	cd php-5.6.6
	./configure --prefix=/usr/local/php --with-config-file-path=/etc/php/ --with-config-file-scan-dir=/etc/php/php.d --enable-mbstring --with-curl --with-mysql --with-openssl --with-zlib --enable-fpm --with-mcrypt --with-mysqli --with-pdo-mysql --libdir=/usr/lib64 --with-libdir=lib64 --with-gd --enable-soap --enable-xml --enable-pdo --enable-exif --enable-zip --enable-bcmath --with-jpeg-dir=/usr/lib64 --with-png-dir=/usr/lib64 --with-freetype-dir=/usr/lib64 --enable-opcache
	make -j6
	make install
	cd ..

	mkdir /etc/php/
	wget $HtPasswd $SouHost/ops/php.ini && cp php.ini /etc/php/

	wget $HtPasswd $SouHost/ops/phpfpm
	chmod +x phpfpm && cp phpfpm /etc/init.d/
	mkdir /data/logs/php -p && chown nginx.nginx /data/logs/php -R

	wget $HtPasswd $SouHost/php-fpm.conf
	cp php-fpm.conf /usr/local/php/etc/
	

	echo -e "\033[32m Installing ImageMagick . \033[0m"
	$SLEEP
	wget $HtPasswd $SouHost/ImageMagick-6.8.9-10.tar.gz
	wget $HtPasswd $SouHost/imagick-3.4.0RC6.tgz
	tar -zxf ImageMagick-6.8.9-10.tar.gz
	cd ImageMagick-6.8.9-10
	./configure --prefix=/usr/local/imagemagick
	make -j6
	make install
	cd ..

	tar -zxf imagick-3.4.0RC6.tgz
	cd imagick-3.4.0RC6
	/usr/local/php/bin/phpize
	./configure --with-php-config=/usr/local/php/bin/php-config --with-imagick=/usr/local/imagemagick/
	make -j6
	make install
	cd ..

	wget $HtPasswd $SouHost/librdkafka-master.zip
	unzip librdkafka-master.zip
	cd librdkafka-master
	./configure
	make
	make install
	cd ..

	wget $HtPasswd $SouHost/phpkafka-master.zip
	unzip phpkafka-master.zip
	cd phpkafka-master
	/usr/local/php/bin/phpize
	./configure --enable-kafka --with-php-config=/usr/local/php/bin/php-config
	make
	make install
	cd ..
	echo "/usr/local/lib" >> /etc/ld.so.conf
	ldconfig -v
}

function Get_tengine () {
	cd /root/
	yum -y install pcre pcre-devel vixie-cron openssl*
	groupadd nginx -g 598
	useradd nginx -g nginx -s /sbin/nologin -u 598
	mkdir -pv /data/logs/nginx/  && chown -R nginx.nginx /data/logs/nginx/
	wget $HtPasswd $SouHost/tengine-2.1.2.tar.gz
	wget $HtPasswd -P /etc/init.d/ $SouHost/nginxd && chmod +x /etc/init.d/nginxd
}

function Cluster_install () {
	Set_HostName
	Sys_UpDate
	Sys_Init
	Sys_Setup
	Set_python
	Set_zabbix
	Set_ldap
	Get_tengine
	
	echo -e "\033[32m Installing Tengine . \033[0m"
	tar -zxf tengine-2.1.2.tar.gz
	cd tengine-2.1.2
	./configure --prefix=/usr/local/tengine --with-http_sysguard_module --user=nginx --group=nginx  --error-log-path=/data/logs/nginx/error.log --http-log-path=/data/logs/nginx/access.log --pid-path=/var/run/nginx.pid --with-http_ssl_module --with-http_concat_module
	make -j6
	make install

	cd ..
	wget $HtPasswd $SouHost/conf_node.tar.gz
	tar -zxf conf_node.tar.gz -C /usr/local/tengine/
	sed -i 's/add_header.*/add_header ServerID '$HOSTNAME";"'/g' /usr/local/tengine/conf/nginx.conf
	
	Set_php
	
	echo '''/etc/init.d/nginxd start
	/etc/init.d/phpfpm start''' >> /etc/rc.local
	/etc/init.d/nginxd start
	/etc/init.d/phpfpm start
	/etc/init.d/zabbix_agentd start
	
	Set_saltstack
}

function Manage_install () {
	Set_HostName
	Sys_UpDate
	Sys_Init
	Sys_Setup
	Set_python
	Set_zabbix
	Set_ldap
	Get_tengine
	
	echo -e “\033[32m Installing Tengine Manage . \033[0m”
	$SLEEP
    wget $HtPasswd $SouHost/LuaJIT-2.0.4.tar.gz
    tar -zxf LuaJIT-2.0.4.tar.gz
    cd LuaJIT-2.0.4
    make -j6
    make install PREFIX=/usr/local/luajit
	cd ..
	
    cd tengine-2.1.2
    ./configure --prefix=/usr/local/tengine --with-http_lua_module --with-luajit-lib=/usr/local/luajit/lib/ --with-luajit-inc=/usr/local/luajit/include/luajit-2.0/ --with-ld-opt=-Wl,-rpath,/usr/local/luajit/lib
    make -j6
    make install

    cd ..
    wget $HtPasswd $SouHost/waf.tar.gz
    tar -xzf waf.tar.gz -C /usr/local/tengine/conf/
    mkdir /data/logs/nginx/hack -p && chown nginx.nginx /data/logs/nginx/hack -R

    wget $HtPasswd $SouHost/conf_manager.tar.gz
    rm -fr /usr/local/tengine/nginx.conf
    tar -xzf conf_manager.tar.gz -C /usr/local/tengine/	
	
	echo '/etc/init.d/nginxd start' >> /etc/rc.local
	/etc/init.d/nginxd start
	/etc/init.d/zabbix_agentd start
	
	Set_saltstack
} 

function Basic_install () {
	Set_HostName
	Sys_UpDate
	Sys_Init
	Sys_Setup
	Set_python
	Set_zabbix
	Set_ldap
	/etc/init.d/zabbix_agentd start	
	Set_saltstack
	
}

function IM_install () {
	Set_HostName
	Sys_UpDate
	Sys_Init
	Sys_Setup
	Set_python
	Set_ldap
	Set_saltstack
	
}

check_root
check_net

while getopts "n:t:" opts;do
case "$opts" in
	"n")
	USE=$OPTARG
	;;
	"t")
	TYPE=$OPTARG
	;;
	*)
	print_help
	;;
esac
done

if [[ -z "$USE" ]] || [[ -z "$TYPE" ]];then
	print_help
else
	case "$USE" in
		"API")
			Cluster_install
			;;
		"WWW")
			Cluster_install
			;;
		"Card")
			Cluster_install
			;;
		"LoadBalance")
			Manage_install
			;;
		"Basic")
			Basic_install
			;;
		"IM")
			IM_install
			;;
		*)
			print_help
		;;
	esac
fi
