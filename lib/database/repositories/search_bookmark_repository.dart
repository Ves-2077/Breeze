import 'package:zephyr/database/db.dart';
import 'package:zephyr/database/row_codec.dart';
import 'package:zephyr/object_box/model.dart';

const _bookmarkInsert =
    'INSERT INTO "SearchBookmark" '
    '("uniqueKey","source","keyword","externJson","anchorComicId",'
    '"anchorTitle","anchorCover","anchorPage","createdAt","updatedAt",'
    '"anchorIndex") VALUES (?,?,?,?,?,?,?,?,?,?,?)';

const _bookmarkUpsert =
    'INSERT INTO "SearchBookmark" '
    '("id","uniqueKey","source","keyword","externJson","anchorComicId",'
    '"anchorTitle","anchorCover","anchorPage","createdAt","updatedAt",'
    '"anchorIndex") VALUES (?,?,?,?,?,?,?,?,?,?,?,?) '
    'ON CONFLICT("id") DO UPDATE SET '
    '"uniqueKey"=excluded."uniqueKey","source"=excluded."source",'
    '"keyword"=excluded."keyword","externJson"=excluded."externJson",'
    '"anchorComicId"=excluded."anchorComicId",'
    '"anchorTitle"=excluded."anchorTitle",'
    '"anchorCover"=excluded."anchorCover",'
    '"anchorPage"=excluded."anchorPage","createdAt"=excluded."createdAt",'
    '"updatedAt"=excluded."updatedAt","anchorIndex"=excluded."anchorIndex"';

class SearchBookmarkRepository {
  final BreezeDatabase db;

  const SearchBookmarkRepository(this.db);

  static const String table = 'SearchBookmark';

  Future<SearchBookmark?> getById(int id) async {
    final rows = await db.query(
      'SELECT * FROM "SearchBookmark" WHERE "id" = ? LIMIT 1',
      <Object?>[id],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  Future<SearchBookmark?> getByKey(String uniqueKey) async {
    final rows = await db.query(
      'SELECT * FROM "SearchBookmark" WHERE "uniqueKey" = ? LIMIT 1',
      <Object?>[uniqueKey],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  Future<List<SearchBookmark>> getAll() async {
    final rows = await db.query(
      'SELECT * FROM "SearchBookmark" ORDER BY "updatedAt" DESC, "id" DESC',
    );
    return rows.map(_decode).toList();
  }

  Future<int> count() async {
    final rows = await db.query('SELECT COUNT(*) AS c FROM "SearchBookmark"');
    return (rows.single['c'] as num).toInt();
  }

  Future<int> put(SearchBookmark value) async {
    if (value.id > 0) {
      await db.execute(_bookmarkUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await db.execute(
      _bookmarkInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  Future<int> removeById(int id) async {
    final result = await db.execute(
      'DELETE FROM "SearchBookmark" WHERE "id" = ?',
      <Object?>[id],
    );
    return result.changes;
  }

  Future<int> removeAll() async {
    final result = await db.execute('DELETE FROM "SearchBookmark"');
    return result.changes;
  }

  List<Object?> _params(SearchBookmark v, {required bool includeId}) {
    return <Object?>[
      if (includeId) v.id,
      v.uniqueKey,
      v.source,
      v.keyword,
      v.externJson,
      v.anchorComicId,
      v.anchorTitle,
      v.anchorCover,
      v.anchorPage,
      dateToDb(v.createdAt),
      dateToDb(v.updatedAt),
      v.anchorIndex,
    ];
  }

  SearchBookmark _decode(Map<String, dynamic> row) {
    return SearchBookmark.fromJson(
      normalizeRow(
        withDefaultId(row),
        dates: const <String>{'createdAt', 'updatedAt'},
      ),
    );
  }
}
