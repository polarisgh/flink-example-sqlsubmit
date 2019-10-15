#!/usr/bin/env bash

source "$(dirname "$0")"/common.sh

# prepare Kafka cluster
echo "Preparing Kafka cluster..."

start_kafka_cluster