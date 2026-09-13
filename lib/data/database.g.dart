// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ScriptsTable extends Scripts with TableInfo<$ScriptsTable, Script> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScriptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _workMeta = const VerificationMeta('work');
  @override
  late final GeneratedColumn<String> work = GeneratedColumn<String>(
    'work',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Gender, String> gender =
      GeneratedColumn<String>(
        'gender',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Gender>($ScriptsTable.$convertergender);
  @override
  late final GeneratedColumnWithTypeConverter<AgeRange, String> ageRange =
      GeneratedColumn<String>(
        'age_range',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AgeRange>($ScriptsTable.$converterageRange);
  @override
  late final GeneratedColumnWithTypeConverter<PracticeStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PracticeStatus>($ScriptsTable.$converterstatus);
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dialogueMeta = const VerificationMeta(
    'dialogue',
  );
  @override
  late final GeneratedColumn<bool> dialogue = GeneratedColumn<bool>(
    'dialogue',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dialogue" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _myRoleMeta = const VerificationMeta('myRole');
  @override
  late final GeneratedColumn<String> myRole = GeneratedColumn<String>(
    'my_role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _situationMeta = const VerificationMeta(
    'situation',
  );
  @override
  late final GeneratedColumn<String> situation = GeneratedColumn<String>(
    'situation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _objectiveMeta = const VerificationMeta(
    'objective',
  );
  @override
  late final GeneratedColumn<String> objective = GeneratedColumn<String>(
    'objective',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _obstacleMeta = const VerificationMeta(
    'obstacle',
  );
  @override
  late final GeneratedColumn<String> obstacle = GeneratedColumn<String>(
    'obstacle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ScriptMedium?, String> medium =
      GeneratedColumn<String>(
        'medium',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ScriptMedium?>($ScriptsTable.$convertermediumn);
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _synopsisMeta = const VerificationMeta(
    'synopsis',
  );
  @override
  late final GeneratedColumn<String> synopsis = GeneratedColumn<String>(
    'synopsis',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sceneContextMeta = const VerificationMeta(
    'sceneContext',
  );
  @override
  late final GeneratedColumn<String> sceneContext = GeneratedColumn<String>(
    'scene_context',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    work,
    memo,
    gender,
    ageRange,
    status,
    favorite,
    body,
    createdAt,
    updatedAt,
    dialogue,
    myRole,
    situation,
    objective,
    obstacle,
    author,
    medium,
    sourceUrl,
    synopsis,
    sceneContext,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scripts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Script> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('work')) {
      context.handle(
        _workMeta,
        work.isAcceptableOrUnknown(data['work']!, _workMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    } else if (isInserting) {
      context.missing(_favoriteMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('dialogue')) {
      context.handle(
        _dialogueMeta,
        dialogue.isAcceptableOrUnknown(data['dialogue']!, _dialogueMeta),
      );
    }
    if (data.containsKey('my_role')) {
      context.handle(
        _myRoleMeta,
        myRole.isAcceptableOrUnknown(data['my_role']!, _myRoleMeta),
      );
    }
    if (data.containsKey('situation')) {
      context.handle(
        _situationMeta,
        situation.isAcceptableOrUnknown(data['situation']!, _situationMeta),
      );
    }
    if (data.containsKey('objective')) {
      context.handle(
        _objectiveMeta,
        objective.isAcceptableOrUnknown(data['objective']!, _objectiveMeta),
      );
    }
    if (data.containsKey('obstacle')) {
      context.handle(
        _obstacleMeta,
        obstacle.isAcceptableOrUnknown(data['obstacle']!, _obstacleMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('synopsis')) {
      context.handle(
        _synopsisMeta,
        synopsis.isAcceptableOrUnknown(data['synopsis']!, _synopsisMeta),
      );
    }
    if (data.containsKey('scene_context')) {
      context.handle(
        _sceneContextMeta,
        sceneContext.isAcceptableOrUnknown(
          data['scene_context']!,
          _sceneContextMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Script map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Script(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      work: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      gender: $ScriptsTable.$convertergender.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}gender'],
        )!,
      ),
      ageRange: $ScriptsTable.$converterageRange.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}age_range'],
        )!,
      ),
      status: $ScriptsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      dialogue: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dialogue'],
      )!,
      myRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}my_role'],
      ),
      situation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}situation'],
      ),
      objective: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}objective'],
      ),
      obstacle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}obstacle'],
      ),
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      medium: $ScriptsTable.$convertermediumn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}medium'],
        ),
      ),
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      synopsis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synopsis'],
      ),
      sceneContext: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scene_context'],
      ),
    );
  }

  @override
  $ScriptsTable createAlias(String alias) {
    return $ScriptsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Gender, String, String> $convertergender =
      const EnumNameConverter<Gender>(Gender.values);
  static JsonTypeConverter2<AgeRange, String, String> $converterageRange =
      const EnumNameConverter<AgeRange>(AgeRange.values);
  static JsonTypeConverter2<PracticeStatus, String, String> $converterstatus =
      const EnumNameConverter<PracticeStatus>(PracticeStatus.values);
  static JsonTypeConverter2<ScriptMedium, String, String> $convertermedium =
      const EnumNameConverter<ScriptMedium>(ScriptMedium.values);
  static JsonTypeConverter2<ScriptMedium?, String?, String?> $convertermediumn =
      JsonTypeConverter2.asNullable($convertermedium);
}

class Script extends DataClass implements Insertable<Script> {
  final int id;
  final String? work;
  final String? memo;
  final Gender gender;
  final AgeRange ageRange;
  final PracticeStatus status;
  final bool favorite;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool dialogue;
  final String? myRole;
  final String? situation;
  final String? objective;
  final String? obstacle;
  final String? author;
  final ScriptMedium? medium;
  final String? sourceUrl;
  final String? synopsis;
  final String? sceneContext;
  const Script({
    required this.id,
    this.work,
    this.memo,
    required this.gender,
    required this.ageRange,
    required this.status,
    required this.favorite,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.dialogue,
    this.myRole,
    this.situation,
    this.objective,
    this.obstacle,
    this.author,
    this.medium,
    this.sourceUrl,
    this.synopsis,
    this.sceneContext,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || work != null) {
      map['work'] = Variable<String>(work);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    {
      map['gender'] = Variable<String>(
        $ScriptsTable.$convertergender.toSql(gender),
      );
    }
    {
      map['age_range'] = Variable<String>(
        $ScriptsTable.$converterageRange.toSql(ageRange),
      );
    }
    {
      map['status'] = Variable<String>(
        $ScriptsTable.$converterstatus.toSql(status),
      );
    }
    map['favorite'] = Variable<bool>(favorite);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['dialogue'] = Variable<bool>(dialogue);
    if (!nullToAbsent || myRole != null) {
      map['my_role'] = Variable<String>(myRole);
    }
    if (!nullToAbsent || situation != null) {
      map['situation'] = Variable<String>(situation);
    }
    if (!nullToAbsent || objective != null) {
      map['objective'] = Variable<String>(objective);
    }
    if (!nullToAbsent || obstacle != null) {
      map['obstacle'] = Variable<String>(obstacle);
    }
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || medium != null) {
      map['medium'] = Variable<String>(
        $ScriptsTable.$convertermediumn.toSql(medium),
      );
    }
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    if (!nullToAbsent || synopsis != null) {
      map['synopsis'] = Variable<String>(synopsis);
    }
    if (!nullToAbsent || sceneContext != null) {
      map['scene_context'] = Variable<String>(sceneContext);
    }
    return map;
  }

  ScriptsCompanion toCompanion(bool nullToAbsent) {
    return ScriptsCompanion(
      id: Value(id),
      work: work == null && nullToAbsent ? const Value.absent() : Value(work),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      gender: Value(gender),
      ageRange: Value(ageRange),
      status: Value(status),
      favorite: Value(favorite),
      body: Value(body),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      dialogue: Value(dialogue),
      myRole: myRole == null && nullToAbsent
          ? const Value.absent()
          : Value(myRole),
      situation: situation == null && nullToAbsent
          ? const Value.absent()
          : Value(situation),
      objective: objective == null && nullToAbsent
          ? const Value.absent()
          : Value(objective),
      obstacle: obstacle == null && nullToAbsent
          ? const Value.absent()
          : Value(obstacle),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      medium: medium == null && nullToAbsent
          ? const Value.absent()
          : Value(medium),
      sourceUrl: sourceUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUrl),
      synopsis: synopsis == null && nullToAbsent
          ? const Value.absent()
          : Value(synopsis),
      sceneContext: sceneContext == null && nullToAbsent
          ? const Value.absent()
          : Value(sceneContext),
    );
  }

  factory Script.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Script(
      id: serializer.fromJson<int>(json['id']),
      work: serializer.fromJson<String?>(json['work']),
      memo: serializer.fromJson<String?>(json['memo']),
      gender: $ScriptsTable.$convertergender.fromJson(
        serializer.fromJson<String>(json['gender']),
      ),
      ageRange: $ScriptsTable.$converterageRange.fromJson(
        serializer.fromJson<String>(json['ageRange']),
      ),
      status: $ScriptsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      favorite: serializer.fromJson<bool>(json['favorite']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      dialogue: serializer.fromJson<bool>(json['dialogue']),
      myRole: serializer.fromJson<String?>(json['myRole']),
      situation: serializer.fromJson<String?>(json['situation']),
      objective: serializer.fromJson<String?>(json['objective']),
      obstacle: serializer.fromJson<String?>(json['obstacle']),
      author: serializer.fromJson<String?>(json['author']),
      medium: $ScriptsTable.$convertermediumn.fromJson(
        serializer.fromJson<String?>(json['medium']),
      ),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      synopsis: serializer.fromJson<String?>(json['synopsis']),
      sceneContext: serializer.fromJson<String?>(json['sceneContext']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'work': serializer.toJson<String?>(work),
      'memo': serializer.toJson<String?>(memo),
      'gender': serializer.toJson<String>(
        $ScriptsTable.$convertergender.toJson(gender),
      ),
      'ageRange': serializer.toJson<String>(
        $ScriptsTable.$converterageRange.toJson(ageRange),
      ),
      'status': serializer.toJson<String>(
        $ScriptsTable.$converterstatus.toJson(status),
      ),
      'favorite': serializer.toJson<bool>(favorite),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'dialogue': serializer.toJson<bool>(dialogue),
      'myRole': serializer.toJson<String?>(myRole),
      'situation': serializer.toJson<String?>(situation),
      'objective': serializer.toJson<String?>(objective),
      'obstacle': serializer.toJson<String?>(obstacle),
      'author': serializer.toJson<String?>(author),
      'medium': serializer.toJson<String?>(
        $ScriptsTable.$convertermediumn.toJson(medium),
      ),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'synopsis': serializer.toJson<String?>(synopsis),
      'sceneContext': serializer.toJson<String?>(sceneContext),
    };
  }

  Script copyWith({
    int? id,
    Value<String?> work = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    Gender? gender,
    AgeRange? ageRange,
    PracticeStatus? status,
    bool? favorite,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? dialogue,
    Value<String?> myRole = const Value.absent(),
    Value<String?> situation = const Value.absent(),
    Value<String?> objective = const Value.absent(),
    Value<String?> obstacle = const Value.absent(),
    Value<String?> author = const Value.absent(),
    Value<ScriptMedium?> medium = const Value.absent(),
    Value<String?> sourceUrl = const Value.absent(),
    Value<String?> synopsis = const Value.absent(),
    Value<String?> sceneContext = const Value.absent(),
  }) => Script(
    id: id ?? this.id,
    work: work.present ? work.value : this.work,
    memo: memo.present ? memo.value : this.memo,
    gender: gender ?? this.gender,
    ageRange: ageRange ?? this.ageRange,
    status: status ?? this.status,
    favorite: favorite ?? this.favorite,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    dialogue: dialogue ?? this.dialogue,
    myRole: myRole.present ? myRole.value : this.myRole,
    situation: situation.present ? situation.value : this.situation,
    objective: objective.present ? objective.value : this.objective,
    obstacle: obstacle.present ? obstacle.value : this.obstacle,
    author: author.present ? author.value : this.author,
    medium: medium.present ? medium.value : this.medium,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    synopsis: synopsis.present ? synopsis.value : this.synopsis,
    sceneContext: sceneContext.present ? sceneContext.value : this.sceneContext,
  );
  Script copyWithCompanion(ScriptsCompanion data) {
    return Script(
      id: data.id.present ? data.id.value : this.id,
      work: data.work.present ? data.work.value : this.work,
      memo: data.memo.present ? data.memo.value : this.memo,
      gender: data.gender.present ? data.gender.value : this.gender,
      ageRange: data.ageRange.present ? data.ageRange.value : this.ageRange,
      status: data.status.present ? data.status.value : this.status,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      dialogue: data.dialogue.present ? data.dialogue.value : this.dialogue,
      myRole: data.myRole.present ? data.myRole.value : this.myRole,
      situation: data.situation.present ? data.situation.value : this.situation,
      objective: data.objective.present ? data.objective.value : this.objective,
      obstacle: data.obstacle.present ? data.obstacle.value : this.obstacle,
      author: data.author.present ? data.author.value : this.author,
      medium: data.medium.present ? data.medium.value : this.medium,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      synopsis: data.synopsis.present ? data.synopsis.value : this.synopsis,
      sceneContext: data.sceneContext.present
          ? data.sceneContext.value
          : this.sceneContext,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Script(')
          ..write('id: $id, ')
          ..write('work: $work, ')
          ..write('memo: $memo, ')
          ..write('gender: $gender, ')
          ..write('ageRange: $ageRange, ')
          ..write('status: $status, ')
          ..write('favorite: $favorite, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dialogue: $dialogue, ')
          ..write('myRole: $myRole, ')
          ..write('situation: $situation, ')
          ..write('objective: $objective, ')
          ..write('obstacle: $obstacle, ')
          ..write('author: $author, ')
          ..write('medium: $medium, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('synopsis: $synopsis, ')
          ..write('sceneContext: $sceneContext')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    work,
    memo,
    gender,
    ageRange,
    status,
    favorite,
    body,
    createdAt,
    updatedAt,
    dialogue,
    myRole,
    situation,
    objective,
    obstacle,
    author,
    medium,
    sourceUrl,
    synopsis,
    sceneContext,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Script &&
          other.id == this.id &&
          other.work == this.work &&
          other.memo == this.memo &&
          other.gender == this.gender &&
          other.ageRange == this.ageRange &&
          other.status == this.status &&
          other.favorite == this.favorite &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.dialogue == this.dialogue &&
          other.myRole == this.myRole &&
          other.situation == this.situation &&
          other.objective == this.objective &&
          other.obstacle == this.obstacle &&
          other.author == this.author &&
          other.medium == this.medium &&
          other.sourceUrl == this.sourceUrl &&
          other.synopsis == this.synopsis &&
          other.sceneContext == this.sceneContext);
}

class ScriptsCompanion extends UpdateCompanion<Script> {
  final Value<int> id;
  final Value<String?> work;
  final Value<String?> memo;
  final Value<Gender> gender;
  final Value<AgeRange> ageRange;
  final Value<PracticeStatus> status;
  final Value<bool> favorite;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> dialogue;
  final Value<String?> myRole;
  final Value<String?> situation;
  final Value<String?> objective;
  final Value<String?> obstacle;
  final Value<String?> author;
  final Value<ScriptMedium?> medium;
  final Value<String?> sourceUrl;
  final Value<String?> synopsis;
  final Value<String?> sceneContext;
  const ScriptsCompanion({
    this.id = const Value.absent(),
    this.work = const Value.absent(),
    this.memo = const Value.absent(),
    this.gender = const Value.absent(),
    this.ageRange = const Value.absent(),
    this.status = const Value.absent(),
    this.favorite = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.dialogue = const Value.absent(),
    this.myRole = const Value.absent(),
    this.situation = const Value.absent(),
    this.objective = const Value.absent(),
    this.obstacle = const Value.absent(),
    this.author = const Value.absent(),
    this.medium = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.synopsis = const Value.absent(),
    this.sceneContext = const Value.absent(),
  });
  ScriptsCompanion.insert({
    this.id = const Value.absent(),
    this.work = const Value.absent(),
    this.memo = const Value.absent(),
    required Gender gender,
    required AgeRange ageRange,
    required PracticeStatus status,
    required bool favorite,
    required String body,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.dialogue = const Value.absent(),
    this.myRole = const Value.absent(),
    this.situation = const Value.absent(),
    this.objective = const Value.absent(),
    this.obstacle = const Value.absent(),
    this.author = const Value.absent(),
    this.medium = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.synopsis = const Value.absent(),
    this.sceneContext = const Value.absent(),
  }) : gender = Value(gender),
       ageRange = Value(ageRange),
       status = Value(status),
       favorite = Value(favorite),
       body = Value(body),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Script> custom({
    Expression<int>? id,
    Expression<String>? work,
    Expression<String>? memo,
    Expression<String>? gender,
    Expression<String>? ageRange,
    Expression<String>? status,
    Expression<bool>? favorite,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? dialogue,
    Expression<String>? myRole,
    Expression<String>? situation,
    Expression<String>? objective,
    Expression<String>? obstacle,
    Expression<String>? author,
    Expression<String>? medium,
    Expression<String>? sourceUrl,
    Expression<String>? synopsis,
    Expression<String>? sceneContext,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (work != null) 'work': work,
      if (memo != null) 'memo': memo,
      if (gender != null) 'gender': gender,
      if (ageRange != null) 'age_range': ageRange,
      if (status != null) 'status': status,
      if (favorite != null) 'favorite': favorite,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (dialogue != null) 'dialogue': dialogue,
      if (myRole != null) 'my_role': myRole,
      if (situation != null) 'situation': situation,
      if (objective != null) 'objective': objective,
      if (obstacle != null) 'obstacle': obstacle,
      if (author != null) 'author': author,
      if (medium != null) 'medium': medium,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (synopsis != null) 'synopsis': synopsis,
      if (sceneContext != null) 'scene_context': sceneContext,
    });
  }

  ScriptsCompanion copyWith({
    Value<int>? id,
    Value<String?>? work,
    Value<String?>? memo,
    Value<Gender>? gender,
    Value<AgeRange>? ageRange,
    Value<PracticeStatus>? status,
    Value<bool>? favorite,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? dialogue,
    Value<String?>? myRole,
    Value<String?>? situation,
    Value<String?>? objective,
    Value<String?>? obstacle,
    Value<String?>? author,
    Value<ScriptMedium?>? medium,
    Value<String?>? sourceUrl,
    Value<String?>? synopsis,
    Value<String?>? sceneContext,
  }) {
    return ScriptsCompanion(
      id: id ?? this.id,
      work: work ?? this.work,
      memo: memo ?? this.memo,
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      status: status ?? this.status,
      favorite: favorite ?? this.favorite,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dialogue: dialogue ?? this.dialogue,
      myRole: myRole ?? this.myRole,
      situation: situation ?? this.situation,
      objective: objective ?? this.objective,
      obstacle: obstacle ?? this.obstacle,
      author: author ?? this.author,
      medium: medium ?? this.medium,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      synopsis: synopsis ?? this.synopsis,
      sceneContext: sceneContext ?? this.sceneContext,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (work.present) {
      map['work'] = Variable<String>(work.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(
        $ScriptsTable.$convertergender.toSql(gender.value),
      );
    }
    if (ageRange.present) {
      map['age_range'] = Variable<String>(
        $ScriptsTable.$converterageRange.toSql(ageRange.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ScriptsTable.$converterstatus.toSql(status.value),
      );
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (dialogue.present) {
      map['dialogue'] = Variable<bool>(dialogue.value);
    }
    if (myRole.present) {
      map['my_role'] = Variable<String>(myRole.value);
    }
    if (situation.present) {
      map['situation'] = Variable<String>(situation.value);
    }
    if (objective.present) {
      map['objective'] = Variable<String>(objective.value);
    }
    if (obstacle.present) {
      map['obstacle'] = Variable<String>(obstacle.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (medium.present) {
      map['medium'] = Variable<String>(
        $ScriptsTable.$convertermediumn.toSql(medium.value),
      );
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (synopsis.present) {
      map['synopsis'] = Variable<String>(synopsis.value);
    }
    if (sceneContext.present) {
      map['scene_context'] = Variable<String>(sceneContext.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScriptsCompanion(')
          ..write('id: $id, ')
          ..write('work: $work, ')
          ..write('memo: $memo, ')
          ..write('gender: $gender, ')
          ..write('ageRange: $ageRange, ')
          ..write('status: $status, ')
          ..write('favorite: $favorite, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('dialogue: $dialogue, ')
          ..write('myRole: $myRole, ')
          ..write('situation: $situation, ')
          ..write('objective: $objective, ')
          ..write('obstacle: $obstacle, ')
          ..write('author: $author, ')
          ..write('medium: $medium, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('synopsis: $synopsis, ')
          ..write('sceneContext: $sceneContext')
          ..write(')'))
        .toString();
  }
}

class $ScriptTagsTable extends ScriptTags
    with TableInfo<$ScriptTagsTable, ScriptTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScriptTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scriptIdMeta = const VerificationMeta(
    'scriptId',
  );
  @override
  late final GeneratedColumn<int> scriptId = GeneratedColumn<int>(
    'script_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scripts (id)',
    ),
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [scriptId, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'script_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScriptTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('script_id')) {
      context.handle(
        _scriptIdMeta,
        scriptId.isAcceptableOrUnknown(data['script_id']!, _scriptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scriptIdMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scriptId, tag};
  @override
  ScriptTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScriptTag(
      scriptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}script_id'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
    );
  }

  @override
  $ScriptTagsTable createAlias(String alias) {
    return $ScriptTagsTable(attachedDatabase, alias);
  }
}

class ScriptTag extends DataClass implements Insertable<ScriptTag> {
  final int scriptId;
  final String tag;
  const ScriptTag({required this.scriptId, required this.tag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['script_id'] = Variable<int>(scriptId);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  ScriptTagsCompanion toCompanion(bool nullToAbsent) {
    return ScriptTagsCompanion(scriptId: Value(scriptId), tag: Value(tag));
  }

  factory ScriptTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScriptTag(
      scriptId: serializer.fromJson<int>(json['scriptId']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scriptId': serializer.toJson<int>(scriptId),
      'tag': serializer.toJson<String>(tag),
    };
  }

  ScriptTag copyWith({int? scriptId, String? tag}) =>
      ScriptTag(scriptId: scriptId ?? this.scriptId, tag: tag ?? this.tag);
  ScriptTag copyWithCompanion(ScriptTagsCompanion data) {
    return ScriptTag(
      scriptId: data.scriptId.present ? data.scriptId.value : this.scriptId,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScriptTag(')
          ..write('scriptId: $scriptId, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scriptId, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScriptTag &&
          other.scriptId == this.scriptId &&
          other.tag == this.tag);
}

class ScriptTagsCompanion extends UpdateCompanion<ScriptTag> {
  final Value<int> scriptId;
  final Value<String> tag;
  final Value<int> rowid;
  const ScriptTagsCompanion({
    this.scriptId = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScriptTagsCompanion.insert({
    required int scriptId,
    required String tag,
    this.rowid = const Value.absent(),
  }) : scriptId = Value(scriptId),
       tag = Value(tag);
  static Insertable<ScriptTag> custom({
    Expression<int>? scriptId,
    Expression<String>? tag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scriptId != null) 'script_id': scriptId,
      if (tag != null) 'tag': tag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScriptTagsCompanion copyWith({
    Value<int>? scriptId,
    Value<String>? tag,
    Value<int>? rowid,
  }) {
    return ScriptTagsCompanion(
      scriptId: scriptId ?? this.scriptId,
      tag: tag ?? this.tag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scriptId.present) {
      map['script_id'] = Variable<int>(scriptId.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScriptTagsCompanion(')
          ..write('scriptId: $scriptId, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScriptImagesTable extends ScriptImages
    with TableInfo<$ScriptImagesTable, ScriptImage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScriptImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scriptIdMeta = const VerificationMeta(
    'scriptId',
  );
  @override
  late final GeneratedColumn<int> scriptId = GeneratedColumn<int>(
    'script_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scripts (id)',
    ),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, scriptId, fileName, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'script_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScriptImage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('script_id')) {
      context.handle(
        _scriptIdMeta,
        scriptId.isAcceptableOrUnknown(data['script_id']!, _scriptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scriptIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScriptImage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScriptImage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scriptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}script_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $ScriptImagesTable createAlias(String alias) {
    return $ScriptImagesTable(attachedDatabase, alias);
  }
}

class ScriptImage extends DataClass implements Insertable<ScriptImage> {
  final int id;
  final int scriptId;
  final String fileName;
  final int position;
  const ScriptImage({
    required this.id,
    required this.scriptId,
    required this.fileName,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['script_id'] = Variable<int>(scriptId);
    map['file_name'] = Variable<String>(fileName);
    map['position'] = Variable<int>(position);
    return map;
  }

  ScriptImagesCompanion toCompanion(bool nullToAbsent) {
    return ScriptImagesCompanion(
      id: Value(id),
      scriptId: Value(scriptId),
      fileName: Value(fileName),
      position: Value(position),
    );
  }

  factory ScriptImage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScriptImage(
      id: serializer.fromJson<int>(json['id']),
      scriptId: serializer.fromJson<int>(json['scriptId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scriptId': serializer.toJson<int>(scriptId),
      'fileName': serializer.toJson<String>(fileName),
      'position': serializer.toJson<int>(position),
    };
  }

  ScriptImage copyWith({
    int? id,
    int? scriptId,
    String? fileName,
    int? position,
  }) => ScriptImage(
    id: id ?? this.id,
    scriptId: scriptId ?? this.scriptId,
    fileName: fileName ?? this.fileName,
    position: position ?? this.position,
  );
  ScriptImage copyWithCompanion(ScriptImagesCompanion data) {
    return ScriptImage(
      id: data.id.present ? data.id.value : this.id,
      scriptId: data.scriptId.present ? data.scriptId.value : this.scriptId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScriptImage(')
          ..write('id: $id, ')
          ..write('scriptId: $scriptId, ')
          ..write('fileName: $fileName, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, scriptId, fileName, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScriptImage &&
          other.id == this.id &&
          other.scriptId == this.scriptId &&
          other.fileName == this.fileName &&
          other.position == this.position);
}

class ScriptImagesCompanion extends UpdateCompanion<ScriptImage> {
  final Value<int> id;
  final Value<int> scriptId;
  final Value<String> fileName;
  final Value<int> position;
  const ScriptImagesCompanion({
    this.id = const Value.absent(),
    this.scriptId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.position = const Value.absent(),
  });
  ScriptImagesCompanion.insert({
    this.id = const Value.absent(),
    required int scriptId,
    required String fileName,
    required int position,
  }) : scriptId = Value(scriptId),
       fileName = Value(fileName),
       position = Value(position);
  static Insertable<ScriptImage> custom({
    Expression<int>? id,
    Expression<int>? scriptId,
    Expression<String>? fileName,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scriptId != null) 'script_id': scriptId,
      if (fileName != null) 'file_name': fileName,
      if (position != null) 'position': position,
    });
  }

  ScriptImagesCompanion copyWith({
    Value<int>? id,
    Value<int>? scriptId,
    Value<String>? fileName,
    Value<int>? position,
  }) {
    return ScriptImagesCompanion(
      id: id ?? this.id,
      scriptId: scriptId ?? this.scriptId,
      fileName: fileName ?? this.fileName,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scriptId.present) {
      map['script_id'] = Variable<int>(scriptId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScriptImagesCompanion(')
          ..write('id: $id, ')
          ..write('scriptId: $scriptId, ')
          ..write('fileName: $fileName, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScriptsTable scripts = $ScriptsTable(this);
  late final $ScriptTagsTable scriptTags = $ScriptTagsTable(this);
  late final $ScriptImagesTable scriptImages = $ScriptImagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    scripts,
    scriptTags,
    scriptImages,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ScriptsTableCreateCompanionBuilder = ScriptsCompanion Function({
  Value<int> id,
  Value<String?> work,
  Value<String?> memo,
  required Gender gender,
  required AgeRange ageRange,
  required PracticeStatus status,
  required bool favorite,
  required String body,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> dialogue,
  Value<String?> myRole,
  Value<String?> situation,
  Value<String?> objective,
  Value<String?> obstacle,
  Value<String?> author,
  Value<ScriptMedium?> medium,
  Value<String?> sourceUrl,
  Value<String?> synopsis,
  Value<String?> sceneContext,
});
typedef $$ScriptsTableUpdateCompanionBuilder = ScriptsCompanion Function({
  Value<int> id,
  Value<String?> work,
  Value<String?> memo,
  Value<Gender> gender,
  Value<AgeRange> ageRange,
  Value<PracticeStatus> status,
  Value<bool> favorite,
  Value<String> body,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> dialogue,
  Value<String?> myRole,
  Value<String?> situation,
  Value<String?> objective,
  Value<String?> obstacle,
  Value<String?> author,
  Value<ScriptMedium?> medium,
  Value<String?> sourceUrl,
  Value<String?> synopsis,
  Value<String?> sceneContext,
});

final class $$ScriptsTableReferences
    extends BaseReferences<_$AppDatabase, $ScriptsTable, Script> {
  $$ScriptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ScriptTagsTable, List<ScriptTag>>
  _scriptTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scriptTags,
    aliasName: 'scripts__id__script_tags__script_id',
  );

  $$ScriptTagsTableProcessedTableManager get scriptTagsRefs {
    final manager = $$ScriptTagsTableTableManager(
      $_db,
      $_db.scriptTags,
    ).filter((f) => f.scriptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_scriptTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScriptImagesTable, List<ScriptImage>>
  _scriptImagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.scriptImages,
    aliasName: 'scripts__id__script_images__script_id',
  );

  $$ScriptImagesTableProcessedTableManager get scriptImagesRefs {
    final manager = $$ScriptImagesTableTableManager(
      $_db,
      $_db.scriptImages,
    ).filter((f) => f.scriptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_scriptImagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ScriptsTableFilterComposer
    extends Composer<_$AppDatabase, $ScriptsTable> {
  $$ScriptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get work => $composableBuilder(
    column: $table.work,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Gender, Gender, String> get gender =>
      $composableBuilder(
        column: $table.gender,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<AgeRange, AgeRange, String> get ageRange =>
      $composableBuilder(
        column: $table.ageRange,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<PracticeStatus, PracticeStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dialogue => $composableBuilder(
    column: $table.dialogue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get myRole => $composableBuilder(
    column: $table.myRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get situation => $composableBuilder(
    column: $table.situation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get objective => $composableBuilder(
    column: $table.objective,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get obstacle => $composableBuilder(
    column: $table.obstacle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ScriptMedium?, ScriptMedium, String>
  get medium => $composableBuilder(
    column: $table.medium,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get synopsis => $composableBuilder(
    column: $table.synopsis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sceneContext => $composableBuilder(
    column: $table.sceneContext,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> scriptTagsRefs(
    Expression<bool> Function($$ScriptTagsTableFilterComposer f) f,
  ) {
    final $$ScriptTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scriptTags,
      getReferencedColumn: (t) => t.scriptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptTagsTableFilterComposer(
            $db: $db,
            $table: $db.scriptTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scriptImagesRefs(
    Expression<bool> Function($$ScriptImagesTableFilterComposer f) f,
  ) {
    final $$ScriptImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scriptImages,
      getReferencedColumn: (t) => t.scriptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptImagesTableFilterComposer(
            $db: $db,
            $table: $db.scriptImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScriptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScriptsTable> {
  $$ScriptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get work => $composableBuilder(
    column: $table.work,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ageRange => $composableBuilder(
    column: $table.ageRange,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dialogue => $composableBuilder(
    column: $table.dialogue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get myRole => $composableBuilder(
    column: $table.myRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get situation => $composableBuilder(
    column: $table.situation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get objective => $composableBuilder(
    column: $table.objective,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get obstacle => $composableBuilder(
    column: $table.obstacle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medium => $composableBuilder(
    column: $table.medium,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get synopsis => $composableBuilder(
    column: $table.synopsis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sceneContext => $composableBuilder(
    column: $table.sceneContext,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScriptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScriptsTable> {
  $$ScriptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get work =>
      $composableBuilder(column: $table.work, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Gender, String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AgeRange, String> get ageRange =>
      $composableBuilder(column: $table.ageRange, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PracticeStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get dialogue =>
      $composableBuilder(column: $table.dialogue, builder: (column) => column);

  GeneratedColumn<String> get myRole =>
      $composableBuilder(column: $table.myRole, builder: (column) => column);

  GeneratedColumn<String> get situation =>
      $composableBuilder(column: $table.situation, builder: (column) => column);

  GeneratedColumn<String> get objective =>
      $composableBuilder(column: $table.objective, builder: (column) => column);

  GeneratedColumn<String> get obstacle =>
      $composableBuilder(column: $table.obstacle, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ScriptMedium?, String> get medium =>
      $composableBuilder(column: $table.medium, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get synopsis =>
      $composableBuilder(column: $table.synopsis, builder: (column) => column);

  GeneratedColumn<String> get sceneContext => $composableBuilder(
    column: $table.sceneContext,
    builder: (column) => column,
  );

  Expression<T> scriptTagsRefs<T extends Object>(
    Expression<T> Function($$ScriptTagsTableAnnotationComposer a) f,
  ) {
    final $$ScriptTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scriptTags,
      getReferencedColumn: (t) => t.scriptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.scriptTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scriptImagesRefs<T extends Object>(
    Expression<T> Function($$ScriptImagesTableAnnotationComposer a) f,
  ) {
    final $$ScriptImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scriptImages,
      getReferencedColumn: (t) => t.scriptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.scriptImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ScriptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScriptsTable,
          Script,
          $$ScriptsTableFilterComposer,
          $$ScriptsTableOrderingComposer,
          $$ScriptsTableAnnotationComposer,
          $$ScriptsTableCreateCompanionBuilder,
          $$ScriptsTableUpdateCompanionBuilder,
          (Script, $$ScriptsTableReferences),
          Script,
          PrefetchHooks Function({bool scriptTagsRefs, bool scriptImagesRefs})
        > {
  $$ScriptsTableTableManager(_$AppDatabase db, $ScriptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScriptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScriptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScriptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> work = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<Gender> gender = const Value.absent(),
                Value<AgeRange> ageRange = const Value.absent(),
                Value<PracticeStatus> status = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> dialogue = const Value.absent(),
                Value<String?> myRole = const Value.absent(),
                Value<String?> situation = const Value.absent(),
                Value<String?> objective = const Value.absent(),
                Value<String?> obstacle = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<ScriptMedium?> medium = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> synopsis = const Value.absent(),
                Value<String?> sceneContext = const Value.absent(),
              }) => ScriptsCompanion(
                id: id,
                work: work,
                memo: memo,
                gender: gender,
                ageRange: ageRange,
                status: status,
                favorite: favorite,
                body: body,
                createdAt: createdAt,
                updatedAt: updatedAt,
                dialogue: dialogue,
                myRole: myRole,
                situation: situation,
                objective: objective,
                obstacle: obstacle,
                author: author,
                medium: medium,
                sourceUrl: sourceUrl,
                synopsis: synopsis,
                sceneContext: sceneContext,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> work = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                required Gender gender,
                required AgeRange ageRange,
                required PracticeStatus status,
                required bool favorite,
                required String body,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> dialogue = const Value.absent(),
                Value<String?> myRole = const Value.absent(),
                Value<String?> situation = const Value.absent(),
                Value<String?> objective = const Value.absent(),
                Value<String?> obstacle = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<ScriptMedium?> medium = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String?> synopsis = const Value.absent(),
                Value<String?> sceneContext = const Value.absent(),
              }) => ScriptsCompanion.insert(
                id: id,
                work: work,
                memo: memo,
                gender: gender,
                ageRange: ageRange,
                status: status,
                favorite: favorite,
                body: body,
                createdAt: createdAt,
                updatedAt: updatedAt,
                dialogue: dialogue,
                myRole: myRole,
                situation: situation,
                objective: objective,
                obstacle: obstacle,
                author: author,
                medium: medium,
                sourceUrl: sourceUrl,
                synopsis: synopsis,
                sceneContext: sceneContext,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScriptsTable, Script>(table),
                  $$ScriptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({scriptTagsRefs = false, scriptImagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (scriptTagsRefs) db.scriptTags,
                    if (scriptImagesRefs) db.scriptImages,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (scriptTagsRefs)
                        await $_getPrefetchedData<
                          Script,
                          $ScriptsTable,
                          ScriptTag
                        >(
                          currentTable: table,
                          referencedTable: $$ScriptsTableReferences
                              ._scriptTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScriptsTableReferences(
                                db,
                                table,
                                p0,
                              ).scriptTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scriptId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scriptImagesRefs)
                        await $_getPrefetchedData<
                          Script,
                          $ScriptsTable,
                          ScriptImage
                        >(
                          currentTable: table,
                          referencedTable: $$ScriptsTableReferences
                              ._scriptImagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScriptsTableReferences(
                                db,
                                table,
                                p0,
                              ).scriptImagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scriptId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ScriptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScriptsTable,
      Script,
      $$ScriptsTableFilterComposer,
      $$ScriptsTableOrderingComposer,
      $$ScriptsTableAnnotationComposer,
      $$ScriptsTableCreateCompanionBuilder,
      $$ScriptsTableUpdateCompanionBuilder,
      (Script, $$ScriptsTableReferences),
      Script,
      PrefetchHooks Function({bool scriptTagsRefs, bool scriptImagesRefs})
    >;
typedef $$ScriptTagsTableCreateCompanionBuilder = ScriptTagsCompanion Function({
  required int scriptId,
  required String tag,
  Value<int> rowid,
});
typedef $$ScriptTagsTableUpdateCompanionBuilder = ScriptTagsCompanion Function({
  Value<int> scriptId,
  Value<String> tag,
  Value<int> rowid,
});

final class $$ScriptTagsTableReferences
    extends BaseReferences<_$AppDatabase, $ScriptTagsTable, ScriptTag> {
  $$ScriptTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScriptsTable _scriptIdTable(_$AppDatabase db) =>
      db.scripts.createAlias('script_tags__script_id__scripts__id');

  $$ScriptsTableProcessedTableManager get scriptId {
    final $_column = $_itemColumn<int>('script_id')!;

    final manager = $$ScriptsTableTableManager(
      $_db,
      $_db.scripts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scriptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScriptTagsTableFilterComposer
    extends Composer<_$AppDatabase, $ScriptTagsTable> {
  $$ScriptTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  $$ScriptsTableFilterComposer get scriptId {
    final $$ScriptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableFilterComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScriptTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScriptTagsTable> {
  $$ScriptTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScriptsTableOrderingComposer get scriptId {
    final $$ScriptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableOrderingComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScriptTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScriptTagsTable> {
  $$ScriptTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  $$ScriptsTableAnnotationComposer get scriptId {
    final $$ScriptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableAnnotationComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScriptTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScriptTagsTable,
          ScriptTag,
          $$ScriptTagsTableFilterComposer,
          $$ScriptTagsTableOrderingComposer,
          $$ScriptTagsTableAnnotationComposer,
          $$ScriptTagsTableCreateCompanionBuilder,
          $$ScriptTagsTableUpdateCompanionBuilder,
          (ScriptTag, $$ScriptTagsTableReferences),
          ScriptTag,
          PrefetchHooks Function({bool scriptId})
        > {
  $$ScriptTagsTableTableManager(_$AppDatabase db, $ScriptTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScriptTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScriptTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScriptTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> scriptId = const Value.absent(),
            Value<String> tag = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ScriptTagsCompanion(scriptId: scriptId, tag: tag, rowid: rowid),
          createCompanionCallback:
              ({
                required int scriptId,
                required String tag,
                Value<int> rowid = const Value.absent(),
              }) => ScriptTagsCompanion.insert(
                scriptId: scriptId,
                tag: tag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScriptTagsTable, ScriptTag>(table),
                  $$ScriptTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scriptId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scriptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.scriptId,
                        referencedTable: $$ScriptTagsTableReferences
                            ._scriptIdTable(db),
                        referencedColumn: $$ScriptTagsTableReferences
                            ._scriptIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ScriptTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScriptTagsTable,
      ScriptTag,
      $$ScriptTagsTableFilterComposer,
      $$ScriptTagsTableOrderingComposer,
      $$ScriptTagsTableAnnotationComposer,
      $$ScriptTagsTableCreateCompanionBuilder,
      $$ScriptTagsTableUpdateCompanionBuilder,
      (ScriptTag, $$ScriptTagsTableReferences),
      ScriptTag,
      PrefetchHooks Function({bool scriptId})
    >;
typedef $$ScriptImagesTableCreateCompanionBuilder =
    ScriptImagesCompanion Function({
      Value<int> id,
      required int scriptId,
      required String fileName,
      required int position,
    });
typedef $$ScriptImagesTableUpdateCompanionBuilder =
    ScriptImagesCompanion Function({
      Value<int> id,
      Value<int> scriptId,
      Value<String> fileName,
      Value<int> position,
    });

final class $$ScriptImagesTableReferences
    extends BaseReferences<_$AppDatabase, $ScriptImagesTable, ScriptImage> {
  $$ScriptImagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScriptsTable _scriptIdTable(_$AppDatabase db) =>
      db.scripts.createAlias('script_images__script_id__scripts__id');

  $$ScriptsTableProcessedTableManager get scriptId {
    final $_column = $_itemColumn<int>('script_id')!;

    final manager = $$ScriptsTableTableManager(
      $_db,
      $_db.scripts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scriptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScriptImagesTableFilterComposer
    extends Composer<_$AppDatabase, $ScriptImagesTable> {
  $$ScriptImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$ScriptsTableFilterComposer get scriptId {
    final $$ScriptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableFilterComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScriptImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ScriptImagesTable> {
  $$ScriptImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScriptsTableOrderingComposer get scriptId {
    final $$ScriptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableOrderingComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScriptImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScriptImagesTable> {
  $$ScriptImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$ScriptsTableAnnotationComposer get scriptId {
    final $$ScriptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scriptId,
      referencedTable: $db.scripts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScriptsTableAnnotationComposer(
            $db: $db,
            $table: $db.scripts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScriptImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScriptImagesTable,
          ScriptImage,
          $$ScriptImagesTableFilterComposer,
          $$ScriptImagesTableOrderingComposer,
          $$ScriptImagesTableAnnotationComposer,
          $$ScriptImagesTableCreateCompanionBuilder,
          $$ScriptImagesTableUpdateCompanionBuilder,
          (ScriptImage, $$ScriptImagesTableReferences),
          ScriptImage,
          PrefetchHooks Function({bool scriptId})
        > {
  $$ScriptImagesTableTableManager(_$AppDatabase db, $ScriptImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScriptImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScriptImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScriptImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> scriptId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => ScriptImagesCompanion(
                id: id,
                scriptId: scriptId,
                fileName: fileName,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int scriptId,
                required String fileName,
                required int position,
              }) => ScriptImagesCompanion.insert(
                id: id,
                scriptId: scriptId,
                fileName: fileName,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScriptImagesTable, ScriptImage>(table),
                  $$ScriptImagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scriptId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scriptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.scriptId,
                        referencedTable: $$ScriptImagesTableReferences
                            ._scriptIdTable(db),
                        referencedColumn: $$ScriptImagesTableReferences
                            ._scriptIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ScriptImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScriptImagesTable,
      ScriptImage,
      $$ScriptImagesTableFilterComposer,
      $$ScriptImagesTableOrderingComposer,
      $$ScriptImagesTableAnnotationComposer,
      $$ScriptImagesTableCreateCompanionBuilder,
      $$ScriptImagesTableUpdateCompanionBuilder,
      (ScriptImage, $$ScriptImagesTableReferences),
      ScriptImage,
      PrefetchHooks Function({bool scriptId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScriptsTableTableManager get scripts =>
      $$ScriptsTableTableManager(_db, _db.scripts);
  $$ScriptTagsTableTableManager get scriptTags =>
      $$ScriptTagsTableTableManager(_db, _db.scriptTags);
  $$ScriptImagesTableTableManager get scriptImages =>
      $$ScriptImagesTableTableManager(_db, _db.scriptImages);
}
