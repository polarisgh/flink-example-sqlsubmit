#!/usr/bin/env bash

################################################################################
# Function of the following
# Simulation data source,then send messages to kafka cluster in json format
################################################################################

source "$(dirname "$0")"/common.sh

# Simulation data source
echo "Generating sources..."

# Create kafka topic
create_kafka_topic 1 3 ${KAFKA_TEST_TOPIC}

# Send messages to kafka cluster in json format
#java -cp target/flink-example-sqlsubmit.jar com.lonton.t8.sqlsubmit.SourceGenerator ${SEND_MSG_SPEED} | ${KAFKA_DIR}/bin/kafka-console-producer.sh --broker-list ${BROKER_LIST} --topic ${KAFKA_TEST_TOPIC}
java -cp target/flink-example-sqlsubmit.jar com.lonton.t8.sqlsubmit.SourceGenerator ${SEND_MSG_SPEED} | ssh smartai@${KAFKA_MASTER} "${KAFKA_DIR}/bin/kafka-console-producer.sh --broker-list ${BROKER_LIST} --topic ${KAFKA_TEST_TOPIC}"