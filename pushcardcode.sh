#!/usr/bin/env bash
#
#

JenkinsHome="/var/lib/jenkins/workspace/测试环境\ Card"
BackupDir=/data/backup/`date +%Y%m%d`
BackupTime=`date +%Y%m%d%H%M%S`
WorkDir="/data/sh"
CardCodeDir="/mnt/uat/名片录入系统release"


if `echo $1 | grep -P "^\d+\.\d+\.\d+$|^card_\d{14}_\d+\.\d+\.\d+$" > /dev/null 2>&1`
then
    :
else
    echo "Error: 输入有误，请重新输入(版本号:1.0.x 或 者回退版本：card_20160720160559_1.x.x)"
    exit 1
fi

Version=$1
test -d $WorkDir/CodeTemp/card/$Version && mv $WorkDir/CodeTemp/card/$Version $WorkDir/CodeTemp/card/${Version}_${BackupTime}
test ! -d $WorkDir/CodeTemp/card/$Version && mkdir -p $WorkDir/CodeTemp/card/$Version
HOSTS=`awk 'BEGIN{RS=""}/fangzhencard/{print $0}' /etc/ansible/hosts  | grep -oP '^172.*'`
APIHOSTS=`awk 'BEGIN{RS=""}/fangzhenapi/{print $0}' /etc/ansible/hosts  | grep -oP '^172.*'`

function Main(){
    ansible $1 -m shell -a "chown nginx.nginx /data/webcode/card -R"
}


function MainAPI(){
    ansible $1 -m shell -a "mkdir -p $BackupDir"
    ansible $1 -m shell -a "rm -fr /data/webcode/api/app/logs/*"
    ansible $1 -m shell -a "rm -fr /data/webcode/api/app/cache/*"
    ansible $1 -m shell -a "chown nginx.nginx /data/webcode/api -R"
    if [[ "$1" = "172.17.1.221" ]]
    then
        echo "重启脚本"
        ansible $1 -m shell -a "ps -ef | grep run.php | grep -v 'grep' | awk '{print \$2,\$3}' | xargs kill -9 2>/dev/null"
        ansible $1 -m shell -a "ps -ef | grep 'Oradt/CronBundle/daemon.php' | grep -v 'grep' | awk '{print \$2,\$3}' | xargs kill -9 2>/dev/null"
        echo "启动脚本"
        ansible $1 -m shell -a "cd  /data/webcode/api/src/Oradt/CronBundle && nohup /usr/local/php/bin/php  /data/webcode/api/src/Oradt/CronBundle/daemon.php > /data/logs/daemon.log 2>&1 &"
    fi
sssss
}

function ModifyConfig(){
    echo "更新Card配置文件"
    sed -i -r s#[\'\"]WEB_SERVICE_ROOT_URL[\'\"].*#"'WEB_SERVICE_ROOT_URL' => 'http://10.10.10.7',"#g card/Apps/Conf/config.php
    sed -i -r s#[\'\"]STAMP_SYSTEM_PATH[\'\"].*#"'STAMP_SYSTEM_PATH' => 'http://172.17.1.223:8080',"#g card/Apps/Conf/config.php
    sed -i -r s#[\'\"]TEST_ACCOUNT[\'\"].*#"'TEST_ACCOUNT' => array('zhaoying026@oradt.com','yangxiaoyan@oradt.com'),"#g card/Apps/Conf/config.php

}
function ModifyAPIConfig(){
    echo "发现API配置文件，更新配置文件"
    sed -i 's/database_driver:.*/database_driver: pdo_mysql/g' $1
    sed -i 's/database_host:.*/database_host: 172.17.3.11/g' $1
    sed -i 's/database_port:.*/database_port: 3307/g' $1
    sed -i 's/database_name:.*/database_name: oradt_cloud_test2/g' $1
    sed -i 's/database_user:.*/database_user: oradt_test2/g' $1
    sed -i 's/database_password:.*/database_password: 12345678910/g' $1
    sed -i 's/im_database_host:.*/im_database_host: 172.17.3.1/g' $1
    sed -i 's/im_database_port:.*/im_database_port: 3366/g' $1
    sed -i 's/im_database_name:.*/im_database_name: V2Platform/g' $1
    sed -i 's/im_database_user:.*/im_database_user: v2_root/g' $1
    sed -i 's/im_database_password:.*/im_database_password: 654321/g' $1
    sed -i 's/IM_WEBSERVICE_URL:.*/IM_WEBSERVICE_URL: \"http:\/\/im.beta.oradt.com:5555\"/g' $1
    sed -i 's/scan_database_driver:.*/scan_database_driver: pdo_mysql/g' $1
    sed -i 's/scan_database_host:.*/scan_database_host: 172.17.3.11/g' $1
    sed -i 's/scan_database_port:.*/scan_database_port: 3307/g' $1
    sed -i 's/scan_database_name:.*/scan_database_name: imora_scan/g' $1
    sed -i 's/scan_database_user:.*/scan_database_user: imora_scan/g' $1
    sed -i 's/scan_database_password:.*/scan_database_password: 123456/g' $1
    sed -i 's/mailer_transport:.*/mailer_transport: NTLM/g' $1
    sed -i 's/mailer_host:.*/mailer_host: mail.oradt.com/g' $1
    sed -i 's/mailer_user:.*/mailer_user: messagecenter@oradt.com/g' $1
    sed -i 's/mailer_password:.*/mailer_password: z1x2@c3v4/g' $1
    sed -i 's/redis_open:.*/redis_open: false/g' $1
    sed -i 's/redis_key_pre:.*/redis_key_pre: \"221\"/g' $1
    sed -i 's/predis_clusters:.*/predis_clusters: "tcp:\/\/172.17.100.1:7001;tcp:\/\/172.17.100.1:7002;tcp:\/\/172.17.100.1:7003"/g' $1
    sed -i 's/kafka_host:.*/kafka_host: \"172.17.4.153:9092,172.17.4.154:9092,172.17.4.1:9092,172.17.4.2:9092,172.17.4.102:9092\"/g' $1
    sed -i 's/kafka_scancard:.*/kafka_scancard: api_scancard_fangzhen/g' $1
    sed -i 's/kafka_accountbasic:.*/kafka_accountbasic: api_accountbasic_fangzhen/g' $1
    sed -i 's/kafka_mapfriend:.*/kafka_mapfriend: api_mapfriend_fangzhen/g' $1
    sed -i 's/SMS_POPULAR_CODE:.*/SMS_POPULAR_CODE: \"拓展人脉商务神器，很时尚，一定要分享给您：http:\/\/101.251.193.29:82\/h5\/imora\/download.html，退订回复TD\"/g' $1
    sed -i 's/SMS_ADD_FRIENDS:.*/SMS_ADD_FRIENDS: \"HI，aa，我是bbccdd，诚邀您加入橙脉，随时随地拓展人脉、了解行业资讯、管理人脉 “橙脉”在手，职场我有！http:\/\/101.251.193.29:82\/h5\/imora\/download.html，退订回复TD\"/g' $1
    sed -i 's/HOST_URL:.*/HOST_URL: http:\/\/101.251.193.27:81/g' $1
    sed -i 's/DOC_ROOT:.*/DOC_ROOT: \/data\/images\/images\//g' $1
    sed -i 's/ELAS_URL:.*/ELAS_URL: "172.17.1.200:9200"/g' $1
}

function BackupOldCode(){
    if `ansible $1 -m shell -a "test -d /data/webcode/card" > /dev/null`
    then
        ansible $1 -m shell -a "mkdir -p $BackupDir"
        echo "备份以前的代码"
        echo "获得以前的版本号"
        OldVersion=`ansible $1 -m shell -a "grep 'APP_VERSION' /data/webcode/card/Apps/Conf/config.php" | grep APP_VERSION | grep -oP '\d+.\d+.\d+'`
        test -z $OldVersion && OldVersion=0.0.0
        echo "备份以前的版本到: $BackupDir/card_${BackupTime}_${OldVersion}"
    fi
}

function BackupAPIOldCode(){
    if `ansible $1 -m shell -a "test -d /data/webcode/api" > /dev/null`
    then
        ansible $1 -m shell -a "mkdir -p $BackupDir"
        echo "备份以前的代码"
        echo "获得以前的版本号"
        OldVersion=`ansible $1 -m shell -a "grep 'api_version' /data/webcode/api/app/config/parameters.yml" | grep -oP '(?<=dev_)\d+.\d+.\d+'`
        echo "这里使用Card的版本号作为备份文件的后缀名"
        echo "备份以前的版本到: $BackupDir/api_${BackupTime}_${Version}"
    fi
}


if [[ "$2" = "发布API补丁" ]]
then
    echo "更新类型: 发布API补丁" 
    echo "本地进行文件解压缩操作"
    if scp -P5022 root@106.37.218.151:$CardCodeDir/v$Version/oradtcloud_v*.tgz $WorkDir/CodeTemp/card/$Version > /dev/null 2>&1
    then
        :
    else
        echo "Error: 没有发现补丁"
        exit 1
    fi
    cd $WorkDir/CodeTemp/card/$Version/

    test ! -d api && mkdir api
    for i in `ls oradtcloud_v*.tgz | sort -n`
    do
        tar -xzf $i -C api
        echo "解压缩API补丁$i"
    done

    #if [ -f "api/app/config/parameters.yml" ]
    #then
    #    #ModifyAPIConfig api/app/config/parameters.yml
    #fi

    for i in `echo $HOSTS`
    do
        BackupAPIOldCode $i
        ansible $i -m shell -a "test -d /data/webcode/api && cp -a /data/webcode/api $BackupDir/api_${BackupTime}_${Version}" > /dev/null 2>&1
        echo "将本地API文件Copy到远程API服务器 $i"
        rsync --exclude ".git" -alz api/* $i:/data/webcode/api/
        MainAPI $i
    done

elif [[ "$2" = "发布名片录入补丁" ]]
then
    echo "更新类型: 发布名片录入补丁" 
    echo "本地进行文件解压缩操作"
    if scp -P5022 root@106.37.218.151:$CardCodeDir/v$Version/OradtWeb_IT_v${Version}.beta.patch*.tgz $WorkDir/CodeTemp/card/$Version > /dev/null 2>&1
    then
        :
    else
        echo "Error: 没有发现补丁"
        exit 1
    fi
    cd $WorkDir/CodeTemp/card/$Version/
    test ! -d card && mkdir card
    for i in `ls OradtWeb_IT_v${Version}.beta.patch*.tgz | sort -n`
    do
        tar -xzf $i -C card
        echo "解压缩补丁$i"
    done

    if [ -f "card/Apps/Conf/config.php" ]
    then
        echo "发现配置配置文件config.php"
        ModifyConfig card/Apps/Conf/config.php
    fi
    for i in `echo $HOSTS`
    do
        BackupOldCode $i
        ansible $i -m shell -a "test -d /data/webcode/card && cp -a /data/webcode/card $BackupDir/card_${BackupTime}_${OldVersion}" > /dev/null 2>&1
        echo "将本地文件Copy到远程服务器 $i"
        rsync --exclude ".git" -alz card/* $i:/data/webcode/card/
        Main $i
    done

elif [[ "$2" = "更新整个版本" ]]
then
    echo "新类型: 更新整个版本" 
    echo "处理主文件包 OradtWeb_IT_${Version}.beta.tgz"
    if scp -P5022 root@106.37.218.151:$CardCodeDir/v$Version/OradtWeb_IT_v${Version}.beta.tgz $WorkDir/CodeTemp/card/$Version > /dev/null 2>&1
    then
        :
    else
        echo "Error: 没有发现版本为${Version}的软件包"
        exit 1
    fi
    cd $WorkDir/CodeTemp/card/$Version/
    test ! -d card && mkdir card
    tar -xzf OradtWeb_IT_v${Version}.beta.tgz -C card

    echo "处理补丁"
    if cp $CardCodeDir/v$Version/OradtWeb_IT_v${Version}.beta.patch*.tgz $WorkDir/CodeTemp/card/$Version > /dev/null 2>&1
    then
        for i in `ls OradtWeb_IT_v${Version}.beta.patch*.tgz | sort -n`
        do
            tar -xzf $i -C card
            echo "解压缩补丁$i"
        done
    elif scp -P5022 root@106.37.218.151:$CardCodeDir/v$Version/oradtcloud_v*.tgz $WorkDir/CodeTemp/card/$Version > /dev/null 2>&1
    then

        test ! -d api && mkdir api
        for i in `ls oradtcloud_v*.tgz | sort -n`
        do
            tar -xzf $i -C api
            echo "解压缩API补丁$i"
        done

        if [ -f "api/app/config/parameters.yml" ]
        then
            ModifyAPIConfig api/app/config/parameters.yml
        fi

        for i in `echo $APIHOSTS`
        do
            BackupAPIOldCode $i
            ansible $i -m shell -a "test -d /data/webcode/api && cp -a /data/webcode/api $BackupDir/api_${BackupTime}_${Version}" >/dev/null 2>&1
            echo "将本地API文件Copy到远程API服务器 $i"
            rsync --exclude ".git" -alz api/* $i:/data/webcode/api/
            MainAPI $i
        done
    
    else
        echo "INFO: 没有发现补丁"
    fi

    if [ -f "card/Apps/Conf/config.php" ]
    then
        echo "发现配置配置文件config.php"
        ModifyConfig card/Apps/Conf/config.php
    fi
    for i in `echo $HOSTS`
    do
        BackupOldCode $i
        ansible $i -m shell -a "test -d /data/webcode/card && mv /data/webcode/card $BackupDir/card_${BackupTime}_${OldVersion}"
        echo "将本地文件Copy到远程服务器 $i"
        rsync --exclude ".git" -alz card/* $i:/data/webcode/card/
        Main $i
    done
elif [[ "$2" = "版本回退" ]]
then
    echo "更新类型: 版本回退"

    for i in `echo $HOSTS`
    do
        echo "开始回退 $i"
	SearchFile=`ansible $i -m shell -a "find /data/backup/ -maxdepth 2 -name $1" | awk -F'>>' '{print $NF}' >/dev/null`
       #if `ansible $i -m shell -a "test -d $BackupDir/$1" > /dev/null`
	if [ ! -n $SearchFile ]
        then
            BackupOldCode $i
            ansible $i -m shell -a "test -d /data/webcode/card && mv /data/webcode/card $BackupDir/card_${BackupTime}_${OldVersion}" > /dev/null 2>&1
            ansible $i -m shell -a "cp -a $BackupDir/$1 /data/webcode/card"
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
