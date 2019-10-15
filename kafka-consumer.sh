#!/usr/bin/env bash

source "$(dirname "$0")"/common.sh

consumer_messages_from_kafka ${KAFKA_TEST_TOPIC}
