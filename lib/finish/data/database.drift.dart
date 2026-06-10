// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kilt/finish/data/finish.dart' as i5;
import 'package:kilt/finish/data/database.dart' as i6;

class $FinishesTableTable extends i6.FinishesTable
    with i0.TableInfo<$FinishesTableTable, i5.Finish> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinishesTableTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const i0.VerificationMeta _identityIdMeta =
      i0.VerificationMeta('identityId');
  @override
  late final i0.GeneratedColumn<int> identityId = i0.GeneratedColumn<int>(
    'identity_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES identities_table (id) ON UPDATE CASCADE ON DELETE CASCADE',
    ),
  );
  static const i0.VerificationMeta _postIdMeta = i0.VerificationMeta('postId');
  @override
  late final i0.GeneratedColumn<int> postId = i0.GeneratedColumn<int>(
    'post_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _finishedAtMeta =
      i0.VerificationMeta('finishedAt');
  @override
  late final i0.GeneratedColumn<DateTime> finishedAt =
      i0.GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    false,
    type: i0.DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _photoPathMeta =
      i0.VerificationMeta('photoPath');
  @override
  late final i0.GeneratedColumn<String> photoPath = i0.GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<i0.GeneratedColumn> get $columns =>
      [id, identityId, postId, finishedAt, photoPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finishes_table';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i5.Finish> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('identity_id')) {
      context.handle(
        _identityIdMeta,
        identityId.isAcceptableOrUnknown(
            data['identity_id']!, _identityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_identityIdMeta);
    }
    if (data.containsKey('post_id')) {
      context.handle(
        _postIdMeta,
        postId.isAcceptableOrUnknown(data['post_id']!, _postIdMeta),
      );
    } else if (isInserting) {
      context.missing(_postIdMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(
            data['finished_at']!, _finishedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_finishedAtMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(
            data['photo_path']!, _photoPathMeta),
      );
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i5.Finish map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i5.Finish(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      identityId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}identity_id'],
      )!,
      postId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}post_id'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
    );
  }

  @override
  $FinishesTableTable createAlias(String alias) {
    return $FinishesTableTable(attachedDatabase, alias);
  }
}

class FinishesTableCompanion extends i0.UpdateCompanion<i5.Finish> {
  final i0.Value<int> id;
  final i0.Value<int> identityId;
  final i0.Value<int> postId;
  final i0.Value<DateTime> finishedAt;
  final i0.Value<String?> photoPath;
  const FinishesTableCompanion({
    this.id = const i0.Value.absent(),
    this.identityId = const i0.Value.absent(),
    this.postId = const i0.Value.absent(),
    this.finishedAt = const i0.Value.absent(),
    this.photoPath = const i0.Value.absent(),
  });
  FinishesTableCompanion.insert({
    this.id = const i0.Value.absent(),
    required int identityId,
    required int postId,
    required DateTime finishedAt,
    this.photoPath = const i0.Value.absent(),
  })  : identityId = i0.Value(identityId),
        postId = i0.Value(postId),
        finishedAt = i0.Value(finishedAt);
  static i0.Insertable<i5.Finish> custom({
    i0.Expression<int>? id,
    i0.Expression<int>? identityId,
    i0.Expression<int>? postId,
    i0.Expression<DateTime>? finishedAt,
    i0.Expression<String>? photoPath,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (identityId != null) 'identity_id': identityId,
      if (postId != null) 'post_id': postId,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (photoPath != null) 'photo_path': photoPath,
    });
  }

  FinishesTableCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<int>? identityId,
    i0.Value<int>? postId,
    i0.Value<DateTime>? finishedAt,
    i0.Value<String?>? photoPath,
  }) {
    return FinishesTableCompanion(
      id: id ?? this.id,
      identityId: identityId ?? this.identityId,
      postId: postId ?? this.postId,
      finishedAt: finishedAt ?? this.finishedAt,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (identityId.present) {
      map['identity_id'] = i0.Variable<int>(identityId.value);
    }
    if (postId.present) {
      map['post_id'] = i0.Variable<int>(postId.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = i0.Variable<DateTime>(finishedAt.value);
    }
    if (photoPath.present) {
      map['photo_path'] = i0.Variable<String>(photoPath.value);
    }
    return map;
  }
}
