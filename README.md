# Flink1.9实战：使用Flink SQL（Blink Planner）读取Kafka并写入MySQL

# 说明
目前Flink1.9不支持SQL CLI中提交一个DDL语句,也不支持提交SQL脚本。本工程案例模拟PV、UV数据，通过kafka进行采集，Flink进行消费处理并转存至MySQL目标表的过程。

## 准备工作
1. 安装JDK、MySQL、Zookeeper、Kafka、Flink等相关组件。安装过程可参考：《[安装文档]-VirtualBox_Ubuntu-16.04_Flink-cluster-06-20191009-001.docx》。
2. 修改Flink集群配置`vi ~/modules/flink-1.9.0/conf/flink-conf.yaml`（taskmanager.numberOfTaskSlots: 10）。
3. 下载Flink connector相关依赖包，并上传至`~/modules/flink-1.9.0/lib`。（<http://central.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka_2.11/1.9.0/flink-sql-connector-kafka_2.11-1.9.0.jar>
 <http://central.maven.org/maven2/org/apache/flink/flink-json/1.9.0/flink-json-1.9.0-sql-jar.jar>
 <http://central.maven.org/maven2/org/apache/flink/flink-jdbc_2.11/1.9.0/flink-jdbc_2.11-1.9.0.jar>
 <https://cdn.mysql.com//Downloads/Connector-J/mysql-connector-java-5.1.48.tar.gz>）
4. 创建MySQL存储数据的目标表`flink_test.pvuv_sink`。
5. 修改`src/main/resources/`下的Flink SQL文件, e.g, `q1.sql`。
6. 修改`env.sh`，更改相关配置信息。
7. 编译打包项目`mvn clean package`并发布到集群环境下或者客户机，e.g. `LTSR005 /home/smartai/software/flink-example-sqlsubmit`。
8. 给脚本赋值权限`chmod 755 *.sh`。

## 步骤
```
# cygwin
cd /cygdrive/g/tmp/flink-example-sqlsubmit
# linux
cd /home/smartai/software/flink-example-sqlsubmit
```
1. 启动相关服务：MySQL-略；Kafka集群-`./start-kafka-cluster.sh`；flink集群-`./start-flink-cluster.sh`。
2. 关闭相关服务：MySQL-略；Kafka集群-`./stop-kafka-cluster.sh`；flink集群-`./stop-flink-cluster.sh`。
3. 运行`./source-generator.sh`。（创建kafka topic，并持续生产消息(来源：`src/main/resources/user_behavior.log`)并推送给kafka，可使用`./kafka-consumer.sh`验证kafka是否可以正常消费），也可以通过`./send_kafka_json_msg.sh`逐条发送消息（5条）。
4. 运行示例程序`./run.sh`。（消费kafka消息，并转储到MySQL目标表）
5. 查看任务`./bin/flink list`，取消任务`./bin/flink cancel ${JobID}`，或通过Web Dashboard <http://192.168.0.15:8081>方式查看和取消Flink任务，运行结果可以查看MySQL目标表`flink_test.pvuv_sink`。
6. 如果终端返回以下输出,这意味着成功提交Flink SQL job。

```
Starting execution of program
Job has been submitted with JobID ${JobID}
```

#### 配置Cygwin（客户机）单向免密访问linux集群服务器
```shell
# 在客户端生成公/私钥对，将私钥文件保存在客户端，再将公钥文件上传到服务器端（远程主机）
ssh-keygen
scp ~/.ssh/id_rsa.pub smartai@LTSR005:~/id_rsa_win.pub
scp ~/.ssh/id_rsa.pub smartai@LTSR006:~/id_rsa_win.pub
scp ~/.ssh/id_rsa.pub smartai@LTSR007:~/id_rsa_win.pub
# 各个远程主机将客户端公钥加入到authorized_keys
cat ~/id_rsa_win.pub >> ~/.ssh/authorized_keys
# 验证客户机免密登录
ssh smartai@LTSR005
ssh smartai@LTSR006
ssh smartai@LTSR007
```

### SSH访问慢解决方法
```shell
# 修改配置文件sshd_config（cygwin - vi /etc/sshd_config）/（linux - sudo vi /etc/ssh/ssh_config） 
# （1）修改"UseDNS"的值为"no"
# （2）修改"GSSAPIAuthentication"的值为"no"

# 修改server上nsswitch.conf文件
sudo vi /etc/nsswitch.conf
hosts: files dns [NOTFOUND=return]

# 重启ssh服务，最好是重启一次机器
net start sshd # cygwin
sudo service ssh restart # linux
```

## 补充

### kafka相关操作
```shell
# 进入kafka安装目录
cd ~/modules/kafka_2.11-0.11.0.3
# 查看kafka topic
bin/kafka-topics.sh --zookeeper 192.168.0.15:2181,192.168.0.16:2181,192.168.0.17:2181 --list
# 删除kafka topic
bin/kafka-topics.sh --delete --zookeeper 192.168.0.15:2181,192.168.0.16:2181,192.168.0.17:2181 --topic user_behavior
# 创建kafka topic
bin/kafka-topics.sh --zookeeper 192.168.0.15:2181,192.168.0.16:2181,192.168.0.17:2181 --create --topic user_behavior --replication-factor 1 --partitions 3
```

### MySQL相关SQL语句
```sql
CREATE DATABASE IF NOT EXISTS flink_test default character set utf8 COLLATE utf8_general_ci;
use flink_test;
drop table IF EXISTS  pvuv_sink;
CREATE TABLE pvuv_sink (
    dt VARCHAR(32),
    pv BIGINT(20),
    uv BIGINT(20)
)ENGINE=InnoDB AUTO_INCREMENT=556536 DEFAULT CHARSET=utf8 COMMENT='埋点统计表';

select * from pvuv_sink limit 100;
select count(*) from pvuv_sink;
delete from pvuv_sink;
```
