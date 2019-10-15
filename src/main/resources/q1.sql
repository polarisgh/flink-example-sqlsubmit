-- -- 开启 mini-batch
-- SET table.exec.mini-batch.enabled=true;
-- -- mini-batch的时间间隔，即作业需要额外忍受的延迟
-- SET table.exec.mini-batch.allow-latency=1s;
-- -- 一个 mini-batch 中允许最多缓存的数据
-- SET table.exec.mini-batch.size=1000;
-- -- 开启 local-global 优化
-- SET table.optimizer.agg-phase-strategy=TWO_PHASE;
-- -- 开启 distinct agg 切分
-- SET table.optimizer.distinct-agg.split.enabled=true;

-- source （使用Flink DDL去创建并连接Kafka中的topic）
CREATE TABLE user_log (
    user_id VARCHAR,
    item_id VARCHAR,
    category_id VARCHAR,
    behavior VARCHAR,
    ts TIMESTAMP
) WITH (
    'connector.type' = 'kafka', -- 使用 kafka connector
    'connector.version' = 'universal', -- kafka版本支持0.11+
    'connector.topic' = 'user_behavior', -- kafka topic
    'connector.startup-mode' = 'earliest-offset', -- 从起始 offset 开始读取
    'connector.properties.0.key' = 'zookeeper.connect',
    'connector.properties.0.value' = '192.168.0.15:2181,192.168.0.16:2181,192.168.0.17:2181',
    'connector.properties.1.key' = 'bootstrap.servers',
    'connector.properties.1.value' = '192.168.0.15:9092,192.168.0.16:9092,192.168.0.17:9092',
    'update-mode' = 'append',
    'format.type' = 'json', -- 数据源格式为json
    'format.derive-schema' = 'true' -- 从DDL schema确定json解析规则
);

-- sink（使用Flink DDL连接MySQL结果表）
CREATE TABLE pvuv_sink (
    dt VARCHAR,
    pv BIGINT,
    uv BIGINT
) WITH (
    'connector.type' = 'jdbc', -- 使用jdbc connector
    'connector.url' = 'jdbc:mysql://192.168.0.18:3306/flink_test',
    'connector.table' = 'pvuv_sink',
    'connector.username' = 'root',
    'connector.password' = '123456',
    'connector.write.flush.max-rows' = '1' -- 默认5000条，为了演示改为1条
);

-- Group Aggregation
INSERT INTO pvuv_sink
SELECT
  DATE_FORMAT(ts, 'yyyy-MM-dd HH:00') dt,
  COUNT(*) AS pv,
  COUNT(DISTINCT user_id) AS uv
FROM user_log
GROUP BY DATE_FORMAT(ts, 'yyyy-MM-dd HH:00');