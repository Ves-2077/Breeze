//! 第一层 SQLite API：通用、异步、无业务实体。
//!
//! Dart 第二层负责建表/索引 SQL、事务边界、模型转换和版本迁移。
//! 这里只执行 SQL 和广播表变更。

use anyhow::{Context, Result};
use flutter_rust_bridge::frb;
use serde_json::{Map, Value, json};

use crate::db::obx_archive::archive_objectbox_data;
use crate::db::obx_reader::read_objectbox_database;
use crate::db::sql;
use crate::frb_generated::StreamSink;

#[frb]
pub async fn db_open(path: String) -> Result<i64> {
    sql::open(&path)
}

#[frb]
pub async fn db_close(handle: i64) -> Result<()> {
    sql::close(handle)
}

/// 查询返回 JSON 数组：`[{"col": value, ...}, ...]`。
#[frb]
pub async fn db_query(handle: i64, sql_text: String, params_json: String) -> Result<String> {
    sql::get(handle)?.query_json(&sql_text, &params_json)
}

/// 执行单条语句，返回 `{"changes": n, "lastInsertId": id}`。
#[frb]
pub async fn db_execute(handle: i64, sql_text: String, params_json: String) -> Result<String> {
    sql::get(handle)?.execute(&sql_text, &params_json)
}

/// 执行多条语句（建表/索引/迁移脚本）。
#[frb]
pub async fn db_execute_script(handle: i64, sql_text: String) -> Result<()> {
    sql::get(handle)?.execute_script(&sql_text)
}

/// 事务使用独立连接；`write=false` 时是只读事务。
#[frb]
pub async fn db_begin(handle: i64, write: bool) -> Result<i64> {
    sql::begin(handle, write)
}

#[frb]
pub async fn db_commit(tx: i64) -> Result<()> {
    sql::commit(tx)
}

#[frb]
pub async fn db_rollback(tx: i64) -> Result<()> {
    sql::rollback(tx)
}

/// 订阅表变更。事务提交/主连接 autocommit 后推送一次去重表名列表。
#[frb]
pub fn db_watch_changes(handle: i64, sink: StreamSink<Vec<String>>) -> Result<()> {
    let db = sql::get(handle)?;
    db.bus.add_listener(Box::new(move |tables| {
        let _ = sink.add(tables);
    }));
    Ok(())
}

/// 只读取旧 ObjectBox LMDB，不写 SQLite。
///
/// 返回格式：
/// `{"objectRows":55,"skippedRows":0,"entities":{"UserSetting":[{...}]}}`
/// 日期为 Unix 毫秒整数，List<String> 为 JSON 数组。
#[frb]
pub async fn db_inspect_objectbox(old_dir: String) -> Result<String> {
    let snapshot = read_objectbox_database(std::path::Path::new(&old_dir))?;
    let mut entities = Map::new();
    for (name, records) in snapshot.records {
        entities.insert(
            name,
            Value::Array(records.into_iter().map(Value::Object).collect()),
        );
    }
    Ok(json!({
        "objectRows": snapshot.object_rows,
        "skippedRows": snapshot.skipped_rows,
        "entities": entities,
    })
    .to_string())
}

/// 压缩迁移完成后的旧 ObjectBox `data.mdb`。
///
/// 归档写到同目录的 `data.mdb.7z`；只有完整解压并核对 MD5 与原文件一致后
/// 才会删除 `data.mdb`。失败时保留原文件，调用方可在下次启动重试。
#[frb]
pub async fn db_archive_objectbox_data(old_dir: String) -> Result<String> {
    tokio::task::spawn_blocking(move || {
        let outcome = archive_objectbox_data(std::path::Path::new(&old_dir))?;
        Ok::<_, anyhow::Error>(
            json!({
                "status": outcome.status.as_str(),
                "oldDir": old_dir,
                "originalBytes": outcome.original_bytes,
                "archiveBytes": outcome.archive_bytes,
            })
            .to_string(),
        )
    })
    .await
    .context("ObjectBox archive task failed")?
}
