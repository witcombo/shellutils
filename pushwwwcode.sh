#!/usr/bin/env bash
#
#

JenkinsHome="/var/lib/jenkins/workspace/测试环境\ WWW"
BackupDir=/data/backup/`date +%Y%m%d`
BackupTime=`date +%Y%m%d%H%M%S`
WorkDir="/data/sh"
WWWCodeDir="/mnt/c-sw/Web/ProductRelease/ImOra/3.x"


if `echo $1 | grep -P "^\d+\.\d+\.\d+$|^www_\d{14}_\d+\.\d+\.\d+$" > /dev/null 2>&1`
then
    :
else
    echo "Error: 输入有误，请重新输入(版本号:1.0.x 或 者回退版本：www_20160720160559_1.x.x)"
    exit 1
fi

Version=$1
test -d $WorkDir/CodeTemp/www/$Version && mv $WorkDir/CodeTemp/www/$Version $WorkDir/CodeTemp/www/${Version}_${BackupTime}
test ! -d $WorkDir/CodeTemp/www/$Version && mkdir -p $WorkDir/CodeTemp/www/$Version
HOSTS=`awk 'BEGIN{RS=""}/fangzhenwww/{print $0}' /etc/ansible/hosts  | grep -oP '^172.*'`

function Main(){
    ansible $1 -m shell -a "chown nginx.nginx /data/webcode/www -R"
    ansible $1 -m shell -a "chmod +x /data/webcode/www/Apps/Static/phantomjs/phantomjs"
}

function replace_lines(){
    sed -i "/$1/{x;s/^/./;/^\.\{$2\}$/{x;s/.*/$3/;x};x;}"  $4
}

function ModifyConfig(){
    echo "更新主配置文件"
    sed -i -r s#[\'\"]WEB_SERVICE_ROOT_URL[\'\"].*#"'WEB_SERVICE_ROOT_URL'  => 'http://10.10.10.7',"#g www/Config/config.php
    sed -i -r s#[\'\"]ORANGE_WEB_SERVICE_URL[\'\"].*#"'ORANGE_WEB_SERVICE_URL'  => 'http://101.251.193.27:81',"#g www/Config/config.php

    sed -i -r s#[\'\"]DB_HOST[\'\"].*#"'DB_HOST'               => '172.17.4.3',"#g www/Config/config.php
    sed -i -r s#[\'\"]DB_NAME[\'\"].*#"'DB_NAME'               => 'operation_data_web',"#g www/Config/config.php
    sed -i -r s#[\'\"]DB_USER[\'\"].*#"'DB_USER'               => 'test',"#g www/Config/config.php
    sed -i -r s#[\'\"]DB_PWD[\'\"].*#"'DB_PWD'               => '123456',"#g www/Config/config.php
    sed -i -r s#[\'\"]DB_PORT[\'\"].*#"'DB_PORT'               => '3366',"#g www/Config/config.php
    sed -i -r s#[\'\"]DB_PREFIX[\'\"].*#"'DB_PREFIX'               => '',"#g www/Config/config.php
    sed -i -r s#[\'\"]DB_SQL_LOG[\'\"].*#"'DB_SQL_LOG'               => 'true',"#g www/Config/config.php

    sed -i -r s#[\'\"]IM_SERVER_IP[\'\"].*#"'IM_SERVER_IP'  => '101.251.193.27',"#g www/Config/config.php
    sed -i -r s#[\'\"]IM_SERVER_PORT[\'\"].*#"'IM_SERVER_PORT'  => '5123',"#g www/Config/config.php
    sed -i -r s#[\'\"]WEB_SOCKET_URL[\'\"].*#"'WEB_SOCKET_URL'  => '101.251.193.27:9999',"#g www/Config/config.php
    sed -i -r s#[\'\"]URL_BINARY_UPLOAD[\'\"].*#"'URL_BINARY_UPLOAD'  => 'http://101.251.193.27:10080/welcome/upload',"#g www/Config/config.php
    sed -i -r s#[\'\"]URL_BINARY_DOWNLOAD[\'\"].*#"'URL_BINARY_DOWNLOAD'  => 'http://101.251.193.27:8090',"#g www/Config/config.php
    sed -i -r s#[\'\"]ANDROID_APP_LINK[\'\"].*#"'ANDROID_APP_LINK'  => 'http://101.251.193.27:81/Oradt-App-Internal-Test_v1.8.apk',"#g www/Config/config.php
    sed -i -r s#[\'\"]ORA_DOMAIN.*#"'ORA_DOMAIN' => 'http://101.251.193.29:82/',"#g www/Config/config.php
    
	
    #sed -i -r ':a;N;$!ba;s#192.168.30.191#10.10.10.101#1' www/Config/config.php
    replace_lines "'db_user'.*" 1 "\t\t\t\t'db_user' => 'oradt_test2'," www/Config/config.php
    replace_lines "'db_pwd'.*" 1 "\t\t\t\t'db_pwd' => '12345678910'," www/Config/config.php
    replace_lines "'db_host'.*" 1 "\t\t\t\t'db_host' => '172.17.3.2'," www/Config/config.php
    replace_lines "'db_port'.*" 1 "\t\t\t\t'db_port' => '3317'," www/Config/config.php
    replace_lines "'db_name'.*" 1 "\t\t\t\t'db_name' => 'oradt_cloud_test2'," www/Config/config.php
    replace_lines "'db_user'.*" 2 "\t\t\t\t'db_user' => 'oradt_test2'," www/Config/config.php
    replace_lines "'db_pwd'.*" 2 "\t\t\t\t'db_pwd'  => '12345678910'," www/Config/config.php
    replace_lines "'db_host'.*" 2 "\t\t\t\t'db_host' => '172.17.3.2'," www/Config/config.php
    replace_lines "'db_port'.*" 2 "\t\t\t\t'db_port' => '3317'," www/Config/config.php
    replace_lines "'db_name'.*" 2 "\t\t\t\t'db_name' => 'oradt_cloud_test2'," www/Config/config.php
    replace_lines "'db_user'.*" 3 "\t\t\t\t'db_user' => 'imora_scan'," www/Config/config.php
    replace_lines "'db_pwd'.*" 3 "\t\t\t\t'db_pwd'  => '123456'," www/Config/config.php
    replace_lines "'db_host'.*" 3 "\t\t\t\t'db_host' => '172.17.3.2'," www/Config/config.php
    replace_lines "'db_port'.*" 3 "\t\t\t\t'db_port' => '3327'," www/Config/config.php
    replace_lines "'db_name'.*" 3 "\t\t\t\t'db_name' => 'imora_scan'," www/Config/config.php
    
}

function ModifyDemoConfig(){
    echo "更新Demo配置文件"
    sed -i -r s#[\'\"]url[\'\"].*#"'url'      => 'http://172.17.3.113:7474/db/data/transaction',"#g www/Apps/Demo/Conf/config.php
}

function BackupOldCode(){
    if `ansible $1 -m shell -a "test -d /data/webcode/www" > /dev/null`
    then
        ansible $1 -m shell -a "mkdir -p $BackupDir"
        echo "备份以前的代码"
        echo "获得以前的版本号"
        OldVersion=`ansible $1 -m shell -a "grep 'APP_VERSION' /data/webcode/www/Config/config.php" | grep APP_VERSION | grep -oP '\d+.\d+.\d+'`
        echo "备份以前的版本到: $BackupDir/www_${BackupTime}_${OldVersion}"
    fi
}


if [[ "$2" = "更新补丁" ]]
then
    echo "更新类型: 发布补丁" 
    echo "本地进行文件解压缩操作"
    if scp -P5022 root@106.37.218.151:$WWWCodeDir/$Version/Patch_*_ImOra.${Version}.tgz $WorkDir/CodeTemp/www/$Version > /dev/null 2>&1
    then
        :
    else
        echo "Error: 没有发现补丁"
        exit 1
    fi
    cd $WorkDir/CodeTemp/www/$Version/
    test ! -d www && mkdir www
    for i in `ls Patch_*_ImOra.${Version}.tgz | sort -n`
    do
        tar -xf $i -C www || tar -zxf $i -C www	
        echo "解压缩补丁$i"
    done

    if [ -f "www/Config/config.sample.php" -o -f "www/Config/config.php" ]
    then
        echo "发现配置配置文件config.sample.php，创建配置文件config.php"
        cp www/Config/config.sample.php www/Config/config.php
        ModifyConfig
	if [ -f "www/Apps/Demo/Conf/config.php" ]
        then
                ModifyDemoConfig
	else
		echo "Info: 没有Demo配置更新"
        fi
    fi
    for i in `echo $HOSTS`
    do
        echo "备份代码 $i"
        BackupOldCode $i
        ansible $i -m shell -a "test -d /data/webcode/www && cp -a /data/webcode/www $BackupDir/www_${BackupTime}_${OldVersion}" > /dev/null 2>&1
        echo "将本地文件Copy到远程服务器 $i"
        rsync --exclude ".git" -alz www/* $i:/data/webcode/www/
        Main $i
    done

elif [[ "$2" = "更新整个版本" ]]
then
    echo "新类型: 更新整个版本" 
    echo "处理主体软件包 $ImOra.${Version}.tgz"
    if scp -P5022 root@106.37.218.151:$WWWCodeDir/$Version/ImOra.${Version}.tgz $WorkDir/CodeTemp/www/$Version > /dev/null 2>&1
    then
        :
    else
        echo "Error: 没有发现版本为${Version}的软件包"
        exit 1
    fi
    cd $WorkDir/CodeTemp/www/$Version/
    test ! -d www && mkdir www
    tar -xzf ImOra.${Version}.tgz -C www

    echo "处理补丁包"
    if scp -P5022 root@106.37.218.151:$WWWCodeDir/$Version/Patch_*_ImOra.${Version}.tgz $WorkDir/CodeTemp/www/$Version > /dev/null 2>&1
    then
        for i in `ls Patch_*_ImOra.${Version}.tgz | sort -n`
        do
            tar -xzf $i -C www
            echo "解压缩补丁$i"
        done
    else
        echo "INFO: 没有发现补丁"
    fi

    if [ -f "www/Config/config.sample.php" -o -f "www/Config/config.php" ]
    then
        echo "发现配置配置文件config.sample.php，创建配置文件config.php"
        cp www/Config/config.sample.php www/Config/config.php
        ModifyConfig www/Config/config.php
	if [ -f "www/Apps/Demo/Conf/config.php" ]
	then
		ModifyDemoConfig
	else
		echo "Info: 没有Demo配置更新"
	fi
    fi

    for i in `echo $HOSTS`
    do
        echo "备份代码 $i"
        BackupOldCode $i
        ansible $i -m shell -a "test -d /data/webcode/www && mv /data/webcode/www $BackupDir/www_${BackupTime}_${OldVersion}" > /dev/null 2>&1
        echo "将本地文件Copy到远程服务器 $i"
        rsync --exclude ".git" -alz www/* $i:/data/webcode/www/
        Main $i
    done

elif [[ "$2" = "版本回退" ]]
then
    echo "更新类型: 版本回退"

    for i in `echo $HOSTS`
    do
        echo "开始回退 $i"
        if `ansible $i -m shell -a "test -d $BackupDir/$1" > /dev/null`
        then
            echo "备份代码 $i"
            BackupOldCode $i
            ansible $i -m shell -a "test -d /data/webcode/www && mv /data/webcode/www $BackupDir/www_${BackupTime}_${OldVersion}" > /dev/null 2>&1
            ansible $i -m shell -a "cp -a $BackupDir/$1 /data/webcode/www"
            Main $i
        else
            echo "Error: 没有回退地址为$BackupDir/$1 的软件包"
            exit 1
        fi
    done
else
    echo "请选择更新类型"
    exit 1
fi
