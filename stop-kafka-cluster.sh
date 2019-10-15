#!/usr/bin/env bash

source "$(dirname "$0")"/common.sh

# Stop and clear Kafka cluster
echo "Stop and clear Kafka cluster..."

stop_kafka_cluster
clear_kafka_cluster