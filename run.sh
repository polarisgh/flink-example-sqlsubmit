#!/usr/bin/env bash

source "$(dirname "$0")"/env.sh

ssh ${SYS_USER}@${FLINK_MASTER} "mkdir -p ${PROJECT_DIR} && mkdir -p ${PROJECT_DIR}/target && mkdir -p ${PROJECT_DIR}/src/main/resources"
scp -r "$(pwd)"/target/flink-example-sqlsubmit.jar ${SYS_USER}@${FLINK_MASTER}:${PROJECT_DIR}/target
scp -r "$(pwd)"/src/main/resources/${FLINK_SQL_FILE} ${SYS_USER}@${FLINK_MASTER}:${PROJECT_DIR}/src/main/resources
ssh ${SYS_USER}@${FLINK_MASTER} "${FLINK_DIR}/bin/flink run -d -p 4 ${PROJECT_DIR}/target/flink-example-sqlsubmit.jar -w ${PROJECT_DIR}/src/main/resources/ -f ${FLINK_SQL_FILE}"
