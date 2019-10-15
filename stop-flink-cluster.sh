#!/usr/bin/env bash

source "$(dirname "$0")"/common.sh

# Stop flink cluster
echo "Stop flink cluster..."

stop_flink_cluster