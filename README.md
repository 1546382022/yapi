# 安装mongoDB

##  docker网络
我们将采用Docker专门为Yapi提供一个MongoDb，由于docker kill重启可能会改变ip，这将使得Yapi也必须重新部署，因此，我们需要一个固定ip的mongo。所以，必须提供自定义docker网络。

```sh
docker network create --subnet=172.18.0.0/16 tools-net
```

## 安装mongo镜像

```sh
 docker run  \
--name mongodb \
-p 27017:27017  \
-v /home/wushuang/test/db/:/data/db/ \
--net tools-net --ip 172.18.0.2 \
-d mongo --auth 
```

## 设置admin root用户

```sh
# 进入 容器
docker exec -it mongodb mongo admin

# 创建管理员账户
>db.createUser({ user: 'admin', pwd: 'admin123456', roles: [ { role: "root", db: "admin" } ] });

db.auth("admin", "admin123456")
```
## 设置yapi用户

```sh
 db.createUser({ 
 user: 'yapi', 
 pwd: 'yapi123456', 
 roles: [ 
 { role: "dbAdmin", db: "yapi" },
 { role: "readWrite", db: "yapi" } 
 ] 
 });

 db.auth("yapi", "yapi123456")

```


# 构建YAPI镜像

基于node:12的debian镜像，部署YApi. 首先要构建Yapi镜像。

## 下载源码：
https://codeload.github.com/YMFE/yapi/tar.gz/v1.8.9
```sh
wget -O yapi.tar.gz  https://codeload.github.com/YMFE/yapi/tar.gz/v1.8.9
```

## 新建Dockerfile

见本仓库`Dockerfile`

## 编写config.json

不需要ldap的可以去掉。

```js
{
    "port": "3001",
    "adminAccount": "******@163.com",
    "db": {
        "servername": "172.18.0.2",
        "DATABASE": "yapi",
        "port": "27017",
        "user": "yapi",
        "pass": "yapi123456",
        "authSource": "admin"
    },
    "mail": {
        "enable": false,
        "host": "smtp.163.com",
        "port": 465,
        "from": "******@163.com",
        "auth": {
            "user": "******@163.com",
            "pass": "******"
        }
}
    "ldapLogin": {
      "enable": true,
      "server": "ldap://192.168.5.3:389",
      "baseDn": "cn=admin,dc=demo,dc=com",
      "bindPassword": "admin",
      "searchDn": "dc=demo,dc=com",
      "searchStandard": "mail",    
      "emailPostfix": "@demo.com",
      "emailKey": "mail",
      "usernameKey": "sn"
   }
}
```

## 编写`docker-entrypoint.sh`

```sh
 #!/bin/sh
set -eo pipefail

if [ "$1" = '--initdb' ]; then
        node /api/vendors/server/install.js
fi

if [ "$1" = '--help' ]; then
    echo "Usage:"
    echo "初始化db并启动:   docker run -d -p 84:3000 --name yapi --net tools-net --ip 172.18.0.3 yapi --initdb"
    echo "初始化后的账号为config.json 配置的邮箱， 密码为ymfe.org"
    echo "直接启动：  docker kill  yapi && docker rm yapi && docker run -d -p 3001:3001 --name yapi --net tools-net --ip 172.18.0.3 yapi"
    exit 1;
fi

node /api/vendors/server/app.js

exec "$@"
```

## 构建

```sh
docker build -t yapi .
```