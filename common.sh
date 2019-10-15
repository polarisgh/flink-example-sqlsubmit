#!/usr/bin/env bash

################################################################################
# Function of the following
# kafka集群常用脚本，提供的功能如下：
#  1.start_kafka_cluster           -- 启动集群（参数：无）
#  2.stop_kafka_cluster            -- 关闭kafka集群（参数：无）
#  3.create_kafka_topic            -- 创建kafka的topic（参数：$1-副本数；$2-分区数；$3-topic名称；）
#  4.drop_kafka_topic              -- 删除kafka的topic（参数：$1-topic名称）
#  5.clear_kafka_cluster           -- 清理kafka集群（参数：无）
#  6.send_messages_to_kafka        -- kafka生产者产生消息（参数：$1-json格式消息；$2-topic名称；）
#  7.consumer_messages_from_kafka  -- kafka消费者消费消息（参数：$1-topic名称；）
#  8.create_kafka_json_source      -- 示例：将json格式数据发送给kafka（参数：$1-topic名称）
#  9.start_flink_cluster           -- 启动Flink集群（参数：无）
# 10.stop_flink_cluster            -- 关闭Flink集群（参数：无）
################################################################################

source "$(dirname "$0")"/env.sh

# 启动集群（参数：无）
function start_kafka_cluster {

    for i in ${HOST_LIST[@]}
    do
    cmd1="if [[ -z ${KAFKA_DIR} ]]; then
            echo '${i} Must run setup KAFKA_DIR before attempting to start Kafka cluster'
            exit 1
          else
            echo '-----INFO:[$i] KAFKA_DIR{${KAFKA_DIR}} is right!'
          fi"
    ssh smartai@$i "$cmd1"
    done

    # 启动zookeeper集群
    for i in ${HOST_LIST[@]}
    do
    ssh smartai@$i "${ZOOKEEPER_HOME}/bin/zkServer.sh start"
    if [ $? -eq 0 ];then
        echo "-----INFO:[$i] zookeeper start successfully!"
    fi
    done

    sleep 1s

    # 启动kafka集群
    for i in ${HOST_LIST[@]}
    do
    ssh smartai@$i "${KAFKA_DIR}/bin/kafka-server-start.sh ${KAFKA_DIR}/config/server.properties >/dev/null 2>&1 &"
    if [ $? -eq 0 ];then
        echo "-----INFO:[$i] kafka start successfully!"
    fi
    done

    sleep 1s

    # 判断kafka是否已经正常启动，若未启动则休眠一会儿（1秒）继续监控，kafka启动后则本方法运行结束
    remote_result=$(ssh smartai@${KAFKA_MASTER} "${KAFKA_DIR}/bin/zookeeper-shell.sh ${ZOOKEEPER_LIST} ls /brokers/ids 2>&1")
    echo "remote_result=$remote_result"
    while [[ ${remote_result} =~ .*[].* ]]  || [[ ${remote_result} =~ .*Node\ does\ not\ exist.* ]]; do
      echo 'Waiting for broker...'
      sleep 1
      remote_result=$(ssh smartai@${KAFKA_MASTER} "${KAFKA_DIR}/bin/zookeeper-shell.sh ${ZOOKEEPER_LIST} ls /brokers/ids 2>&1")
    done

    # 打印各节点进程
    for i in ${HOST_LIST[@]}
    do
    echo "${i}------------------------------------"
    ssh smartai@$i "source ~/.bashrc && export PATH=${JAVA_HOME}/bin:\${PATH} && jps"
    done
}

# 关闭kafka集群（参数：无）
function stop_kafka_cluster {
    # 关闭kafka集群
    for i in ${HOST_LIST[@]}
    do
    ssh smartai@$i "${KAFKA_DIR}/bin/kafka-server-stop.sh ${KAFKA_DIR}/config/server.properties >/dev/null 2>&1 &"
    if [ $? -eq 0 ];then
        echo "-----INFO:[$i] kafka stop successfully!"
    fi
    done

    sleep 3s

    # 关闭zookeeper集群
    for i in ${HOST_LIST[@]}
    do
    ssh smartai@$i "${ZOOKEEPER_HOME}/bin/zkServer.sh stop"
    if [ $? -eq 0 ];then
        echo "-----INFO:[$i] zookeeper stop successfully!"
    fi
    done

    # 结束kafka进程，注意：结尾eeooff需要顶格写
    for i in ${HOST_LIST[@]}
    do
    PIDS=$(ssh smartai@${i} "source ~/.bashrc && export PATH=${JAVA_HOME}/bin:\${PATH} && jps -vl | grep -i 'kafka\.Kafka' | grep java | grep -v grep | awk '{print \$1}'|| echo """)
	echo $PIDS
	ssh -tt smartai@${i} >> test.log << eeooff
    if [ ! -z "$PIDS" ]; then
        kill -9 $PIDS
    fi
    exit
eeooff
    done

    # 结束zookeeper进程，注意：结尾eeooff需要顶格写
    for i in ${HOST_LIST[@]}
    do
    PIDS=$(ssh smartai@${i} "ps -ef | grep QuorumPeerMain | grep -v \"grep\" | awk '{print \$2}'")
    echo $PIDS
    ssh -tt smartai@${i} >> test.log << eeooff
    if [ ! -z "$PIDS" ]; then
        kill -9 $PIDS
    fi
    exit
eeooff
    done

    # 打印各节点进程
    for i in ${HOST_LIST[@]}
    do
    echo "${i}------------------------------------"
    ssh smartai@$i "source ~/.bashrc && export PATH=${JAVA_HOME}/bin:\${PATH} && jps"
    done
}

# 清理kafka集群（参数：无）
function clear_kafka_cluster {
    # 清理zookeeper集群
    for i in ${HOST_LIST[@]}
    do
    ssh smartai@$i "rm -rf ${ZOOKEEPER_HOME}/log/*;rm -rf ${ZOOKEEPER_HOME}/data/version*"
    if [ $? -eq 0 ];then
        echo "----- INFO:[$i] zookeeper clear successfully!"
    fi
    done

    # 清理kafka集群
    for i in ${HOST_LIST[@]}
    do
    ssh smartai@$i "rm -rf ${KAFKA_DIR}/tmp/kafka-logs/*"
    if [ $? -eq 0 ];then
        echo "----- INFO:[$i] kafka clear successfully!"
    fi
    done
}

# 创建kafka的topic（参数：$1-副本数；$2-分区数；$3-topic名称；）
function create_kafka_topic {
    ssh smartai@${KAFKA_MASTER} "${KAFKA_DIR}/bin/kafka-topics.sh --create --zookeeper ${ZOOKEEPER_LIST} --replication-factor $1 --partitions $2 --topic $3"
}

# 删除kafka的topic（参数：$1-topic名称）
function drop_kafka_topic {
    ssh smartai@${KAFKA_MASTER} "${KAFKA_DIR}/bin/kafka-topics.sh --delete --zookeeper ${ZOOKEEPER_LIST} --topic $1"
}

# kafka生产者产生消息（参数：$1-json格式消息；$2-topic名称；）
function send_messages_to_kafka {
    echo -e $1 | ssh smartai@${KAFKA_MASTER} "${KAFKA_DIR}/bin/kafka-console-producer.sh --broker-list ${BROKER_LIST} --topic $2"
    #echo -e $1 | ${KAFKA_DIR}/bin/kafka-console-producer.sh --broker-list ${BROKER_LIST} --topic $2
}

# kafka消费者消费消息（参数：$1-topic名称；）
function consumer_messages_from_kafka {
    ssh smartai@${KAFKA_MASTER} "${KAFKA_DIR}/bin/kafka-console-consumer.sh --bootstrap-server ${BROKER_LIST} --topic $1 --from-beginning"
}

# 示例：将json格式数据发送给kafka（参数：$1-topic名称）
function create_kafka_json_source {
    topicName="$1"
    create_kafka_topic 1 3 $topicName

    # put JSON data into Kafka
    echo "Sending messages to Kafka(${topicName})..."

    send_messages_to_kafka '{"user_id": "543462", "item_id":"1715", "category_id": "1464116", "behavior": "pv", "ts": "2017-11-25T01:04:00Z"}' $topicName
    send_messages_to_kafka '{"user_id": "662867", "item_id":"2244074", "category_id": "1575622", "behavior": "pv", "ts": "2017-11-26T01:02:00Z"}' $topicName
    send_messages_to_kafka '{"user_id": "662867", "item_id":"4435228", "category_id": "4131561", "behavior": "pv", "ts": "2017-11-26T01:01:48Z"}' $topicName
    send_messages_to_kafka '{"user_id": "937166", "item_id":"321683", "category_id": "2355072", "behavior": "pv", "ts": "2017-11-26T01:02:00Z"}' $topicName
    send_messages_to_kafka '{"user_id": "156905", "item_id":"2901727", "category_id": "3001296", "behavior": "pv", "ts": "2017-11-28T05:05:00Z"}' $topicName
}

# 启动Flink集群（参数：无）
function start_flink_cluster {

    cmd1="if [[ -z ${FLINK_DIR} ]]; then
            echo '${FLINK_MASTER} Must run setup FLINK_DIR before attempting to start flink cluster'
            exit 1
          else
            echo '-----INFO:[${FLINK_MASTER}] FLINK_DIR{${FLINK_DIR}} is right!'
          fi"
    ssh smartai@${FLINK_MASTER} -C "$cmd1"

    # 启动Flink集群
    for i in ${FLINK_MASTER[@]}
    do
    ssh smartai@$i "source ~/.bashrc && export PATH=${JAVA_HOME}/bin:\${PATH} && ${FLINK_DIR}/bin/start-cluster.sh"
    if [ $? -eq 0 ];then
        echo "-----INFO:[master-$i] flink cluster start successfully!"
    fi
    done

    sleep 3s

    # 打印各节点进程
    for i in ${HOST_LIST[@]}
    do
    echo "${i}------------------------------------"
    ssh smartai@$i "source ~/.bashrc && export PATH=${JAVA_HOME}/bin:\${PATH} && jps"
    done
}

# 关闭Flink集群（参数：无）
function stop_flink_cluster {
    # 关闭Flink集群
    for i in ${FLINK_MASTER[@]}
    do
    ssh smartai@$i "source ~/.bashrc && export PATH=${JAVA_HOME}/bin:\${PATH} && ${FLINK_DIR}/bin/stop-cluster.sh"
    if [ $? -eq 0 ];then
        echo "-----INFO:[master-$i] flink cluster stop successfully!"
    fi
    done

    sleep 3s

    # 打印各节点进程
    for i in ${HOST_LIST[@]}
    do
    echo "${i}------------------------------------"
    ssh smartai@$i "source ~/.bashrc && export PATH=${JAVA_HOME}/bin:\${PATH} && jps"
    done
}
