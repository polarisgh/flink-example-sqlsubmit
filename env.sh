#!/usr/bin/env bash

################################################################################
# Configuration information
################################################################################

PROJECT_DIR=/home/smartai/software/flink-example-sqlsubmit

# Cluster machines list
HOST_LIST=(LTSR005 LTSR006 LTSR007)
FLINK_MASTER=LTSR005
KAFKA_MASTER=LTSR005

# Component home directory
JAVA_HOME=/home/smartai/modules/jdk1.8.0_211
ZOOKEEPER_HOME=/home/smartai/modules/zookeeper-3.4.10
FLINK_DIR=/home/smartai/modules/flink-1.9.0
KAFKA_DIR=/home/smartai/modules/kafka_2.11-0.11.0.3

# Connector
ZOOKEEPER_LIST=192.168.0.15:2181,192.168.0.16:2181,192.168.0.17:2181
BROKER_LIST=192.168.0.15:9092,192.168.0.16:9092,192.168.0.17:9092

# kafka topic
KAFKA_TEST_TOPIC=user_behavior

# Send messages per second
#SEND_MSG_SPEED=1000
SEND_MSG_SPEED=1

# Flink SQL file
FLINK_SQL_FILE=q1.sql
