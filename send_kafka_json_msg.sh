#!/usr/bin/env bash

source "$(dirname "$0")"/common.sh

create_kafka_json_source ${KAFKA_TEST_TOPIC}
