#!/usr/bin/env bash
#
#

JenkinsHome="/var/lib/jenkins/workspace/测试环境\ API"
#BackupDir=/data/backup/`date +%Y%m%d`
BackupDir=/data/backup/API
BackupTime=`date +%Y%m%d%H%M%S`
WorkDir="/data/sh"
APICodeDir="/mnt/c-sw/Api"
APIHOST="fangzhenapi"


if `echo $1 | grep -P "^\d+\.\d+\.\d+$|^api_\d{14}_\d+\.\d+\.\d+$" > /dev/null 2>&1`
then
    :
else
    echo "Error: 输入有误，请重新输入(版本号:2.0.xx 或 者回退版本：api_20160720160559_2.x.x)"
    exit 1
fi

Version=$1
test -d $WorkDir/CodeTemp/api/$Version && mv $WorkDir/CodeTemp/api/$Version $WorkDir/CodeTemp/api/${Version}_${BackupTime}
test ! -d $WorkDir/CodeTemp/api/$Version && mkdir -p $WorkDir/CodeTemp/api/$Version
HOSTS=`awk 'BEGIN{RS=""}/fangzhenapi/{print $0}' /etc/ansible/hosts  | grep -oP '^172.*'`

function Main(){
    ansible $1 -m shell -a "test -d /data/webcode/api/app/logs && rm -fr /data/webcode/api/app/logs/*"
    ansible $1 -m shell -a "test -d /data/webcode/api/app/cache && rm -fr /data/webcode/api/app/cache/*"
    ansible $1 -m shell -a "chown nginx.nginx /data/webcode/api -R"
    if [[ "$1" = "172.17.1.221" ]]
    then
        echo "停止脚本"
        ansible $1 -m shell -a "ps -ef | grep run.php | grep -v 'grep' | awk '{print \$2,\$3}' | xargs kill -9 2>/dev/null"
        ansible $1 -m shell -a "ps -ef | grep 'Oradt/CronBundle/daemon.php' | grep -v 'grep' | awk '{print \$2,\$3}' | xargs kill -9 2>/dev/null"
        echo "启动脚本"
        ansible $1 -m shell -a "/usr/local/php/bin/php /data/webcode/api/src/Oradt/CronBundle/daemon.php -p /usr/local/php/bin/ > /data/logs/daemon.log 2>&1 &"
    fi

}

function ModifyMainConfig(){
    echo "更新主配置文件"
    sed -i 's/database_driver:.*/database_driver: pdo_mysql/g' $1
    sed -i 's/database_host:.*/database_host: 172.17.3.2/g' $1
    sed -i 's/database_port:.*/database_port: 3317/g' $1
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
    sed -i 's/scan_database_host:.*/scan_database_host: 172.17.3.2/g' $1
    sed -i 's/scan_database_port:.*/scan_database_port: 3327/g' $1
    sed -i 's/scan_database_name:.*/scan_database_name: imora_scan/g' $1
    sed -i 's/scan_database_user:.*/scan_database_user: imora_scan/g' $1
    sed -i 's/scan_database_password:.*/scan_database_password: 123456/g' $1
    sed -i 's/u8_database_host:.*/u8_database_host: 172.17.3.1/g' $1
    sed -i 's/u8_database_port:.*/u8_database_port: 3366/g' $1
    sed -i 's/u8_database_name:.*/u8_database_name: u8orderdb/g' $1
    sed -i 's/u8_database_user:.*/u8_database_user: appuser/g' $1
    sed -i 's/u8_database_password:.*/u8_database_password: app_79521/g' $1
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
    sed -i 's/kafka_contactcard:.*/kafka_contactcard: api_contactcard_fangzhen/g' $1
    sed -i 's/kafka_funccard:.*/kafka_funccard: api_funccard_fangzhen/g' $1
    sed -i 's/SMS_POPULAR_CODE:.*/SMS_POPULAR_CODE: \"拓展人脉商务神器，很时尚，一定要分享给您：http:\/\/101.251.193.29:82\/h5\/imora\/download.html，退订回复TD\"/g' $1
    sed -i 's/SMS_ADD_FRIENDS:.*/SMS_ADD_FRIENDS: \"HI，aa，我是bbccdd，诚邀您加入橙脉，随时随地拓展人脉、了解行业资讯、管理人脉 “橙脉”在手，职场我有！http:\/\/101.251.193.29:82\/h5\/imora\/download.html，退订回复TD\"/g' $1
    sed -i 's/HOST_URL:.*/HOST_URL: http:\/\/101.251.193.27:81/g' $1
    sed -i 's/DOC_ROOT:.*/DOC_ROOT: \/data\/images\/images\//g' $1
    sed -i "s/gearman_server:.*/gearman_server: '172.17.1.101:4730'/g" $1

    sed -i 's/ELAS_URL:.*/ELAS_URL: "172.17.1.200:8200"/g' $1
    sed -i "s/ELAS_INDEX:.*/ELAS_INDEX: 'sharecard_fangzhen'/g" $1
    sed -i "s/ELAS_TYPE:.*/ELAS_TYPE: 'sharecard_fangzhen'/g" $1
    sed -i "s/ELAS_SCANER_INDEX:.*/ELAS_SCANER_INDEX: 'scancard'/g" $1
    sed -i "s/ELAS_SCANER_TYPE:.*/ELAS_SCANER_TYPE: 'scard'/g" $1
    sed -i "s/USER_TYPE:.*/USER_TYPE: 'usercard_fangzhen'/g" $1

    sed -i "s/flight_appid:.*/flight_appid: simu/g" $1
    sed -i "s/flight_get_url:.*/flight_get_url: http:\/\/106.37.218.151:60001\/service\/fcz?/g" $1
    sed -i "s/flight_add_push:.*/flight_add_push: http:\/\/106.37.218.151:60001\/service\/fcz\/addflightpush?/g" $1

    sed -i "s/OCR_PATH:.*/OCR_PATH: \/data\/webcode\/ocr\/release\//g" $1
}

function ModifyParConfig()  {
    echo "更新par_const.yml"
    sed -i "s/ALIPAY_NOTIFY_URL.*/ALIPAY_NOTIFY_URL :  'http:\/\/101.251.193.27:81\/account\/trading\/alipay'/g" $1
    sed -i "s/BILL_NOTIFY_URL.*/BILL_NOTIFY_URL : 'http:\/\/101.251.193.27:81\/accountbiz\/order\/kqbgurl'/g" $1
}

function ModifyDesignConfig()  {
    echo "更新design_config.yml"
    sed -i "s/const ALIPAY_NOTIFY_URL.*/const ALIPAY_NOTIFY_URL = 'http:\/\/101.251.193.27:81\/design\/alipay';/g" $1
    sed -i "s/const WXAPP_NOTIFY_URL.*/const WXAPP_NOTIFY_URL = 'http:\/\/101.251.193.27:81\/design\/wxpay';/g" $1
    sed -i "s/const WXAPP_IMORA_NOTIFY_URL.*/const WXAPP_IMORA_NOTIFY_URL = 'http:\/\/101.251.193.27:81\/account\/trading\/wxpay';/g" $1
    sed -i "s/const WXGZH_NOTIFY_URL.*/const WXGZH_NOTIFY_URL = 'http:\/\/101.251.193.27:81\/design\/wxpayweb';/g" $1
}

function ModifyConfig() {
    if [ -f "api/app/config/parameters.yml" ]
    then
        ModifyMainConfig api/app/config/parameters.yml
    fi

    if [ -f "api/app/config/par_const.yml" ]
    then
        ModifyParConfig api/app/config/par_const.yml
    fi

    if [ -f "api/app/config/design_config.php" ]
    then
        ModifyDesignConfig api/app/config/design_config.php
    fi
}

function BackupOldCode(){
    if `ansible $1 -m shell -a "test -d /data/webcode/api" > /dev/null`
    then
        ansible $1 -m shell -a "test -d $BackupDir || mkdir -p $BackupDir"
        echo "备份以前的代码"
        echo "获得以前的版本号"
        OldVersion=`ansible $1 -m shell -a "grep 'api_version' /data/webcode/api/app/config/parameters.yml" | grep -oP '(?<=dev_)\d+.\d+.\d+'`
        echo "备份以前的版本到: $BackupDir/api_${BackupTime}_${OldVersion}"
    fi
}


if [[ "$2" = "更新补丁" ]]
then
    echo "更新类型: 发布补丁" 
    echo "本地进行文件解压缩操作"
    if scp -P5022 root@106.37.218.151:$APICodeDir/v$Version/oradt_cloud${Version}_patch*.tar.gz $WorkDir/CodeTemp/api/$Version > /dev/null 2>&1
    then
        :
    else
        echo "Error: 没有发现版本为${Version}的补丁包"
        exit 1
    fi

    cd $WorkDir/CodeTemp/api/$Version/
    test ! -d api && mkdir api
    for i in `ls oradt_cloud${Version}_patch*.tar.gz | sort -n`
    do
        tar -xzf $i -C api || tar zf $i -C api
        echo "解压缩补丁$i"
    done

    ModifyConfig
    
    for i in `echo $HOSTS`
    do
        echo "备份代码 $i"
        BackupOldCode $i
        ansible $i -m shell -a "test -d /data/webcode/api && cp -a /data/webcode/api $BackupDir/api_${BackupTime}_${OldVersion}"
        echo "将本地文件Copy到远程服务器 $i"
        rsync --exclude ".git" -alz api/* $i:/data/webcode/api/
        Main $i
    done

elif [[ "$2" = "更新整个版本" ]]
then
    echo "更新类型: 更新整个版本" 
    echo "处理主软件包 $oradt_cloud${Version}-api.tar.gz"
    if scp -P5022 root@106.37.218.151:$APICodeDir/v$Version/oradt_cloud${Version}-api.tar.gz $WorkDir/CodeTemp/api/$Version > /dev/null 2>&1
    then
        :
    else
        echo "Error: 没有发现版本为${Version}的软件包"
        exit 1
    fi
    cd $WorkDir/CodeTemp/api/$Version/
    tar -xzf oradt_cloud${Version}-api.tar.gz 
    cp -a imora_cloud/webservice api


    echo "处理补丁包"
    if scp -P5022 root@106.37.218.151:$APICodeDir/v$Version/oradt_cloud${Version}_patch*.tar.gz $WorkDir/CodeTemp/api/$Version > /dev/null 2>&1
    then
        for i in `ls oradt_cloud${Version}_patch*.tar.gz | sort -n`
        do
            tar -xzf $i -C api
            echo "解压缩补丁$i"
        done
    else
        echo "INFO: 没有发现补丁"
    fi

    ModifyConfig
     
    for i in `echo $HOSTS`
    do
        echo "备份代码 $i"
        BackupOldCode $i
        ansible $i -m shell -a "test -d /data/webcode/api && mv /data/webcode/api $BackupDir/api_${BackupTime}_${OldVersion}"
        echo "将本地文件Copy到远程服务器 $i"
        rsync --exclude ".git" -alz api/* $i:/data/webcode/api/
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
            ansible $i -m shell -a "test -d /data/webcode/api && mv /data/webcode/api $BackupDir/api_${BackupTime}_${OldVersion}"
            ansible $i -m shell -a "cp -a $BackupDir/$1 /data/webcode/api"
            Main $i
        else
            echo "Error: 没有回退地址为 $BackupDir/$1 的软件包"
            exit 1
        fi
    done
else
    echo "请选择更新类型"
    exit 1
fi
