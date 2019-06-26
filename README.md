## Docker-compose multiple Logstash

本仓库为多节点Logstash，数据均输出到es-tribe，让这个协调节点自己去负载均衡写入数据。配合[我的博客](<https://www.cnblogs.com/hellxz/p/docker_logstash_mutiple_nodes.html>)食用风味更佳

## 目录结构

```bash
├── docker-ls-multiple-down.sh
├── docker-ls-multiple-up.sh
├── logstash-01
│   ├── config
│   │   ├── logstash.conf
│   │   └── logstash.yml
│   ├── docker-compose.yml
│   └── .env
├── logstash-02
│   ├── config
│   │   ├── logstash.conf
│   │   └── logstash.yml
│   ├── docker-compose.yml
│   └── .env
└── logstash-03
    ├── config
    │   ├── logstash.conf
    │   └── logstash.yml
    ├── docker-compose.yml
    └── .env

```



## 文件说明

以`logstash-01`举例说明

`.env`为`docker-compose.yml`提供了Logstash配置文件目录的位置，如果不放置到其他位置，无需更改

```properties
# .env file for docker-compose default. please be careful.
# logstash config dir mount set. change inside dir config file to change logstash cluster settings.
# default use relation path. don't change if you don't know what means.
LOGSTASH_CONFIG_DIR=./config
```

`docker-compose.yml` 为docker-compose的配置文件，这里只读取了`.env`的配置文件的路径，并把路径下的`logstash.conf`挂载到容器中logstash目录下`pipeline/logstash.conf`，挂载`logstash.yml`到logstash目录下`config/logstash.yml`

```yaml
version: "3"
services:
    logstash-1:
        image: logstash:7.1.0
        container_name: logstash-1
        volumes:
            - ${LOGSTASH_CONFIG_DIR}/logstash.conf:/usr/share/logstash/pipeline/logstash.conf:rw
            - ${LOGSTASH_CONFIG_DIR}/logstash.yml:/usr/share/logstash/config/logstash.yml:rw
        network_mode: "host"
```

`logstash.conf`为模板文件，输入输出以及配置都可以在这里修改

```json
input {     #输入
  kafka {	#使用kafka方式输入
    bootstrap_servers => "kafka1:9092,kafka2:9093,kafka3:9094" #kafka集群节点列表
    topics => ["all_logs"] #订阅名为all_logs的topic
    group_id => "logstash" #设置组为logstash
    codec => json #转换为json
  }
}

filter { #过滤分词等都在这里配置，暂时未配置

}

output {     #输出
  elasticsearch { #输出到es
    hosts => ["10.2.114.110:9204"] #es的路径
    index => "all-logs-%{+YYYY.MM.dd}" #输出到es的索引名称，这里是每天一个索引
    #user => "elastic"
    #password => "changeme"
  }
  stdout {
    codec => rubydebug
  }
}

```

> 此处设置并不是本文中的重点，有兴趣和需要请参考其它文章的相关配置

`logstash.yml` 为logstash的配置文件，只写了些与集群相关的，还有更多请参考其它文章.

```yaml
# set now host ip to http.host
http.host: 10.2.114.110
# set the es-tribe-node host. let logstash monitor the es.
xpack.monitoring.elasticsearch.hosts:
- http://10.2.114.110:9204
# enable or disable the logstash monitoring the es.
xpack.monitoring.enabled: true

```

另外两个脚本文件，仅在使用同一台主机时使用，便捷启动/关闭多节点Logstash

> 这里没有指定Logstash启动时的端口号，Logstash默认端口为9600，多实例在同主机时，会自动分配9600后的端口

## 使用说明

1. 需要确保多台主机均能正常ping通
2. 确保Zookeeper集群与Kafka集群已经启动，并且Logstash订阅的borkers的列表能对得起来
3. 确保Elasticsearch集群正常启动
4. 宿主机`/etc/hosts`添加`kafka1`、`kafka2`、`kafka3`映射到对应的kafka所在的宿主机ip
5. 修改每个Logstash目录下的`config/logstash.conf`中的输出es部分的ip到es-tribe对应的宿主机ip
6. 修改每个Logstash目录下的`config/logstash.yml`中的`http.host`为当前宿主机ip, 修改`xpack.monitoring.elasticsearch.hosts`为当前es-tribe宿主机ip与port
7. 进入每个Logstash目录执行`docker-compose up -d`以启动集群，执行`docker-compose down`以关闭集群