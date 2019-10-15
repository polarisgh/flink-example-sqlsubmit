#!/usr/bin/env bash

source "$(dirname "$0")"/common.sh

# prepare flink cluster
echo "Preparing flink cluster..."

start_flink_cluster