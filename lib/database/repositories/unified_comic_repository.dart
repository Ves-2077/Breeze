import 'package:zephyr/database/db.dart';
import 'package:zephyr/database/row_codec.dart';
import 'package:zephyr/object_box/model.dart';

const _favoriteInsert =
    'INSERT INTO "UnifiedComicFavorite" '
    '("uniqueKey","source","comicId","title","description","createdAt",'
    '"updatedAt","deleted","schemaVersion","cover","creator","titleMeta",'
    '"metadata") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)';

const _favoriteUpsert =
    'INSERT INTO "UnifiedComicFavorite" '
    '("id","uniqueKey","source","comicId","title","description","createdAt",'
    '"updatedAt","deleted","schemaVersion","cover","creator","titleMeta",'
    '"metadata") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?) '
    'ON CONFLICT("id") DO UPDATE SET '
    '"uniqueKey"=excluded."uniqueKey","source"=excluded."source",'
    '"comicId"=excluded."comicId","title"=excluded."title",'
    '"description"=excluded."description","createdAt"=excluded."createdAt",'
    '"updatedAt"=excluded."updatedAt","deleted"=excluded."deleted",'
    '"schemaVersion"=excluded."schemaVersion","cover"=excluded."cover",'
    '"creator"=excluded."creator","titleMeta"=excluded."titleMeta",'
    '"metadata"=excluded."metadata"';

class UnifiedComicFavoriteRepository {
  final BreezeDatabase db;

  const UnifiedComicFavoriteRepository(this.db);

  static const String table = 'UnifiedComicFavorite';

  Future<UnifiedComicFavorite?> getById(int id) async {
    final rows = await db.query(
      'SELECT * FROM "UnifiedComicFavorite" WHERE "id" = ? LIMIT 1',
      <Object?>[id],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  Future<UnifiedComicFavorite?> getByKey(String uniqueKey) async {
    final rows = await db.query(
      'SELECT * FROM "UnifiedComicFavorite" WHERE "uniqueKey" = ? LIMIT 1',
      <Object?>[uniqueKey],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  Future<List<UnifiedComicFavorite>> getAll() async {
    final rows = await db.query(
      'SELECT * FROM "UnifiedComicFavorite" ORDER BY "id"',
    );
    return rows.map(_decode).toList();
  }

  Future<List<UnifiedComicFavorite>> listActive() async {
    final rows = await db.query(
      'SELECT * FROM "UnifiedComicFavorite" WHERE "deleted" = 0 ORDER BY "id"',
    );
    return rows.map(_decode).toList();
  }

  Future<int> count() async {
    final rows = await db.query(
      'SELECT COUNT(*) AS c FROM "UnifiedComicFavorite"',
    );
    return (rows.single['c'] as num).toInt();
  }

  Future<int> put(UnifiedComicFavorite value) async {
    if (value.id > 0) {
      await db.execute(_favoriteUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await db.execute(
      _favoriteInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  Future<List<int>> putMany(List<UnifiedComicFavorite> values) async {
    if (values.isEmpty) return const <int>[];
    return db.transaction((tx) async {
      final ids = <int>[];
      for (final value in values) {
        ids.add(await _putInTx(tx, value));
      }
      return ids;
    });
  }

  Future<int> removeById(int id) async {
    final result = await db.execute(
      'DELETE FROM "UnifiedComicFavorite" WHERE "id" = ?',
      <Object?>[id],
    );
    return result.changes;
  }

  Future<int> removeAll() async {
    final result = await db.execute('DELETE FROM "UnifiedComicFavorite"');
    return result.changes;
  }

  Stream<List<UnifiedComicFavorite>> watchActive() async* {
    yield await listActive();
    yield* db.changes
        .where((tables) => tables.contains(table))
        .asyncMap((_) => listActive());
  }

  Future<int> _putInTx(DbTransaction tx, UnifiedComicFavorite value) async {
    if (value.id > 0) {
      await tx.execute(_favoriteUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await tx.execute(
      _favoriteInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  List<Object?> _params(UnifiedComicFavorite v, {required bool includeId}) {
    return <Object?>[
      if (includeId) v.id,
      v.uniqueKey,
      v.source,
      v.comicId,
      v.title,
      v.description,
      dateToDb(v.createdAt),
      dateToDb(v.updatedAt),
      boolToDb(v.deleted),
      v.schemaVersion,
      v.cover,
      v.creator,
      v.titleMeta,
      v.metadata,
    ];
  }

  UnifiedComicFavorite _decode(Map<String, dynamic> row) {
    return UnifiedComicFavorite.fromJson(
      normalizeRow(
        withDefaultId(row),
        dates: const <String>{'createdAt', 'updatedAt'},
        bools: const <String>{'deleted'},
      ),
    );
  }
}

const _historyInsert =
    'INSERT INTO "UnifiedComicHistory" '
    '("uniqueKey","source","comicId","title","description","chapterId",'
    '"chapterTitle","chapterOrder","pageIndex","lastReadAt","deleted",'
    '"schemaVersion","createdAt","updatedAt","cover","creator","titleMeta",'
    '"metadata") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)';

const _historyUpsert =
    'INSERT INTO "UnifiedComicHistory" '
    '("id","uniqueKey","source","comicId","title","description","chapterId",'
    '"chapterTitle","chapterOrder","pageIndex","lastReadAt","deleted",'
    '"schemaVersion","createdAt","updatedAt","cover","creator","titleMeta",'
    '"metadata") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) '
    'ON CONFLICT("id") DO UPDATE SET '
    '"uniqueKey"=excluded."uniqueKey","source"=excluded."source",'
    '"comicId"=excluded."comicId","title"=excluded."title",'
    '"description"=excluded."description","chapterId"=excluded."chapterId",'
    '"chapterTitle"=excluded."chapterTitle","chapterOrder"=excluded."chapterOrder",'
    '"pageIndex"=excluded."pageIndex","lastReadAt"=excluded."lastReadAt",'
    '"deleted"=excluded."deleted","schemaVersion"=excluded."schemaVersion",'
    '"createdAt"=excluded."createdAt","updatedAt"=excluded."updatedAt",'
    '"cover"=excluded."cover","creator"=excluded."creator",'
    '"titleMeta"=excluded."titleMeta","metadata"=excluded."metadata"';

class UnifiedComicHistoryRepository {
  final BreezeDatabase db;

  const UnifiedComicHistoryRepository(this.db);

  static const String table = 'UnifiedComicHistory';

  Future<UnifiedComicHistory?> getById(int id) async {
    final rows = await db.query(
      'SELECT * FROM "UnifiedComicHistory" WHERE "id" = ? LIMIT 1',
      <Object?>[id],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  Future<UnifiedComicHistory?> getByKey(String uniqueKey) async {
    final rows = await db.query(
      'SELECT * FROM "UnifiedComicHistory" WHERE "uniqueKey" = ? LIMIT 1',
      <Object?>[uniqueKey],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  Future<List<UnifiedComicHistory>> getAll() async {
    final rows = await db.query(
      'SELECT * FROM "UnifiedComicHistory" ORDER BY "id"',
    );
    return rows.map(_decode).toList();
  }

  Future<List<UnifiedComicHistory>> listActive({bool ascending = false}) async {
    final direction = ascending ? 'ASC' : 'DESC';
    final rows = await db.query(
      'SELECT * FROM "UnifiedComicHistory" WHERE "deleted" = 0 '
      'ORDER BY "updatedAt" $direction, "id" $direction',
    );
    return rows.map(_decode).toList();
  }

  Future<int> count() async {
    final rows = await db.query(
      'SELECT COUNT(*) AS c FROM "UnifiedComicHistory"',
    );
    return (rows.single['c'] as num).toInt();
  }

  Future<int> put(UnifiedComicHistory value) async {
    if (value.id > 0) {
      await db.execute(_historyUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await db.execute(
      _historyInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  Future<List<int>> putMany(List<UnifiedComicHistory> values) async {
    if (values.isEmpty) return const <int>[];
    return db.transaction((tx) async {
      final ids = <int>[];
      for (final value in values) {
        ids.add(await _putInTx(tx, value));
      }
      return ids;
    });
  }

  Future<int> removeById(int id) async {
    final result = await db.execute(
      'DELETE FROM "UnifiedComicHistory" WHERE "id" = ?',
      <Object?>[id],
    );
    return result.changes;
  }

  Future<int> removeAll() async {
    final result = await db.execute('DELETE FROM "UnifiedComicHistory"');
    return result.changes;
  }

  Stream<List<UnifiedComicHistory>> watchActive({
    bool ascending = false,
  }) async* {
    yield await listActive(ascending: ascending);
    yield* db.changes
        .where((tables) => tables.contains(table))
        .asyncMap((_) => listActive(ascending: ascending));
  }

  Future<int> _putInTx(DbTransaction tx, UnifiedComicHistory value) async {
    if (value.id > 0) {
      await tx.execute(_historyUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await tx.execute(
      _historyInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  List<Object?> _params(UnifiedComicHistory v, {required bool includeId}) {
    return <Object?>[
      if (includeId) v.id,
      v.uniqueKey,
      v.source,
      v.comicId,
      v.title,
      v.description,
      v.chapterId,
      v.chapterTitle,
      v.chapterOrder,
      v.pageIndex,
      dateToDb(v.lastReadAt),
      boolToDb(v.deleted),
      v.schemaVersion,
      dateToDb(v.createdAt),
      dateToDb(v.updatedAt),
      v.cover,
      v.creator,
      v.titleMeta,
      v.metadata,
    ];
  }

  UnifiedComicHistory _decode(Map<String, dynamic> row) {
    return UnifiedComicHistory.fromJson(
      normalizeRow(
        withDefaultId(row),
        dates: const <String>{'createdAt', 'lastReadAt', 'updatedAt'},
        bools: const <String>{'deleted'},
      ),
    );
  }
}

const _downloadInsert =
    'INSERT INTO "UnifiedComicDownload" '
    '("uniqueKey","source","comicId","title","description","storageRoot",'
    '"createdAt","updatedAt","downloadedAt","deleted","schemaVersion",'
    '"totalViews","totalLikes","totalComments","isFavourite","isLiked",'
    '"allowComment","allowLike","allowFavorite","allowDownload","cover",'
    '"creator","titleMeta","metadata","chapters","detailJson","titleOverride",'
    '"coverOverride") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)';

const _downloadUpsert =
    'INSERT INTO "UnifiedComicDownload" '
    '("id","uniqueKey","source","comicId","title","description","storageRoot",'
    '"createdAt","updatedAt","downloadedAt","deleted","schemaVersion",'
    '"totalViews","totalLikes","totalComments","isFavourite","isLiked",'
    '"allowComment","allowLike","allowFavorite","allowDownload","cover",'
    '"creator","titleMeta","metadata","chapters","detailJson","titleOverride",'
    '"coverOverride") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) '
    'ON CONFLICT("id") DO UPDATE SET '
    '"uniqueKey"=excluded."uniqueKey","source"=excluded."source",'
    '"comicId"=excluded."comicId","title"=excluded."title",'
    '"description"=excluded."description","storageRoot"=excluded."storageRoot",'
    '"createdAt"=excluded."createdAt","updatedAt"=excluded."updatedAt",'
    '"downloadedAt"=excluded."downloadedAt","deleted"=excluded."deleted",'
    '"schemaVersion"=excluded."schemaVersion","totalViews"=excluded."totalViews",'
    '"totalLikes"=excluded."totalLikes","totalComments"=excluded."totalComments",'
    '"isFavourite"=excluded."isFavourite","isLiked"=excluded."isLiked",'
    '"allowComment"=excluded."allowComment","allowLike"=excluded."allowLike",'
    '"allowFavorite"=excluded."allowFavorite","allowDownload"=excluded."allowDownload",'
    '"cover"=excluded."cover","creator"=excluded."creator",'
    '"titleMeta"=excluded."titleMeta","metadata"=excluded."metadata",'
    '"chapters"=excluded."chapters","detailJson"=excluded."detailJson",'
    '"titleOverride"=excluded."titleOverride","coverOverride"=excluded."coverOverride"';

class UnifiedComicDownloadRepository {
  final BreezeDatabase db;

  const UnifiedComicDownloadRepository(this.db);

  static const String table = 'UnifiedComicDownload';

  Future<UnifiedComicDownload?> getById(int id) async {
    final rows = await db.query(
      'SELECT * FROM "UnifiedComicDownload" WHERE "id" = ? LIMIT 1',
      <Object?>[id],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  Future<UnifiedComicDownload?> getByKey(String uniqueKey) async {
    final rows = await db.query(
      'SELECT * FROM "UnifiedComicDownload" WHERE "uniqueKey" = ? LIMIT 1',
      <Object?>[uniqueKey],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  /// 按 comicId 取第一条下载记录（用于来源不一致时的兜底查找）。
  Future<UnifiedComicDownload?> getFirstByComicId(String comicId) async {
    final rows = await db.query(
      'SELECT * FROM "UnifiedComicDownload" WHERE "comicId" = ? '
      'ORDER BY "id" LIMIT 1',
      <Object?>[comicId],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  Future<List<UnifiedComicDownload>> getAll() async {
    final rows = await db.query(
      'SELECT * FROM "UnifiedComicDownload" ORDER BY "id"',
    );
    return rows.map(_decode).toList();
  }

  Future<List<UnifiedComicDownload>> listActive() async {
    final rows = await db.query(
      'SELECT * FROM "UnifiedComicDownload" WHERE "deleted" = 0 ORDER BY "id"',
    );
    return rows.map(_decode).toList();
  }

  Future<int> count() async {
    final rows = await db.query(
      'SELECT COUNT(*) AS c FROM "UnifiedComicDownload"',
    );
    return (rows.single['c'] as num).toInt();
  }

  Future<int> put(UnifiedComicDownload value) async {
    if (value.id > 0) {
      await db.execute(_downloadUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await db.execute(
      _downloadInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  Future<List<int>> putMany(List<UnifiedComicDownload> values) async {
    if (values.isEmpty) return const <int>[];
    return db.transaction((tx) async {
      final ids = <int>[];
      for (final value in values) {
        ids.add(await _putInTx(tx, value));
      }
      return ids;
    });
  }

  Future<int> removeById(int id) async {
    final result = await db.execute(
      'DELETE FROM "UnifiedComicDownload" WHERE "id" = ?',
      <Object?>[id],
    );
    return result.changes;
  }

  Future<int> removeAll() async {
    final result = await db.execute('DELETE FROM "UnifiedComicDownload"');
    return result.changes;
  }

  Stream<UnifiedComicDownload?> watchByKey(String uniqueKey) async* {
    yield await getByKey(uniqueKey);
    yield* db.changes
        .where((tables) => tables.contains(table))
        .asyncMap((_) => getByKey(uniqueKey));
  }

  Future<int> _putInTx(DbTransaction tx, UnifiedComicDownload value) async {
    if (value.id > 0) {
      await tx.execute(_downloadUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await tx.execute(
      _downloadInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  List<Object?> _params(UnifiedComicDownload v, {required bool includeId}) {
    return <Object?>[
      if (includeId) v.id,
      v.uniqueKey,
      v.source,
      v.comicId,
      v.title,
      v.description,
      v.storageRoot,
      dateToDb(v.createdAt),
      dateToDb(v.updatedAt),
      dateToDb(v.downloadedAt),
      boolToDb(v.deleted),
      v.schemaVersion,
      v.totalViews,
      v.totalLikes,
      v.totalComments,
      boolToDb(v.isFavourite),
      boolToDb(v.isLiked),
      boolToDb(v.allowComment),
      boolToDb(v.allowLike),
      boolToDb(v.allowFavorite),
      boolToDb(v.allowDownload),
      v.cover,
      v.creator,
      v.titleMeta,
      v.metadata,
      v.chapters,
      v.detailJson,
      v.titleOverride,
      v.coverOverride,
    ];
  }

  UnifiedComicDownload _decode(Map<String, dynamic> row) {
    return UnifiedComicDownload.fromJson(
      normalizeRow(
        withDefaultId(row),
        dates: const <String>{'createdAt', 'updatedAt', 'downloadedAt'},
        bools: const <String>{
          'deleted',
          'isFavourite',
          'isLiked',
          'allowComment',
          'allowLike',
          'allowFavorite',
          'allowDownload',
        },
      ),
    );
  }
}
