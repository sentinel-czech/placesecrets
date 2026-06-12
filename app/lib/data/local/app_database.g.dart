// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VisitedPoisTableTable extends VisitedPoisTable
    with TableInfo<$VisitedPoisTableTable, VisitedPoi> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitedPoisTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _poiIdMeta = const VerificationMeta('poiId');
  @override
  late final GeneratedColumn<String> poiId = GeneratedColumn<String>(
      'poi_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cityIdMeta = const VerificationMeta('cityId');
  @override
  late final GeneratedColumn<String> cityId = GeneratedColumn<String>(
      'city_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _poiNameMeta =
      const VerificationMeta('poiName');
  @override
  late final GeneratedColumn<String> poiName = GeneratedColumn<String>(
      'poi_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _visitedAtMeta =
      const VerificationMeta('visitedAt');
  @override
  late final GeneratedColumn<DateTime> visitedAt = GeneratedColumn<DateTime>(
      'visited_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _userNoteMeta =
      const VerificationMeta('userNote');
  @override
  late final GeneratedColumn<String> userNote = GeneratedColumn<String>(
      'user_note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userPhotoPathMeta =
      const VerificationMeta('userPhotoPath');
  @override
  late final GeneratedColumn<String> userPhotoPath = GeneratedColumn<String>(
      'user_photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _exportedToPdfMeta =
      const VerificationMeta('exportedToPdf');
  @override
  late final GeneratedColumn<bool> exportedToPdf = GeneratedColumn<bool>(
      'exported_to_pdf', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("exported_to_pdf" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        poiId,
        cityId,
        poiName,
        latitude,
        longitude,
        visitedAt,
        userNote,
        userPhotoPath,
        isSynced,
        exportedToPdf
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visited_pois';
  @override
  VerificationContext validateIntegrity(Insertable<VisitedPoi> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('poi_id')) {
      context.handle(
          _poiIdMeta, poiId.isAcceptableOrUnknown(data['poi_id']!, _poiIdMeta));
    } else if (isInserting) {
      context.missing(_poiIdMeta);
    }
    if (data.containsKey('city_id')) {
      context.handle(_cityIdMeta,
          cityId.isAcceptableOrUnknown(data['city_id']!, _cityIdMeta));
    } else if (isInserting) {
      context.missing(_cityIdMeta);
    }
    if (data.containsKey('poi_name')) {
      context.handle(_poiNameMeta,
          poiName.isAcceptableOrUnknown(data['poi_name']!, _poiNameMeta));
    } else if (isInserting) {
      context.missing(_poiNameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('visited_at')) {
      context.handle(_visitedAtMeta,
          visitedAt.isAcceptableOrUnknown(data['visited_at']!, _visitedAtMeta));
    } else if (isInserting) {
      context.missing(_visitedAtMeta);
    }
    if (data.containsKey('user_note')) {
      context.handle(_userNoteMeta,
          userNote.isAcceptableOrUnknown(data['user_note']!, _userNoteMeta));
    }
    if (data.containsKey('user_photo_path')) {
      context.handle(
          _userPhotoPathMeta,
          userPhotoPath.isAcceptableOrUnknown(
              data['user_photo_path']!, _userPhotoPathMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('exported_to_pdf')) {
      context.handle(
          _exportedToPdfMeta,
          exportedToPdf.isAcceptableOrUnknown(
              data['exported_to_pdf']!, _exportedToPdfMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  VisitedPoi map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitedPoi(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      poiId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poi_id'])!,
      cityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}city_id'])!,
      poiName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poi_name'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      visitedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}visited_at'])!,
      userNote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_note']),
      userPhotoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_photo_path']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      exportedToPdf: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}exported_to_pdf'])!,
    );
  }

  @override
  $VisitedPoisTableTable createAlias(String alias) {
    return $VisitedPoisTableTable(attachedDatabase, alias);
  }
}

class VisitedPoi extends DataClass implements Insertable<VisitedPoi> {
  final int localId;
  final String poiId;
  final String cityId;
  final String poiName;
  final double latitude;
  final double longitude;
  final DateTime visitedAt;
  final String? userNote;
  final String? userPhotoPath;
  final bool isSynced;
  final bool exportedToPdf;
  const VisitedPoi(
      {required this.localId,
      required this.poiId,
      required this.cityId,
      required this.poiName,
      required this.latitude,
      required this.longitude,
      required this.visitedAt,
      this.userNote,
      this.userPhotoPath,
      required this.isSynced,
      required this.exportedToPdf});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['poi_id'] = Variable<String>(poiId);
    map['city_id'] = Variable<String>(cityId);
    map['poi_name'] = Variable<String>(poiName);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['visited_at'] = Variable<DateTime>(visitedAt);
    if (!nullToAbsent || userNote != null) {
      map['user_note'] = Variable<String>(userNote);
    }
    if (!nullToAbsent || userPhotoPath != null) {
      map['user_photo_path'] = Variable<String>(userPhotoPath);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    map['exported_to_pdf'] = Variable<bool>(exportedToPdf);
    return map;
  }

  VisitedPoisTableCompanion toCompanion(bool nullToAbsent) {
    return VisitedPoisTableCompanion(
      localId: Value(localId),
      poiId: Value(poiId),
      cityId: Value(cityId),
      poiName: Value(poiName),
      latitude: Value(latitude),
      longitude: Value(longitude),
      visitedAt: Value(visitedAt),
      userNote: userNote == null && nullToAbsent
          ? const Value.absent()
          : Value(userNote),
      userPhotoPath: userPhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(userPhotoPath),
      isSynced: Value(isSynced),
      exportedToPdf: Value(exportedToPdf),
    );
  }

  factory VisitedPoi.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitedPoi(
      localId: serializer.fromJson<int>(json['localId']),
      poiId: serializer.fromJson<String>(json['poiId']),
      cityId: serializer.fromJson<String>(json['cityId']),
      poiName: serializer.fromJson<String>(json['poiName']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      visitedAt: serializer.fromJson<DateTime>(json['visitedAt']),
      userNote: serializer.fromJson<String?>(json['userNote']),
      userPhotoPath: serializer.fromJson<String?>(json['userPhotoPath']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      exportedToPdf: serializer.fromJson<bool>(json['exportedToPdf']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'poiId': serializer.toJson<String>(poiId),
      'cityId': serializer.toJson<String>(cityId),
      'poiName': serializer.toJson<String>(poiName),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'visitedAt': serializer.toJson<DateTime>(visitedAt),
      'userNote': serializer.toJson<String?>(userNote),
      'userPhotoPath': serializer.toJson<String?>(userPhotoPath),
      'isSynced': serializer.toJson<bool>(isSynced),
      'exportedToPdf': serializer.toJson<bool>(exportedToPdf),
    };
  }

  VisitedPoi copyWith(
          {int? localId,
          String? poiId,
          String? cityId,
          String? poiName,
          double? latitude,
          double? longitude,
          DateTime? visitedAt,
          Value<String?> userNote = const Value.absent(),
          Value<String?> userPhotoPath = const Value.absent(),
          bool? isSynced,
          bool? exportedToPdf}) =>
      VisitedPoi(
        localId: localId ?? this.localId,
        poiId: poiId ?? this.poiId,
        cityId: cityId ?? this.cityId,
        poiName: poiName ?? this.poiName,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        visitedAt: visitedAt ?? this.visitedAt,
        userNote: userNote.present ? userNote.value : this.userNote,
        userPhotoPath:
            userPhotoPath.present ? userPhotoPath.value : this.userPhotoPath,
        isSynced: isSynced ?? this.isSynced,
        exportedToPdf: exportedToPdf ?? this.exportedToPdf,
      );
  VisitedPoi copyWithCompanion(VisitedPoisTableCompanion data) {
    return VisitedPoi(
      localId: data.localId.present ? data.localId.value : this.localId,
      poiId: data.poiId.present ? data.poiId.value : this.poiId,
      cityId: data.cityId.present ? data.cityId.value : this.cityId,
      poiName: data.poiName.present ? data.poiName.value : this.poiName,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      visitedAt: data.visitedAt.present ? data.visitedAt.value : this.visitedAt,
      userNote: data.userNote.present ? data.userNote.value : this.userNote,
      userPhotoPath: data.userPhotoPath.present
          ? data.userPhotoPath.value
          : this.userPhotoPath,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      exportedToPdf: data.exportedToPdf.present
          ? data.exportedToPdf.value
          : this.exportedToPdf,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitedPoi(')
          ..write('localId: $localId, ')
          ..write('poiId: $poiId, ')
          ..write('cityId: $cityId, ')
          ..write('poiName: $poiName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('userNote: $userNote, ')
          ..write('userPhotoPath: $userPhotoPath, ')
          ..write('isSynced: $isSynced, ')
          ..write('exportedToPdf: $exportedToPdf')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, poiId, cityId, poiName, latitude,
      longitude, visitedAt, userNote, userPhotoPath, isSynced, exportedToPdf);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitedPoi &&
          other.localId == this.localId &&
          other.poiId == this.poiId &&
          other.cityId == this.cityId &&
          other.poiName == this.poiName &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.visitedAt == this.visitedAt &&
          other.userNote == this.userNote &&
          other.userPhotoPath == this.userPhotoPath &&
          other.isSynced == this.isSynced &&
          other.exportedToPdf == this.exportedToPdf);
}

class VisitedPoisTableCompanion extends UpdateCompanion<VisitedPoi> {
  final Value<int> localId;
  final Value<String> poiId;
  final Value<String> cityId;
  final Value<String> poiName;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<DateTime> visitedAt;
  final Value<String?> userNote;
  final Value<String?> userPhotoPath;
  final Value<bool> isSynced;
  final Value<bool> exportedToPdf;
  const VisitedPoisTableCompanion({
    this.localId = const Value.absent(),
    this.poiId = const Value.absent(),
    this.cityId = const Value.absent(),
    this.poiName = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.visitedAt = const Value.absent(),
    this.userNote = const Value.absent(),
    this.userPhotoPath = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.exportedToPdf = const Value.absent(),
  });
  VisitedPoisTableCompanion.insert({
    this.localId = const Value.absent(),
    required String poiId,
    required String cityId,
    required String poiName,
    required double latitude,
    required double longitude,
    required DateTime visitedAt,
    this.userNote = const Value.absent(),
    this.userPhotoPath = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.exportedToPdf = const Value.absent(),
  })  : poiId = Value(poiId),
        cityId = Value(cityId),
        poiName = Value(poiName),
        latitude = Value(latitude),
        longitude = Value(longitude),
        visitedAt = Value(visitedAt);
  static Insertable<VisitedPoi> custom({
    Expression<int>? localId,
    Expression<String>? poiId,
    Expression<String>? cityId,
    Expression<String>? poiName,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? visitedAt,
    Expression<String>? userNote,
    Expression<String>? userPhotoPath,
    Expression<bool>? isSynced,
    Expression<bool>? exportedToPdf,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (poiId != null) 'poi_id': poiId,
      if (cityId != null) 'city_id': cityId,
      if (poiName != null) 'poi_name': poiName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (visitedAt != null) 'visited_at': visitedAt,
      if (userNote != null) 'user_note': userNote,
      if (userPhotoPath != null) 'user_photo_path': userPhotoPath,
      if (isSynced != null) 'is_synced': isSynced,
      if (exportedToPdf != null) 'exported_to_pdf': exportedToPdf,
    });
  }

  VisitedPoisTableCompanion copyWith(
      {Value<int>? localId,
      Value<String>? poiId,
      Value<String>? cityId,
      Value<String>? poiName,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<DateTime>? visitedAt,
      Value<String?>? userNote,
      Value<String?>? userPhotoPath,
      Value<bool>? isSynced,
      Value<bool>? exportedToPdf}) {
    return VisitedPoisTableCompanion(
      localId: localId ?? this.localId,
      poiId: poiId ?? this.poiId,
      cityId: cityId ?? this.cityId,
      poiName: poiName ?? this.poiName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      visitedAt: visitedAt ?? this.visitedAt,
      userNote: userNote ?? this.userNote,
      userPhotoPath: userPhotoPath ?? this.userPhotoPath,
      isSynced: isSynced ?? this.isSynced,
      exportedToPdf: exportedToPdf ?? this.exportedToPdf,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (poiId.present) {
      map['poi_id'] = Variable<String>(poiId.value);
    }
    if (cityId.present) {
      map['city_id'] = Variable<String>(cityId.value);
    }
    if (poiName.present) {
      map['poi_name'] = Variable<String>(poiName.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (visitedAt.present) {
      map['visited_at'] = Variable<DateTime>(visitedAt.value);
    }
    if (userNote.present) {
      map['user_note'] = Variable<String>(userNote.value);
    }
    if (userPhotoPath.present) {
      map['user_photo_path'] = Variable<String>(userPhotoPath.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (exportedToPdf.present) {
      map['exported_to_pdf'] = Variable<bool>(exportedToPdf.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitedPoisTableCompanion(')
          ..write('localId: $localId, ')
          ..write('poiId: $poiId, ')
          ..write('cityId: $cityId, ')
          ..write('poiName: $poiName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('userNote: $userNote, ')
          ..write('userPhotoPath: $userPhotoPath, ')
          ..write('isSynced: $isSynced, ')
          ..write('exportedToPdf: $exportedToPdf')
          ..write(')'))
        .toString();
  }
}

class $CachedPoisTableTable extends CachedPoisTable
    with TableInfo<$CachedPoisTableTable, CachedPoi> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPoisTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cityIdMeta = const VerificationMeta('cityId');
  @override
  late final GeneratedColumn<String> cityId = GeneratedColumn<String>(
      'city_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameJsonMeta =
      const VerificationMeta('nameJson');
  @override
  late final GeneratedColumn<String> nameJson = GeneratedColumn<String>(
      'name_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionJsonMeta =
      const VerificationMeta('descriptionJson');
  @override
  late final GeneratedColumn<String> descriptionJson = GeneratedColumn<String>(
      'description_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _geofenceRadiusMeta =
      const VerificationMeta('geofenceRadius');
  @override
  late final GeneratedColumn<double> geofenceRadius = GeneratedColumn<double>(
      'geofence_radius', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _photoUrlsJsonMeta =
      const VerificationMeta('photoUrlsJson');
  @override
  late final GeneratedColumn<String> photoUrlsJson = GeneratedColumn<String>(
      'photo_urls_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _audioUrlsJsonMeta =
      const VerificationMeta('audioUrlsJson');
  @override
  late final GeneratedColumn<String> audioUrlsJson = GeneratedColumn<String>(
      'audio_urls_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isPremiumMeta =
      const VerificationMeta('isPremium');
  @override
  late final GeneratedColumn<bool> isPremium = GeneratedColumn<bool>(
      'is_premium', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_premium" IN (0, 1))'));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        cityId,
        nameJson,
        descriptionJson,
        latitude,
        longitude,
        geofenceRadius,
        photoUrlsJson,
        audioUrlsJson,
        isPremium,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_pois';
  @override
  VerificationContext validateIntegrity(Insertable<CachedPoi> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('city_id')) {
      context.handle(_cityIdMeta,
          cityId.isAcceptableOrUnknown(data['city_id']!, _cityIdMeta));
    } else if (isInserting) {
      context.missing(_cityIdMeta);
    }
    if (data.containsKey('name_json')) {
      context.handle(_nameJsonMeta,
          nameJson.isAcceptableOrUnknown(data['name_json']!, _nameJsonMeta));
    } else if (isInserting) {
      context.missing(_nameJsonMeta);
    }
    if (data.containsKey('description_json')) {
      context.handle(
          _descriptionJsonMeta,
          descriptionJson.isAcceptableOrUnknown(
              data['description_json']!, _descriptionJsonMeta));
    } else if (isInserting) {
      context.missing(_descriptionJsonMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('geofence_radius')) {
      context.handle(
          _geofenceRadiusMeta,
          geofenceRadius.isAcceptableOrUnknown(
              data['geofence_radius']!, _geofenceRadiusMeta));
    } else if (isInserting) {
      context.missing(_geofenceRadiusMeta);
    }
    if (data.containsKey('photo_urls_json')) {
      context.handle(
          _photoUrlsJsonMeta,
          photoUrlsJson.isAcceptableOrUnknown(
              data['photo_urls_json']!, _photoUrlsJsonMeta));
    } else if (isInserting) {
      context.missing(_photoUrlsJsonMeta);
    }
    if (data.containsKey('audio_urls_json')) {
      context.handle(
          _audioUrlsJsonMeta,
          audioUrlsJson.isAcceptableOrUnknown(
              data['audio_urls_json']!, _audioUrlsJsonMeta));
    } else if (isInserting) {
      context.missing(_audioUrlsJsonMeta);
    }
    if (data.containsKey('is_premium')) {
      context.handle(_isPremiumMeta,
          isPremium.isAcceptableOrUnknown(data['is_premium']!, _isPremiumMeta));
    } else if (isInserting) {
      context.missing(_isPremiumMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedPoi map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPoi(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      cityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}city_id'])!,
      nameJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name_json'])!,
      descriptionJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}description_json'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      geofenceRadius: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}geofence_radius'])!,
      photoUrlsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}photo_urls_json'])!,
      audioUrlsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}audio_urls_json'])!,
      isPremium: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_premium'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CachedPoisTableTable createAlias(String alias) {
    return $CachedPoisTableTable(attachedDatabase, alias);
  }
}

class CachedPoi extends DataClass implements Insertable<CachedPoi> {
  final String id;
  final String cityId;
  final String nameJson;
  final String descriptionJson;
  final double latitude;
  final double longitude;
  final double geofenceRadius;
  final String photoUrlsJson;
  final String audioUrlsJson;
  final bool isPremium;
  final DateTime cachedAt;
  const CachedPoi(
      {required this.id,
      required this.cityId,
      required this.nameJson,
      required this.descriptionJson,
      required this.latitude,
      required this.longitude,
      required this.geofenceRadius,
      required this.photoUrlsJson,
      required this.audioUrlsJson,
      required this.isPremium,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['city_id'] = Variable<String>(cityId);
    map['name_json'] = Variable<String>(nameJson);
    map['description_json'] = Variable<String>(descriptionJson);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['geofence_radius'] = Variable<double>(geofenceRadius);
    map['photo_urls_json'] = Variable<String>(photoUrlsJson);
    map['audio_urls_json'] = Variable<String>(audioUrlsJson);
    map['is_premium'] = Variable<bool>(isPremium);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedPoisTableCompanion toCompanion(bool nullToAbsent) {
    return CachedPoisTableCompanion(
      id: Value(id),
      cityId: Value(cityId),
      nameJson: Value(nameJson),
      descriptionJson: Value(descriptionJson),
      latitude: Value(latitude),
      longitude: Value(longitude),
      geofenceRadius: Value(geofenceRadius),
      photoUrlsJson: Value(photoUrlsJson),
      audioUrlsJson: Value(audioUrlsJson),
      isPremium: Value(isPremium),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedPoi.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPoi(
      id: serializer.fromJson<String>(json['id']),
      cityId: serializer.fromJson<String>(json['cityId']),
      nameJson: serializer.fromJson<String>(json['nameJson']),
      descriptionJson: serializer.fromJson<String>(json['descriptionJson']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      geofenceRadius: serializer.fromJson<double>(json['geofenceRadius']),
      photoUrlsJson: serializer.fromJson<String>(json['photoUrlsJson']),
      audioUrlsJson: serializer.fromJson<String>(json['audioUrlsJson']),
      isPremium: serializer.fromJson<bool>(json['isPremium']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cityId': serializer.toJson<String>(cityId),
      'nameJson': serializer.toJson<String>(nameJson),
      'descriptionJson': serializer.toJson<String>(descriptionJson),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'geofenceRadius': serializer.toJson<double>(geofenceRadius),
      'photoUrlsJson': serializer.toJson<String>(photoUrlsJson),
      'audioUrlsJson': serializer.toJson<String>(audioUrlsJson),
      'isPremium': serializer.toJson<bool>(isPremium),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedPoi copyWith(
          {String? id,
          String? cityId,
          String? nameJson,
          String? descriptionJson,
          double? latitude,
          double? longitude,
          double? geofenceRadius,
          String? photoUrlsJson,
          String? audioUrlsJson,
          bool? isPremium,
          DateTime? cachedAt}) =>
      CachedPoi(
        id: id ?? this.id,
        cityId: cityId ?? this.cityId,
        nameJson: nameJson ?? this.nameJson,
        descriptionJson: descriptionJson ?? this.descriptionJson,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        geofenceRadius: geofenceRadius ?? this.geofenceRadius,
        photoUrlsJson: photoUrlsJson ?? this.photoUrlsJson,
        audioUrlsJson: audioUrlsJson ?? this.audioUrlsJson,
        isPremium: isPremium ?? this.isPremium,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedPoi copyWithCompanion(CachedPoisTableCompanion data) {
    return CachedPoi(
      id: data.id.present ? data.id.value : this.id,
      cityId: data.cityId.present ? data.cityId.value : this.cityId,
      nameJson: data.nameJson.present ? data.nameJson.value : this.nameJson,
      descriptionJson: data.descriptionJson.present
          ? data.descriptionJson.value
          : this.descriptionJson,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      geofenceRadius: data.geofenceRadius.present
          ? data.geofenceRadius.value
          : this.geofenceRadius,
      photoUrlsJson: data.photoUrlsJson.present
          ? data.photoUrlsJson.value
          : this.photoUrlsJson,
      audioUrlsJson: data.audioUrlsJson.present
          ? data.audioUrlsJson.value
          : this.audioUrlsJson,
      isPremium: data.isPremium.present ? data.isPremium.value : this.isPremium,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPoi(')
          ..write('id: $id, ')
          ..write('cityId: $cityId, ')
          ..write('nameJson: $nameJson, ')
          ..write('descriptionJson: $descriptionJson, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('geofenceRadius: $geofenceRadius, ')
          ..write('photoUrlsJson: $photoUrlsJson, ')
          ..write('audioUrlsJson: $audioUrlsJson, ')
          ..write('isPremium: $isPremium, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      cityId,
      nameJson,
      descriptionJson,
      latitude,
      longitude,
      geofenceRadius,
      photoUrlsJson,
      audioUrlsJson,
      isPremium,
      cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPoi &&
          other.id == this.id &&
          other.cityId == this.cityId &&
          other.nameJson == this.nameJson &&
          other.descriptionJson == this.descriptionJson &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.geofenceRadius == this.geofenceRadius &&
          other.photoUrlsJson == this.photoUrlsJson &&
          other.audioUrlsJson == this.audioUrlsJson &&
          other.isPremium == this.isPremium &&
          other.cachedAt == this.cachedAt);
}

class CachedPoisTableCompanion extends UpdateCompanion<CachedPoi> {
  final Value<String> id;
  final Value<String> cityId;
  final Value<String> nameJson;
  final Value<String> descriptionJson;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> geofenceRadius;
  final Value<String> photoUrlsJson;
  final Value<String> audioUrlsJson;
  final Value<bool> isPremium;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedPoisTableCompanion({
    this.id = const Value.absent(),
    this.cityId = const Value.absent(),
    this.nameJson = const Value.absent(),
    this.descriptionJson = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.geofenceRadius = const Value.absent(),
    this.photoUrlsJson = const Value.absent(),
    this.audioUrlsJson = const Value.absent(),
    this.isPremium = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPoisTableCompanion.insert({
    required String id,
    required String cityId,
    required String nameJson,
    required String descriptionJson,
    required double latitude,
    required double longitude,
    required double geofenceRadius,
    required String photoUrlsJson,
    required String audioUrlsJson,
    required bool isPremium,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        cityId = Value(cityId),
        nameJson = Value(nameJson),
        descriptionJson = Value(descriptionJson),
        latitude = Value(latitude),
        longitude = Value(longitude),
        geofenceRadius = Value(geofenceRadius),
        photoUrlsJson = Value(photoUrlsJson),
        audioUrlsJson = Value(audioUrlsJson),
        isPremium = Value(isPremium),
        cachedAt = Value(cachedAt);
  static Insertable<CachedPoi> custom({
    Expression<String>? id,
    Expression<String>? cityId,
    Expression<String>? nameJson,
    Expression<String>? descriptionJson,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? geofenceRadius,
    Expression<String>? photoUrlsJson,
    Expression<String>? audioUrlsJson,
    Expression<bool>? isPremium,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cityId != null) 'city_id': cityId,
      if (nameJson != null) 'name_json': nameJson,
      if (descriptionJson != null) 'description_json': descriptionJson,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (geofenceRadius != null) 'geofence_radius': geofenceRadius,
      if (photoUrlsJson != null) 'photo_urls_json': photoUrlsJson,
      if (audioUrlsJson != null) 'audio_urls_json': audioUrlsJson,
      if (isPremium != null) 'is_premium': isPremium,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPoisTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? cityId,
      Value<String>? nameJson,
      Value<String>? descriptionJson,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<double>? geofenceRadius,
      Value<String>? photoUrlsJson,
      Value<String>? audioUrlsJson,
      Value<bool>? isPremium,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return CachedPoisTableCompanion(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      nameJson: nameJson ?? this.nameJson,
      descriptionJson: descriptionJson ?? this.descriptionJson,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geofenceRadius: geofenceRadius ?? this.geofenceRadius,
      photoUrlsJson: photoUrlsJson ?? this.photoUrlsJson,
      audioUrlsJson: audioUrlsJson ?? this.audioUrlsJson,
      isPremium: isPremium ?? this.isPremium,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cityId.present) {
      map['city_id'] = Variable<String>(cityId.value);
    }
    if (nameJson.present) {
      map['name_json'] = Variable<String>(nameJson.value);
    }
    if (descriptionJson.present) {
      map['description_json'] = Variable<String>(descriptionJson.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (geofenceRadius.present) {
      map['geofence_radius'] = Variable<double>(geofenceRadius.value);
    }
    if (photoUrlsJson.present) {
      map['photo_urls_json'] = Variable<String>(photoUrlsJson.value);
    }
    if (audioUrlsJson.present) {
      map['audio_urls_json'] = Variable<String>(audioUrlsJson.value);
    }
    if (isPremium.present) {
      map['is_premium'] = Variable<bool>(isPremium.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPoisTableCompanion(')
          ..write('id: $id, ')
          ..write('cityId: $cityId, ')
          ..write('nameJson: $nameJson, ')
          ..write('descriptionJson: $descriptionJson, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('geofenceRadius: $geofenceRadius, ')
          ..write('photoUrlsJson: $photoUrlsJson, ')
          ..write('audioUrlsJson: $audioUrlsJson, ')
          ..write('isPremium: $isPremium, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FreeVisitsTableTable extends FreeVisitsTable
    with TableInfo<$FreeVisitsTableTable, FreeVisitsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FreeVisitsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _poiIdMeta = const VerificationMeta('poiId');
  @override
  late final GeneratedColumn<String> poiId = GeneratedColumn<String>(
      'poi_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _yearMonthMeta =
      const VerificationMeta('yearMonth');
  @override
  late final GeneratedColumn<String> yearMonth = GeneratedColumn<String>(
      'year_month', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _visitedAtMeta =
      const VerificationMeta('visitedAt');
  @override
  late final GeneratedColumn<DateTime> visitedAt = GeneratedColumn<DateTime>(
      'visited_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, poiId, yearMonth, visitedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'free_visits';
  @override
  VerificationContext validateIntegrity(
      Insertable<FreeVisitsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('poi_id')) {
      context.handle(
          _poiIdMeta, poiId.isAcceptableOrUnknown(data['poi_id']!, _poiIdMeta));
    } else if (isInserting) {
      context.missing(_poiIdMeta);
    }
    if (data.containsKey('year_month')) {
      context.handle(_yearMonthMeta,
          yearMonth.isAcceptableOrUnknown(data['year_month']!, _yearMonthMeta));
    } else if (isInserting) {
      context.missing(_yearMonthMeta);
    }
    if (data.containsKey('visited_at')) {
      context.handle(_visitedAtMeta,
          visitedAt.isAcceptableOrUnknown(data['visited_at']!, _visitedAtMeta));
    } else if (isInserting) {
      context.missing(_visitedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FreeVisitsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FreeVisitsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      poiId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poi_id'])!,
      yearMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}year_month'])!,
      visitedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}visited_at'])!,
    );
  }

  @override
  $FreeVisitsTableTable createAlias(String alias) {
    return $FreeVisitsTableTable(attachedDatabase, alias);
  }
}

class FreeVisitsTableData extends DataClass
    implements Insertable<FreeVisitsTableData> {
  final int id;
  final String poiId;
  final String yearMonth;
  final DateTime visitedAt;
  const FreeVisitsTableData(
      {required this.id,
      required this.poiId,
      required this.yearMonth,
      required this.visitedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['poi_id'] = Variable<String>(poiId);
    map['year_month'] = Variable<String>(yearMonth);
    map['visited_at'] = Variable<DateTime>(visitedAt);
    return map;
  }

  FreeVisitsTableCompanion toCompanion(bool nullToAbsent) {
    return FreeVisitsTableCompanion(
      id: Value(id),
      poiId: Value(poiId),
      yearMonth: Value(yearMonth),
      visitedAt: Value(visitedAt),
    );
  }

  factory FreeVisitsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FreeVisitsTableData(
      id: serializer.fromJson<int>(json['id']),
      poiId: serializer.fromJson<String>(json['poiId']),
      yearMonth: serializer.fromJson<String>(json['yearMonth']),
      visitedAt: serializer.fromJson<DateTime>(json['visitedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'poiId': serializer.toJson<String>(poiId),
      'yearMonth': serializer.toJson<String>(yearMonth),
      'visitedAt': serializer.toJson<DateTime>(visitedAt),
    };
  }

  FreeVisitsTableData copyWith(
          {int? id, String? poiId, String? yearMonth, DateTime? visitedAt}) =>
      FreeVisitsTableData(
        id: id ?? this.id,
        poiId: poiId ?? this.poiId,
        yearMonth: yearMonth ?? this.yearMonth,
        visitedAt: visitedAt ?? this.visitedAt,
      );
  FreeVisitsTableData copyWithCompanion(FreeVisitsTableCompanion data) {
    return FreeVisitsTableData(
      id: data.id.present ? data.id.value : this.id,
      poiId: data.poiId.present ? data.poiId.value : this.poiId,
      yearMonth: data.yearMonth.present ? data.yearMonth.value : this.yearMonth,
      visitedAt: data.visitedAt.present ? data.visitedAt.value : this.visitedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FreeVisitsTableData(')
          ..write('id: $id, ')
          ..write('poiId: $poiId, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('visitedAt: $visitedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, poiId, yearMonth, visitedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FreeVisitsTableData &&
          other.id == this.id &&
          other.poiId == this.poiId &&
          other.yearMonth == this.yearMonth &&
          other.visitedAt == this.visitedAt);
}

class FreeVisitsTableCompanion extends UpdateCompanion<FreeVisitsTableData> {
  final Value<int> id;
  final Value<String> poiId;
  final Value<String> yearMonth;
  final Value<DateTime> visitedAt;
  const FreeVisitsTableCompanion({
    this.id = const Value.absent(),
    this.poiId = const Value.absent(),
    this.yearMonth = const Value.absent(),
    this.visitedAt = const Value.absent(),
  });
  FreeVisitsTableCompanion.insert({
    this.id = const Value.absent(),
    required String poiId,
    required String yearMonth,
    required DateTime visitedAt,
  })  : poiId = Value(poiId),
        yearMonth = Value(yearMonth),
        visitedAt = Value(visitedAt);
  static Insertable<FreeVisitsTableData> custom({
    Expression<int>? id,
    Expression<String>? poiId,
    Expression<String>? yearMonth,
    Expression<DateTime>? visitedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (poiId != null) 'poi_id': poiId,
      if (yearMonth != null) 'year_month': yearMonth,
      if (visitedAt != null) 'visited_at': visitedAt,
    });
  }

  FreeVisitsTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? poiId,
      Value<String>? yearMonth,
      Value<DateTime>? visitedAt}) {
    return FreeVisitsTableCompanion(
      id: id ?? this.id,
      poiId: poiId ?? this.poiId,
      yearMonth: yearMonth ?? this.yearMonth,
      visitedAt: visitedAt ?? this.visitedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (poiId.present) {
      map['poi_id'] = Variable<String>(poiId.value);
    }
    if (yearMonth.present) {
      map['year_month'] = Variable<String>(yearMonth.value);
    }
    if (visitedAt.present) {
      map['visited_at'] = Variable<DateTime>(visitedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FreeVisitsTableCompanion(')
          ..write('id: $id, ')
          ..write('poiId: $poiId, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('visitedAt: $visitedAt')
          ..write(')'))
        .toString();
  }
}

class $RatedPoisTableTable extends RatedPoisTable
    with TableInfo<$RatedPoisTableTable, RatedPoi> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RatedPoisTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _poiIdMeta = const VerificationMeta('poiId');
  @override
  late final GeneratedColumn<String> poiId = GeneratedColumn<String>(
      'poi_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
      'rating', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _langCodeMeta =
      const VerificationMeta('langCode');
  @override
  late final GeneratedColumn<String> langCode = GeneratedColumn<String>(
      'lang_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cs'));
  static const VerificationMeta _ratedAtMeta =
      const VerificationMeta('ratedAt');
  @override
  late final GeneratedColumn<DateTime> ratedAt = GeneratedColumn<DateTime>(
      'rated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [localId, poiId, rating, reason, langCode, ratedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rated_pois';
  @override
  VerificationContext validateIntegrity(Insertable<RatedPoi> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('poi_id')) {
      context.handle(
          _poiIdMeta, poiId.isAcceptableOrUnknown(data['poi_id']!, _poiIdMeta));
    } else if (isInserting) {
      context.missing(_poiIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('lang_code')) {
      context.handle(_langCodeMeta,
          langCode.isAcceptableOrUnknown(data['lang_code']!, _langCodeMeta));
    }
    if (data.containsKey('rated_at')) {
      context.handle(_ratedAtMeta,
          ratedAt.isAcceptableOrUnknown(data['rated_at']!, _ratedAtMeta));
    } else if (isInserting) {
      context.missing(_ratedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {poiId},
      ];
  @override
  RatedPoi map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RatedPoi(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      poiId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poi_id'])!,
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rating'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason']),
      langCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lang_code'])!,
      ratedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}rated_at'])!,
    );
  }

  @override
  $RatedPoisTableTable createAlias(String alias) {
    return $RatedPoisTableTable(attachedDatabase, alias);
  }
}

class RatedPoi extends DataClass implements Insertable<RatedPoi> {
  final int localId;
  final String poiId;
  final int rating;
  final String? reason;
  final String langCode;
  final DateTime ratedAt;
  const RatedPoi(
      {required this.localId,
      required this.poiId,
      required this.rating,
      this.reason,
      required this.langCode,
      required this.ratedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['poi_id'] = Variable<String>(poiId);
    map['rating'] = Variable<int>(rating);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['lang_code'] = Variable<String>(langCode);
    map['rated_at'] = Variable<DateTime>(ratedAt);
    return map;
  }

  RatedPoisTableCompanion toCompanion(bool nullToAbsent) {
    return RatedPoisTableCompanion(
      localId: Value(localId),
      poiId: Value(poiId),
      rating: Value(rating),
      reason:
          reason == null && nullToAbsent ? const Value.absent() : Value(reason),
      langCode: Value(langCode),
      ratedAt: Value(ratedAt),
    );
  }

  factory RatedPoi.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RatedPoi(
      localId: serializer.fromJson<int>(json['localId']),
      poiId: serializer.fromJson<String>(json['poiId']),
      rating: serializer.fromJson<int>(json['rating']),
      reason: serializer.fromJson<String?>(json['reason']),
      langCode: serializer.fromJson<String>(json['langCode']),
      ratedAt: serializer.fromJson<DateTime>(json['ratedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'poiId': serializer.toJson<String>(poiId),
      'rating': serializer.toJson<int>(rating),
      'reason': serializer.toJson<String?>(reason),
      'langCode': serializer.toJson<String>(langCode),
      'ratedAt': serializer.toJson<DateTime>(ratedAt),
    };
  }

  RatedPoi copyWith(
          {int? localId,
          String? poiId,
          int? rating,
          Value<String?> reason = const Value.absent(),
          String? langCode,
          DateTime? ratedAt}) =>
      RatedPoi(
        localId: localId ?? this.localId,
        poiId: poiId ?? this.poiId,
        rating: rating ?? this.rating,
        reason: reason.present ? reason.value : this.reason,
        langCode: langCode ?? this.langCode,
        ratedAt: ratedAt ?? this.ratedAt,
      );
  RatedPoi copyWithCompanion(RatedPoisTableCompanion data) {
    return RatedPoi(
      localId: data.localId.present ? data.localId.value : this.localId,
      poiId: data.poiId.present ? data.poiId.value : this.poiId,
      rating: data.rating.present ? data.rating.value : this.rating,
      reason: data.reason.present ? data.reason.value : this.reason,
      langCode: data.langCode.present ? data.langCode.value : this.langCode,
      ratedAt: data.ratedAt.present ? data.ratedAt.value : this.ratedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RatedPoi(')
          ..write('localId: $localId, ')
          ..write('poiId: $poiId, ')
          ..write('rating: $rating, ')
          ..write('reason: $reason, ')
          ..write('langCode: $langCode, ')
          ..write('ratedAt: $ratedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(localId, poiId, rating, reason, langCode, ratedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RatedPoi &&
          other.localId == this.localId &&
          other.poiId == this.poiId &&
          other.rating == this.rating &&
          other.reason == this.reason &&
          other.langCode == this.langCode &&
          other.ratedAt == this.ratedAt);
}

class RatedPoisTableCompanion extends UpdateCompanion<RatedPoi> {
  final Value<int> localId;
  final Value<String> poiId;
  final Value<int> rating;
  final Value<String?> reason;
  final Value<String> langCode;
  final Value<DateTime> ratedAt;
  const RatedPoisTableCompanion({
    this.localId = const Value.absent(),
    this.poiId = const Value.absent(),
    this.rating = const Value.absent(),
    this.reason = const Value.absent(),
    this.langCode = const Value.absent(),
    this.ratedAt = const Value.absent(),
  });
  RatedPoisTableCompanion.insert({
    this.localId = const Value.absent(),
    required String poiId,
    required int rating,
    this.reason = const Value.absent(),
    this.langCode = const Value.absent(),
    required DateTime ratedAt,
  })  : poiId = Value(poiId),
        rating = Value(rating),
        ratedAt = Value(ratedAt);
  static Insertable<RatedPoi> custom({
    Expression<int>? localId,
    Expression<String>? poiId,
    Expression<int>? rating,
    Expression<String>? reason,
    Expression<String>? langCode,
    Expression<DateTime>? ratedAt,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (poiId != null) 'poi_id': poiId,
      if (rating != null) 'rating': rating,
      if (reason != null) 'reason': reason,
      if (langCode != null) 'lang_code': langCode,
      if (ratedAt != null) 'rated_at': ratedAt,
    });
  }

  RatedPoisTableCompanion copyWith(
      {Value<int>? localId,
      Value<String>? poiId,
      Value<int>? rating,
      Value<String?>? reason,
      Value<String>? langCode,
      Value<DateTime>? ratedAt}) {
    return RatedPoisTableCompanion(
      localId: localId ?? this.localId,
      poiId: poiId ?? this.poiId,
      rating: rating ?? this.rating,
      reason: reason ?? this.reason,
      langCode: langCode ?? this.langCode,
      ratedAt: ratedAt ?? this.ratedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (poiId.present) {
      map['poi_id'] = Variable<String>(poiId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (langCode.present) {
      map['lang_code'] = Variable<String>(langCode.value);
    }
    if (ratedAt.present) {
      map['rated_at'] = Variable<DateTime>(ratedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RatedPoisTableCompanion(')
          ..write('localId: $localId, ')
          ..write('poiId: $poiId, ')
          ..write('rating: $rating, ')
          ..write('reason: $reason, ')
          ..write('langCode: $langCode, ')
          ..write('ratedAt: $ratedAt')
          ..write(')'))
        .toString();
  }
}

class $PurchasedPoisTableTable extends PurchasedPoisTable
    with TableInfo<$PurchasedPoisTableTable, PurchasedPoi> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchasedPoisTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _poiIdMeta = const VerificationMeta('poiId');
  @override
  late final GeneratedColumn<String> poiId = GeneratedColumn<String>(
      'poi_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stripeSessionIdMeta =
      const VerificationMeta('stripeSessionId');
  @override
  late final GeneratedColumn<String> stripeSessionId = GeneratedColumn<String>(
      'stripe_session_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pricePaidMeta =
      const VerificationMeta('pricePaid');
  @override
  late final GeneratedColumn<double> pricePaid = GeneratedColumn<double>(
      'price_paid', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _purchasedAtMeta =
      const VerificationMeta('purchasedAt');
  @override
  late final GeneratedColumn<DateTime> purchasedAt = GeneratedColumn<DateTime>(
      'purchased_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [poiId, stripeSessionId, pricePaid, purchasedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchased_pois';
  @override
  VerificationContext validateIntegrity(Insertable<PurchasedPoi> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('poi_id')) {
      context.handle(
          _poiIdMeta, poiId.isAcceptableOrUnknown(data['poi_id']!, _poiIdMeta));
    } else if (isInserting) {
      context.missing(_poiIdMeta);
    }
    if (data.containsKey('stripe_session_id')) {
      context.handle(
          _stripeSessionIdMeta,
          stripeSessionId.isAcceptableOrUnknown(
              data['stripe_session_id']!, _stripeSessionIdMeta));
    }
    if (data.containsKey('price_paid')) {
      context.handle(_pricePaidMeta,
          pricePaid.isAcceptableOrUnknown(data['price_paid']!, _pricePaidMeta));
    } else if (isInserting) {
      context.missing(_pricePaidMeta);
    }
    if (data.containsKey('purchased_at')) {
      context.handle(
          _purchasedAtMeta,
          purchasedAt.isAcceptableOrUnknown(
              data['purchased_at']!, _purchasedAtMeta));
    } else if (isInserting) {
      context.missing(_purchasedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {poiId};
  @override
  PurchasedPoi map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchasedPoi(
      poiId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poi_id'])!,
      stripeSessionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}stripe_session_id']),
      pricePaid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price_paid'])!,
      purchasedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}purchased_at'])!,
    );
  }

  @override
  $PurchasedPoisTableTable createAlias(String alias) {
    return $PurchasedPoisTableTable(attachedDatabase, alias);
  }
}

class PurchasedPoi extends DataClass implements Insertable<PurchasedPoi> {
  final String poiId;
  final String? stripeSessionId;
  final double pricePaid;
  final DateTime purchasedAt;
  const PurchasedPoi(
      {required this.poiId,
      this.stripeSessionId,
      required this.pricePaid,
      required this.purchasedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['poi_id'] = Variable<String>(poiId);
    if (!nullToAbsent || stripeSessionId != null) {
      map['stripe_session_id'] = Variable<String>(stripeSessionId);
    }
    map['price_paid'] = Variable<double>(pricePaid);
    map['purchased_at'] = Variable<DateTime>(purchasedAt);
    return map;
  }

  PurchasedPoisTableCompanion toCompanion(bool nullToAbsent) {
    return PurchasedPoisTableCompanion(
      poiId: Value(poiId),
      stripeSessionId: stripeSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(stripeSessionId),
      pricePaid: Value(pricePaid),
      purchasedAt: Value(purchasedAt),
    );
  }

  factory PurchasedPoi.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchasedPoi(
      poiId: serializer.fromJson<String>(json['poiId']),
      stripeSessionId: serializer.fromJson<String?>(json['stripeSessionId']),
      pricePaid: serializer.fromJson<double>(json['pricePaid']),
      purchasedAt: serializer.fromJson<DateTime>(json['purchasedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'poiId': serializer.toJson<String>(poiId),
      'stripeSessionId': serializer.toJson<String?>(stripeSessionId),
      'pricePaid': serializer.toJson<double>(pricePaid),
      'purchasedAt': serializer.toJson<DateTime>(purchasedAt),
    };
  }

  PurchasedPoi copyWith(
          {String? poiId,
          Value<String?> stripeSessionId = const Value.absent(),
          double? pricePaid,
          DateTime? purchasedAt}) =>
      PurchasedPoi(
        poiId: poiId ?? this.poiId,
        stripeSessionId: stripeSessionId.present
            ? stripeSessionId.value
            : this.stripeSessionId,
        pricePaid: pricePaid ?? this.pricePaid,
        purchasedAt: purchasedAt ?? this.purchasedAt,
      );
  PurchasedPoi copyWithCompanion(PurchasedPoisTableCompanion data) {
    return PurchasedPoi(
      poiId: data.poiId.present ? data.poiId.value : this.poiId,
      stripeSessionId: data.stripeSessionId.present
          ? data.stripeSessionId.value
          : this.stripeSessionId,
      pricePaid: data.pricePaid.present ? data.pricePaid.value : this.pricePaid,
      purchasedAt:
          data.purchasedAt.present ? data.purchasedAt.value : this.purchasedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchasedPoi(')
          ..write('poiId: $poiId, ')
          ..write('stripeSessionId: $stripeSessionId, ')
          ..write('pricePaid: $pricePaid, ')
          ..write('purchasedAt: $purchasedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(poiId, stripeSessionId, pricePaid, purchasedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchasedPoi &&
          other.poiId == this.poiId &&
          other.stripeSessionId == this.stripeSessionId &&
          other.pricePaid == this.pricePaid &&
          other.purchasedAt == this.purchasedAt);
}

class PurchasedPoisTableCompanion extends UpdateCompanion<PurchasedPoi> {
  final Value<String> poiId;
  final Value<String?> stripeSessionId;
  final Value<double> pricePaid;
  final Value<DateTime> purchasedAt;
  final Value<int> rowid;
  const PurchasedPoisTableCompanion({
    this.poiId = const Value.absent(),
    this.stripeSessionId = const Value.absent(),
    this.pricePaid = const Value.absent(),
    this.purchasedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchasedPoisTableCompanion.insert({
    required String poiId,
    this.stripeSessionId = const Value.absent(),
    required double pricePaid,
    required DateTime purchasedAt,
    this.rowid = const Value.absent(),
  })  : poiId = Value(poiId),
        pricePaid = Value(pricePaid),
        purchasedAt = Value(purchasedAt);
  static Insertable<PurchasedPoi> custom({
    Expression<String>? poiId,
    Expression<String>? stripeSessionId,
    Expression<double>? pricePaid,
    Expression<DateTime>? purchasedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (poiId != null) 'poi_id': poiId,
      if (stripeSessionId != null) 'stripe_session_id': stripeSessionId,
      if (pricePaid != null) 'price_paid': pricePaid,
      if (purchasedAt != null) 'purchased_at': purchasedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchasedPoisTableCompanion copyWith(
      {Value<String>? poiId,
      Value<String?>? stripeSessionId,
      Value<double>? pricePaid,
      Value<DateTime>? purchasedAt,
      Value<int>? rowid}) {
    return PurchasedPoisTableCompanion(
      poiId: poiId ?? this.poiId,
      stripeSessionId: stripeSessionId ?? this.stripeSessionId,
      pricePaid: pricePaid ?? this.pricePaid,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (poiId.present) {
      map['poi_id'] = Variable<String>(poiId.value);
    }
    if (stripeSessionId.present) {
      map['stripe_session_id'] = Variable<String>(stripeSessionId.value);
    }
    if (pricePaid.present) {
      map['price_paid'] = Variable<double>(pricePaid.value);
    }
    if (purchasedAt.present) {
      map['purchased_at'] = Variable<DateTime>(purchasedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchasedPoisTableCompanion(')
          ..write('poiId: $poiId, ')
          ..write('stripeSessionId: $stripeSessionId, ')
          ..write('pricePaid: $pricePaid, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchasedCityBundlesTableTable extends PurchasedCityBundlesTable
    with TableInfo<$PurchasedCityBundlesTableTable, PurchasedCityBundle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchasedCityBundlesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cityIdMeta = const VerificationMeta('cityId');
  @override
  late final GeneratedColumn<String> cityId = GeneratedColumn<String>(
      'city_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stripeSessionIdMeta =
      const VerificationMeta('stripeSessionId');
  @override
  late final GeneratedColumn<String> stripeSessionId = GeneratedColumn<String>(
      'stripe_session_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pricePaidMeta =
      const VerificationMeta('pricePaid');
  @override
  late final GeneratedColumn<double> pricePaid = GeneratedColumn<double>(
      'price_paid', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _purchasedAtMeta =
      const VerificationMeta('purchasedAt');
  @override
  late final GeneratedColumn<DateTime> purchasedAt = GeneratedColumn<DateTime>(
      'purchased_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [cityId, stripeSessionId, pricePaid, purchasedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchased_city_bundles';
  @override
  VerificationContext validateIntegrity(
      Insertable<PurchasedCityBundle> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('city_id')) {
      context.handle(_cityIdMeta,
          cityId.isAcceptableOrUnknown(data['city_id']!, _cityIdMeta));
    } else if (isInserting) {
      context.missing(_cityIdMeta);
    }
    if (data.containsKey('stripe_session_id')) {
      context.handle(
          _stripeSessionIdMeta,
          stripeSessionId.isAcceptableOrUnknown(
              data['stripe_session_id']!, _stripeSessionIdMeta));
    }
    if (data.containsKey('price_paid')) {
      context.handle(_pricePaidMeta,
          pricePaid.isAcceptableOrUnknown(data['price_paid']!, _pricePaidMeta));
    } else if (isInserting) {
      context.missing(_pricePaidMeta);
    }
    if (data.containsKey('purchased_at')) {
      context.handle(
          _purchasedAtMeta,
          purchasedAt.isAcceptableOrUnknown(
              data['purchased_at']!, _purchasedAtMeta));
    } else if (isInserting) {
      context.missing(_purchasedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cityId};
  @override
  PurchasedCityBundle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchasedCityBundle(
      cityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}city_id'])!,
      stripeSessionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}stripe_session_id']),
      pricePaid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price_paid'])!,
      purchasedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}purchased_at'])!,
    );
  }

  @override
  $PurchasedCityBundlesTableTable createAlias(String alias) {
    return $PurchasedCityBundlesTableTable(attachedDatabase, alias);
  }
}

class PurchasedCityBundle extends DataClass
    implements Insertable<PurchasedCityBundle> {
  final String cityId;
  final String? stripeSessionId;
  final double pricePaid;
  final DateTime purchasedAt;
  const PurchasedCityBundle(
      {required this.cityId,
      this.stripeSessionId,
      required this.pricePaid,
      required this.purchasedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['city_id'] = Variable<String>(cityId);
    if (!nullToAbsent || stripeSessionId != null) {
      map['stripe_session_id'] = Variable<String>(stripeSessionId);
    }
    map['price_paid'] = Variable<double>(pricePaid);
    map['purchased_at'] = Variable<DateTime>(purchasedAt);
    return map;
  }

  PurchasedCityBundlesTableCompanion toCompanion(bool nullToAbsent) {
    return PurchasedCityBundlesTableCompanion(
      cityId: Value(cityId),
      stripeSessionId: stripeSessionId == null && nullToAbsent
          ? const Value.absent()
          : Value(stripeSessionId),
      pricePaid: Value(pricePaid),
      purchasedAt: Value(purchasedAt),
    );
  }

  factory PurchasedCityBundle.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchasedCityBundle(
      cityId: serializer.fromJson<String>(json['cityId']),
      stripeSessionId: serializer.fromJson<String?>(json['stripeSessionId']),
      pricePaid: serializer.fromJson<double>(json['pricePaid']),
      purchasedAt: serializer.fromJson<DateTime>(json['purchasedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cityId': serializer.toJson<String>(cityId),
      'stripeSessionId': serializer.toJson<String?>(stripeSessionId),
      'pricePaid': serializer.toJson<double>(pricePaid),
      'purchasedAt': serializer.toJson<DateTime>(purchasedAt),
    };
  }

  PurchasedCityBundle copyWith(
          {String? cityId,
          Value<String?> stripeSessionId = const Value.absent(),
          double? pricePaid,
          DateTime? purchasedAt}) =>
      PurchasedCityBundle(
        cityId: cityId ?? this.cityId,
        stripeSessionId: stripeSessionId.present
            ? stripeSessionId.value
            : this.stripeSessionId,
        pricePaid: pricePaid ?? this.pricePaid,
        purchasedAt: purchasedAt ?? this.purchasedAt,
      );
  PurchasedCityBundle copyWithCompanion(
      PurchasedCityBundlesTableCompanion data) {
    return PurchasedCityBundle(
      cityId: data.cityId.present ? data.cityId.value : this.cityId,
      stripeSessionId: data.stripeSessionId.present
          ? data.stripeSessionId.value
          : this.stripeSessionId,
      pricePaid: data.pricePaid.present ? data.pricePaid.value : this.pricePaid,
      purchasedAt:
          data.purchasedAt.present ? data.purchasedAt.value : this.purchasedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchasedCityBundle(')
          ..write('cityId: $cityId, ')
          ..write('stripeSessionId: $stripeSessionId, ')
          ..write('pricePaid: $pricePaid, ')
          ..write('purchasedAt: $purchasedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(cityId, stripeSessionId, pricePaid, purchasedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchasedCityBundle &&
          other.cityId == this.cityId &&
          other.stripeSessionId == this.stripeSessionId &&
          other.pricePaid == this.pricePaid &&
          other.purchasedAt == this.purchasedAt);
}

class PurchasedCityBundlesTableCompanion
    extends UpdateCompanion<PurchasedCityBundle> {
  final Value<String> cityId;
  final Value<String?> stripeSessionId;
  final Value<double> pricePaid;
  final Value<DateTime> purchasedAt;
  final Value<int> rowid;
  const PurchasedCityBundlesTableCompanion({
    this.cityId = const Value.absent(),
    this.stripeSessionId = const Value.absent(),
    this.pricePaid = const Value.absent(),
    this.purchasedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchasedCityBundlesTableCompanion.insert({
    required String cityId,
    this.stripeSessionId = const Value.absent(),
    required double pricePaid,
    required DateTime purchasedAt,
    this.rowid = const Value.absent(),
  })  : cityId = Value(cityId),
        pricePaid = Value(pricePaid),
        purchasedAt = Value(purchasedAt);
  static Insertable<PurchasedCityBundle> custom({
    Expression<String>? cityId,
    Expression<String>? stripeSessionId,
    Expression<double>? pricePaid,
    Expression<DateTime>? purchasedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cityId != null) 'city_id': cityId,
      if (stripeSessionId != null) 'stripe_session_id': stripeSessionId,
      if (pricePaid != null) 'price_paid': pricePaid,
      if (purchasedAt != null) 'purchased_at': purchasedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchasedCityBundlesTableCompanion copyWith(
      {Value<String>? cityId,
      Value<String?>? stripeSessionId,
      Value<double>? pricePaid,
      Value<DateTime>? purchasedAt,
      Value<int>? rowid}) {
    return PurchasedCityBundlesTableCompanion(
      cityId: cityId ?? this.cityId,
      stripeSessionId: stripeSessionId ?? this.stripeSessionId,
      pricePaid: pricePaid ?? this.pricePaid,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cityId.present) {
      map['city_id'] = Variable<String>(cityId.value);
    }
    if (stripeSessionId.present) {
      map['stripe_session_id'] = Variable<String>(stripeSessionId.value);
    }
    if (pricePaid.present) {
      map['price_paid'] = Variable<double>(pricePaid.value);
    }
    if (purchasedAt.present) {
      map['purchased_at'] = Variable<DateTime>(purchasedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchasedCityBundlesTableCompanion(')
          ..write('cityId: $cityId, ')
          ..write('stripeSessionId: $stripeSessionId, ')
          ..write('pricePaid: $pricePaid, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedAudioGuidesTableTable extends CachedAudioGuidesTable
    with TableInfo<$CachedAudioGuidesTableTable, CachedAudioGuide> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAudioGuidesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _poiIdMeta = const VerificationMeta('poiId');
  @override
  late final GeneratedColumn<String> poiId = GeneratedColumn<String>(
      'poi_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _langCodeMeta =
      const VerificationMeta('langCode');
  @override
  late final GeneratedColumn<String> langCode = GeneratedColumn<String>(
      'lang_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _durationSecMeta =
      const VerificationMeta('durationSec');
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
      'duration_sec', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, poiId, langCode, title, url, durationSec, sortOrder, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_audio_guides';
  @override
  VerificationContext validateIntegrity(Insertable<CachedAudioGuide> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('poi_id')) {
      context.handle(
          _poiIdMeta, poiId.isAcceptableOrUnknown(data['poi_id']!, _poiIdMeta));
    } else if (isInserting) {
      context.missing(_poiIdMeta);
    }
    if (data.containsKey('lang_code')) {
      context.handle(_langCodeMeta,
          langCode.isAcceptableOrUnknown(data['lang_code']!, _langCodeMeta));
    } else if (isInserting) {
      context.missing(_langCodeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
          _durationSecMeta,
          durationSec.isAcceptableOrUnknown(
              data['duration_sec']!, _durationSecMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedAudioGuide map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAudioGuide(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      poiId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}poi_id'])!,
      langCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lang_code'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      durationSec: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_sec']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CachedAudioGuidesTableTable createAlias(String alias) {
    return $CachedAudioGuidesTableTable(attachedDatabase, alias);
  }
}

class CachedAudioGuide extends DataClass
    implements Insertable<CachedAudioGuide> {
  final String id;
  final String poiId;
  final String langCode;
  final String title;
  final String url;
  final int? durationSec;
  final int sortOrder;
  final DateTime cachedAt;
  const CachedAudioGuide(
      {required this.id,
      required this.poiId,
      required this.langCode,
      required this.title,
      required this.url,
      this.durationSec,
      required this.sortOrder,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['poi_id'] = Variable<String>(poiId);
    map['lang_code'] = Variable<String>(langCode);
    map['title'] = Variable<String>(title);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedAudioGuidesTableCompanion toCompanion(bool nullToAbsent) {
    return CachedAudioGuidesTableCompanion(
      id: Value(id),
      poiId: Value(poiId),
      langCode: Value(langCode),
      title: Value(title),
      url: Value(url),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      sortOrder: Value(sortOrder),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedAudioGuide.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAudioGuide(
      id: serializer.fromJson<String>(json['id']),
      poiId: serializer.fromJson<String>(json['poiId']),
      langCode: serializer.fromJson<String>(json['langCode']),
      title: serializer.fromJson<String>(json['title']),
      url: serializer.fromJson<String>(json['url']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'poiId': serializer.toJson<String>(poiId),
      'langCode': serializer.toJson<String>(langCode),
      'title': serializer.toJson<String>(title),
      'url': serializer.toJson<String>(url),
      'durationSec': serializer.toJson<int?>(durationSec),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedAudioGuide copyWith(
          {String? id,
          String? poiId,
          String? langCode,
          String? title,
          String? url,
          Value<int?> durationSec = const Value.absent(),
          int? sortOrder,
          DateTime? cachedAt}) =>
      CachedAudioGuide(
        id: id ?? this.id,
        poiId: poiId ?? this.poiId,
        langCode: langCode ?? this.langCode,
        title: title ?? this.title,
        url: url ?? this.url,
        durationSec: durationSec.present ? durationSec.value : this.durationSec,
        sortOrder: sortOrder ?? this.sortOrder,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedAudioGuide copyWithCompanion(CachedAudioGuidesTableCompanion data) {
    return CachedAudioGuide(
      id: data.id.present ? data.id.value : this.id,
      poiId: data.poiId.present ? data.poiId.value : this.poiId,
      langCode: data.langCode.present ? data.langCode.value : this.langCode,
      title: data.title.present ? data.title.value : this.title,
      url: data.url.present ? data.url.value : this.url,
      durationSec:
          data.durationSec.present ? data.durationSec.value : this.durationSec,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAudioGuide(')
          ..write('id: $id, ')
          ..write('poiId: $poiId, ')
          ..write('langCode: $langCode, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('durationSec: $durationSec, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, poiId, langCode, title, url, durationSec, sortOrder, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAudioGuide &&
          other.id == this.id &&
          other.poiId == this.poiId &&
          other.langCode == this.langCode &&
          other.title == this.title &&
          other.url == this.url &&
          other.durationSec == this.durationSec &&
          other.sortOrder == this.sortOrder &&
          other.cachedAt == this.cachedAt);
}

class CachedAudioGuidesTableCompanion
    extends UpdateCompanion<CachedAudioGuide> {
  final Value<String> id;
  final Value<String> poiId;
  final Value<String> langCode;
  final Value<String> title;
  final Value<String> url;
  final Value<int?> durationSec;
  final Value<int> sortOrder;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedAudioGuidesTableCompanion({
    this.id = const Value.absent(),
    this.poiId = const Value.absent(),
    this.langCode = const Value.absent(),
    this.title = const Value.absent(),
    this.url = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAudioGuidesTableCompanion.insert({
    required String id,
    required String poiId,
    required String langCode,
    this.title = const Value.absent(),
    required String url,
    this.durationSec = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        poiId = Value(poiId),
        langCode = Value(langCode),
        url = Value(url);
  static Insertable<CachedAudioGuide> custom({
    Expression<String>? id,
    Expression<String>? poiId,
    Expression<String>? langCode,
    Expression<String>? title,
    Expression<String>? url,
    Expression<int>? durationSec,
    Expression<int>? sortOrder,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (poiId != null) 'poi_id': poiId,
      if (langCode != null) 'lang_code': langCode,
      if (title != null) 'title': title,
      if (url != null) 'url': url,
      if (durationSec != null) 'duration_sec': durationSec,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAudioGuidesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? poiId,
      Value<String>? langCode,
      Value<String>? title,
      Value<String>? url,
      Value<int?>? durationSec,
      Value<int>? sortOrder,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return CachedAudioGuidesTableCompanion(
      id: id ?? this.id,
      poiId: poiId ?? this.poiId,
      langCode: langCode ?? this.langCode,
      title: title ?? this.title,
      url: url ?? this.url,
      durationSec: durationSec ?? this.durationSec,
      sortOrder: sortOrder ?? this.sortOrder,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (poiId.present) {
      map['poi_id'] = Variable<String>(poiId.value);
    }
    if (langCode.present) {
      map['lang_code'] = Variable<String>(langCode.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAudioGuidesTableCompanion(')
          ..write('id: $id, ')
          ..write('poiId: $poiId, ')
          ..write('langCode: $langCode, ')
          ..write('title: $title, ')
          ..write('url: $url, ')
          ..write('durationSec: $durationSec, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VisitedPoisTableTable visitedPoisTable =
      $VisitedPoisTableTable(this);
  late final $CachedPoisTableTable cachedPoisTable =
      $CachedPoisTableTable(this);
  late final $FreeVisitsTableTable freeVisitsTable =
      $FreeVisitsTableTable(this);
  late final $RatedPoisTableTable ratedPoisTable = $RatedPoisTableTable(this);
  late final $PurchasedPoisTableTable purchasedPoisTable =
      $PurchasedPoisTableTable(this);
  late final $PurchasedCityBundlesTableTable purchasedCityBundlesTable =
      $PurchasedCityBundlesTableTable(this);
  late final $CachedAudioGuidesTableTable cachedAudioGuidesTable =
      $CachedAudioGuidesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        visitedPoisTable,
        cachedPoisTable,
        freeVisitsTable,
        ratedPoisTable,
        purchasedPoisTable,
        purchasedCityBundlesTable,
        cachedAudioGuidesTable
      ];
}

typedef $$VisitedPoisTableTableCreateCompanionBuilder
    = VisitedPoisTableCompanion Function({
  Value<int> localId,
  required String poiId,
  required String cityId,
  required String poiName,
  required double latitude,
  required double longitude,
  required DateTime visitedAt,
  Value<String?> userNote,
  Value<String?> userPhotoPath,
  Value<bool> isSynced,
  Value<bool> exportedToPdf,
});
typedef $$VisitedPoisTableTableUpdateCompanionBuilder
    = VisitedPoisTableCompanion Function({
  Value<int> localId,
  Value<String> poiId,
  Value<String> cityId,
  Value<String> poiName,
  Value<double> latitude,
  Value<double> longitude,
  Value<DateTime> visitedAt,
  Value<String?> userNote,
  Value<String?> userPhotoPath,
  Value<bool> isSynced,
  Value<bool> exportedToPdf,
});

class $$VisitedPoisTableTableFilterComposer
    extends Composer<_$AppDatabase, $VisitedPoisTableTable> {
  $$VisitedPoisTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get poiId => $composableBuilder(
      column: $table.poiId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cityId => $composableBuilder(
      column: $table.cityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get poiName => $composableBuilder(
      column: $table.poiName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get visitedAt => $composableBuilder(
      column: $table.visitedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userNote => $composableBuilder(
      column: $table.userNote, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userPhotoPath => $composableBuilder(
      column: $table.userPhotoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get exportedToPdf => $composableBuilder(
      column: $table.exportedToPdf, builder: (column) => ColumnFilters(column));
}

class $$VisitedPoisTableTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitedPoisTableTable> {
  $$VisitedPoisTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get poiId => $composableBuilder(
      column: $table.poiId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cityId => $composableBuilder(
      column: $table.cityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get poiName => $composableBuilder(
      column: $table.poiName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get visitedAt => $composableBuilder(
      column: $table.visitedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userNote => $composableBuilder(
      column: $table.userNote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userPhotoPath => $composableBuilder(
      column: $table.userPhotoPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get exportedToPdf => $composableBuilder(
      column: $table.exportedToPdf,
      builder: (column) => ColumnOrderings(column));
}

class $$VisitedPoisTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitedPoisTableTable> {
  $$VisitedPoisTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get poiId =>
      $composableBuilder(column: $table.poiId, builder: (column) => column);

  GeneratedColumn<String> get cityId =>
      $composableBuilder(column: $table.cityId, builder: (column) => column);

  GeneratedColumn<String> get poiName =>
      $composableBuilder(column: $table.poiName, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get visitedAt =>
      $composableBuilder(column: $table.visitedAt, builder: (column) => column);

  GeneratedColumn<String> get userNote =>
      $composableBuilder(column: $table.userNote, builder: (column) => column);

  GeneratedColumn<String> get userPhotoPath => $composableBuilder(
      column: $table.userPhotoPath, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get exportedToPdf => $composableBuilder(
      column: $table.exportedToPdf, builder: (column) => column);
}

class $$VisitedPoisTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VisitedPoisTableTable,
    VisitedPoi,
    $$VisitedPoisTableTableFilterComposer,
    $$VisitedPoisTableTableOrderingComposer,
    $$VisitedPoisTableTableAnnotationComposer,
    $$VisitedPoisTableTableCreateCompanionBuilder,
    $$VisitedPoisTableTableUpdateCompanionBuilder,
    (
      VisitedPoi,
      BaseReferences<_$AppDatabase, $VisitedPoisTableTable, VisitedPoi>
    ),
    VisitedPoi,
    PrefetchHooks Function()> {
  $$VisitedPoisTableTableTableManager(
      _$AppDatabase db, $VisitedPoisTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitedPoisTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitedPoisTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitedPoisTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> poiId = const Value.absent(),
            Value<String> cityId = const Value.absent(),
            Value<String> poiName = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<DateTime> visitedAt = const Value.absent(),
            Value<String?> userNote = const Value.absent(),
            Value<String?> userPhotoPath = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<bool> exportedToPdf = const Value.absent(),
          }) =>
              VisitedPoisTableCompanion(
            localId: localId,
            poiId: poiId,
            cityId: cityId,
            poiName: poiName,
            latitude: latitude,
            longitude: longitude,
            visitedAt: visitedAt,
            userNote: userNote,
            userPhotoPath: userPhotoPath,
            isSynced: isSynced,
            exportedToPdf: exportedToPdf,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            required String poiId,
            required String cityId,
            required String poiName,
            required double latitude,
            required double longitude,
            required DateTime visitedAt,
            Value<String?> userNote = const Value.absent(),
            Value<String?> userPhotoPath = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<bool> exportedToPdf = const Value.absent(),
          }) =>
              VisitedPoisTableCompanion.insert(
            localId: localId,
            poiId: poiId,
            cityId: cityId,
            poiName: poiName,
            latitude: latitude,
            longitude: longitude,
            visitedAt: visitedAt,
            userNote: userNote,
            userPhotoPath: userPhotoPath,
            isSynced: isSynced,
            exportedToPdf: exportedToPdf,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VisitedPoisTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VisitedPoisTableTable,
    VisitedPoi,
    $$VisitedPoisTableTableFilterComposer,
    $$VisitedPoisTableTableOrderingComposer,
    $$VisitedPoisTableTableAnnotationComposer,
    $$VisitedPoisTableTableCreateCompanionBuilder,
    $$VisitedPoisTableTableUpdateCompanionBuilder,
    (
      VisitedPoi,
      BaseReferences<_$AppDatabase, $VisitedPoisTableTable, VisitedPoi>
    ),
    VisitedPoi,
    PrefetchHooks Function()>;
typedef $$CachedPoisTableTableCreateCompanionBuilder = CachedPoisTableCompanion
    Function({
  required String id,
  required String cityId,
  required String nameJson,
  required String descriptionJson,
  required double latitude,
  required double longitude,
  required double geofenceRadius,
  required String photoUrlsJson,
  required String audioUrlsJson,
  required bool isPremium,
  required DateTime cachedAt,
  Value<int> rowid,
});
typedef $$CachedPoisTableTableUpdateCompanionBuilder = CachedPoisTableCompanion
    Function({
  Value<String> id,
  Value<String> cityId,
  Value<String> nameJson,
  Value<String> descriptionJson,
  Value<double> latitude,
  Value<double> longitude,
  Value<double> geofenceRadius,
  Value<String> photoUrlsJson,
  Value<String> audioUrlsJson,
  Value<bool> isPremium,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$CachedPoisTableTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPoisTableTable> {
  $$CachedPoisTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cityId => $composableBuilder(
      column: $table.cityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nameJson => $composableBuilder(
      column: $table.nameJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get descriptionJson => $composableBuilder(
      column: $table.descriptionJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get geofenceRadius => $composableBuilder(
      column: $table.geofenceRadius,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoUrlsJson => $composableBuilder(
      column: $table.photoUrlsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioUrlsJson => $composableBuilder(
      column: $table.audioUrlsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPremium => $composableBuilder(
      column: $table.isPremium, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedPoisTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPoisTableTable> {
  $$CachedPoisTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cityId => $composableBuilder(
      column: $table.cityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nameJson => $composableBuilder(
      column: $table.nameJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get descriptionJson => $composableBuilder(
      column: $table.descriptionJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get geofenceRadius => $composableBuilder(
      column: $table.geofenceRadius,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoUrlsJson => $composableBuilder(
      column: $table.photoUrlsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioUrlsJson => $composableBuilder(
      column: $table.audioUrlsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPremium => $composableBuilder(
      column: $table.isPremium, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedPoisTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPoisTableTable> {
  $$CachedPoisTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cityId =>
      $composableBuilder(column: $table.cityId, builder: (column) => column);

  GeneratedColumn<String> get nameJson =>
      $composableBuilder(column: $table.nameJson, builder: (column) => column);

  GeneratedColumn<String> get descriptionJson => $composableBuilder(
      column: $table.descriptionJson, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get geofenceRadius => $composableBuilder(
      column: $table.geofenceRadius, builder: (column) => column);

  GeneratedColumn<String> get photoUrlsJson => $composableBuilder(
      column: $table.photoUrlsJson, builder: (column) => column);

  GeneratedColumn<String> get audioUrlsJson => $composableBuilder(
      column: $table.audioUrlsJson, builder: (column) => column);

  GeneratedColumn<bool> get isPremium =>
      $composableBuilder(column: $table.isPremium, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedPoisTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedPoisTableTable,
    CachedPoi,
    $$CachedPoisTableTableFilterComposer,
    $$CachedPoisTableTableOrderingComposer,
    $$CachedPoisTableTableAnnotationComposer,
    $$CachedPoisTableTableCreateCompanionBuilder,
    $$CachedPoisTableTableUpdateCompanionBuilder,
    (
      CachedPoi,
      BaseReferences<_$AppDatabase, $CachedPoisTableTable, CachedPoi>
    ),
    CachedPoi,
    PrefetchHooks Function()> {
  $$CachedPoisTableTableTableManager(
      _$AppDatabase db, $CachedPoisTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPoisTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPoisTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPoisTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> cityId = const Value.absent(),
            Value<String> nameJson = const Value.absent(),
            Value<String> descriptionJson = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<double> geofenceRadius = const Value.absent(),
            Value<String> photoUrlsJson = const Value.absent(),
            Value<String> audioUrlsJson = const Value.absent(),
            Value<bool> isPremium = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedPoisTableCompanion(
            id: id,
            cityId: cityId,
            nameJson: nameJson,
            descriptionJson: descriptionJson,
            latitude: latitude,
            longitude: longitude,
            geofenceRadius: geofenceRadius,
            photoUrlsJson: photoUrlsJson,
            audioUrlsJson: audioUrlsJson,
            isPremium: isPremium,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String cityId,
            required String nameJson,
            required String descriptionJson,
            required double latitude,
            required double longitude,
            required double geofenceRadius,
            required String photoUrlsJson,
            required String audioUrlsJson,
            required bool isPremium,
            required DateTime cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedPoisTableCompanion.insert(
            id: id,
            cityId: cityId,
            nameJson: nameJson,
            descriptionJson: descriptionJson,
            latitude: latitude,
            longitude: longitude,
            geofenceRadius: geofenceRadius,
            photoUrlsJson: photoUrlsJson,
            audioUrlsJson: audioUrlsJson,
            isPremium: isPremium,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedPoisTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedPoisTableTable,
    CachedPoi,
    $$CachedPoisTableTableFilterComposer,
    $$CachedPoisTableTableOrderingComposer,
    $$CachedPoisTableTableAnnotationComposer,
    $$CachedPoisTableTableCreateCompanionBuilder,
    $$CachedPoisTableTableUpdateCompanionBuilder,
    (
      CachedPoi,
      BaseReferences<_$AppDatabase, $CachedPoisTableTable, CachedPoi>
    ),
    CachedPoi,
    PrefetchHooks Function()>;
typedef $$FreeVisitsTableTableCreateCompanionBuilder = FreeVisitsTableCompanion
    Function({
  Value<int> id,
  required String poiId,
  required String yearMonth,
  required DateTime visitedAt,
});
typedef $$FreeVisitsTableTableUpdateCompanionBuilder = FreeVisitsTableCompanion
    Function({
  Value<int> id,
  Value<String> poiId,
  Value<String> yearMonth,
  Value<DateTime> visitedAt,
});

class $$FreeVisitsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FreeVisitsTableTable> {
  $$FreeVisitsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get poiId => $composableBuilder(
      column: $table.poiId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get yearMonth => $composableBuilder(
      column: $table.yearMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get visitedAt => $composableBuilder(
      column: $table.visitedAt, builder: (column) => ColumnFilters(column));
}

class $$FreeVisitsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FreeVisitsTableTable> {
  $$FreeVisitsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get poiId => $composableBuilder(
      column: $table.poiId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get yearMonth => $composableBuilder(
      column: $table.yearMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get visitedAt => $composableBuilder(
      column: $table.visitedAt, builder: (column) => ColumnOrderings(column));
}

class $$FreeVisitsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FreeVisitsTableTable> {
  $$FreeVisitsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get poiId =>
      $composableBuilder(column: $table.poiId, builder: (column) => column);

  GeneratedColumn<String> get yearMonth =>
      $composableBuilder(column: $table.yearMonth, builder: (column) => column);

  GeneratedColumn<DateTime> get visitedAt =>
      $composableBuilder(column: $table.visitedAt, builder: (column) => column);
}

class $$FreeVisitsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FreeVisitsTableTable,
    FreeVisitsTableData,
    $$FreeVisitsTableTableFilterComposer,
    $$FreeVisitsTableTableOrderingComposer,
    $$FreeVisitsTableTableAnnotationComposer,
    $$FreeVisitsTableTableCreateCompanionBuilder,
    $$FreeVisitsTableTableUpdateCompanionBuilder,
    (
      FreeVisitsTableData,
      BaseReferences<_$AppDatabase, $FreeVisitsTableTable, FreeVisitsTableData>
    ),
    FreeVisitsTableData,
    PrefetchHooks Function()> {
  $$FreeVisitsTableTableTableManager(
      _$AppDatabase db, $FreeVisitsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FreeVisitsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FreeVisitsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FreeVisitsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> poiId = const Value.absent(),
            Value<String> yearMonth = const Value.absent(),
            Value<DateTime> visitedAt = const Value.absent(),
          }) =>
              FreeVisitsTableCompanion(
            id: id,
            poiId: poiId,
            yearMonth: yearMonth,
            visitedAt: visitedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String poiId,
            required String yearMonth,
            required DateTime visitedAt,
          }) =>
              FreeVisitsTableCompanion.insert(
            id: id,
            poiId: poiId,
            yearMonth: yearMonth,
            visitedAt: visitedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FreeVisitsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FreeVisitsTableTable,
    FreeVisitsTableData,
    $$FreeVisitsTableTableFilterComposer,
    $$FreeVisitsTableTableOrderingComposer,
    $$FreeVisitsTableTableAnnotationComposer,
    $$FreeVisitsTableTableCreateCompanionBuilder,
    $$FreeVisitsTableTableUpdateCompanionBuilder,
    (
      FreeVisitsTableData,
      BaseReferences<_$AppDatabase, $FreeVisitsTableTable, FreeVisitsTableData>
    ),
    FreeVisitsTableData,
    PrefetchHooks Function()>;
typedef $$RatedPoisTableTableCreateCompanionBuilder = RatedPoisTableCompanion
    Function({
  Value<int> localId,
  required String poiId,
  required int rating,
  Value<String?> reason,
  Value<String> langCode,
  required DateTime ratedAt,
});
typedef $$RatedPoisTableTableUpdateCompanionBuilder = RatedPoisTableCompanion
    Function({
  Value<int> localId,
  Value<String> poiId,
  Value<int> rating,
  Value<String?> reason,
  Value<String> langCode,
  Value<DateTime> ratedAt,
});

class $$RatedPoisTableTableFilterComposer
    extends Composer<_$AppDatabase, $RatedPoisTableTable> {
  $$RatedPoisTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get poiId => $composableBuilder(
      column: $table.poiId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get langCode => $composableBuilder(
      column: $table.langCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get ratedAt => $composableBuilder(
      column: $table.ratedAt, builder: (column) => ColumnFilters(column));
}

class $$RatedPoisTableTableOrderingComposer
    extends Composer<_$AppDatabase, $RatedPoisTableTable> {
  $$RatedPoisTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get poiId => $composableBuilder(
      column: $table.poiId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get langCode => $composableBuilder(
      column: $table.langCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get ratedAt => $composableBuilder(
      column: $table.ratedAt, builder: (column) => ColumnOrderings(column));
}

class $$RatedPoisTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $RatedPoisTableTable> {
  $$RatedPoisTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get poiId =>
      $composableBuilder(column: $table.poiId, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get langCode =>
      $composableBuilder(column: $table.langCode, builder: (column) => column);

  GeneratedColumn<DateTime> get ratedAt =>
      $composableBuilder(column: $table.ratedAt, builder: (column) => column);
}

class $$RatedPoisTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RatedPoisTableTable,
    RatedPoi,
    $$RatedPoisTableTableFilterComposer,
    $$RatedPoisTableTableOrderingComposer,
    $$RatedPoisTableTableAnnotationComposer,
    $$RatedPoisTableTableCreateCompanionBuilder,
    $$RatedPoisTableTableUpdateCompanionBuilder,
    (RatedPoi, BaseReferences<_$AppDatabase, $RatedPoisTableTable, RatedPoi>),
    RatedPoi,
    PrefetchHooks Function()> {
  $$RatedPoisTableTableTableManager(
      _$AppDatabase db, $RatedPoisTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RatedPoisTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RatedPoisTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RatedPoisTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> poiId = const Value.absent(),
            Value<int> rating = const Value.absent(),
            Value<String?> reason = const Value.absent(),
            Value<String> langCode = const Value.absent(),
            Value<DateTime> ratedAt = const Value.absent(),
          }) =>
              RatedPoisTableCompanion(
            localId: localId,
            poiId: poiId,
            rating: rating,
            reason: reason,
            langCode: langCode,
            ratedAt: ratedAt,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            required String poiId,
            required int rating,
            Value<String?> reason = const Value.absent(),
            Value<String> langCode = const Value.absent(),
            required DateTime ratedAt,
          }) =>
              RatedPoisTableCompanion.insert(
            localId: localId,
            poiId: poiId,
            rating: rating,
            reason: reason,
            langCode: langCode,
            ratedAt: ratedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RatedPoisTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RatedPoisTableTable,
    RatedPoi,
    $$RatedPoisTableTableFilterComposer,
    $$RatedPoisTableTableOrderingComposer,
    $$RatedPoisTableTableAnnotationComposer,
    $$RatedPoisTableTableCreateCompanionBuilder,
    $$RatedPoisTableTableUpdateCompanionBuilder,
    (RatedPoi, BaseReferences<_$AppDatabase, $RatedPoisTableTable, RatedPoi>),
    RatedPoi,
    PrefetchHooks Function()>;
typedef $$PurchasedPoisTableTableCreateCompanionBuilder
    = PurchasedPoisTableCompanion Function({
  required String poiId,
  Value<String?> stripeSessionId,
  required double pricePaid,
  required DateTime purchasedAt,
  Value<int> rowid,
});
typedef $$PurchasedPoisTableTableUpdateCompanionBuilder
    = PurchasedPoisTableCompanion Function({
  Value<String> poiId,
  Value<String?> stripeSessionId,
  Value<double> pricePaid,
  Value<DateTime> purchasedAt,
  Value<int> rowid,
});

class $$PurchasedPoisTableTableFilterComposer
    extends Composer<_$AppDatabase, $PurchasedPoisTableTable> {
  $$PurchasedPoisTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get poiId => $composableBuilder(
      column: $table.poiId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stripeSessionId => $composableBuilder(
      column: $table.stripeSessionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get pricePaid => $composableBuilder(
      column: $table.pricePaid, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get purchasedAt => $composableBuilder(
      column: $table.purchasedAt, builder: (column) => ColumnFilters(column));
}

class $$PurchasedPoisTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchasedPoisTableTable> {
  $$PurchasedPoisTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get poiId => $composableBuilder(
      column: $table.poiId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stripeSessionId => $composableBuilder(
      column: $table.stripeSessionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get pricePaid => $composableBuilder(
      column: $table.pricePaid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get purchasedAt => $composableBuilder(
      column: $table.purchasedAt, builder: (column) => ColumnOrderings(column));
}

class $$PurchasedPoisTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchasedPoisTableTable> {
  $$PurchasedPoisTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get poiId =>
      $composableBuilder(column: $table.poiId, builder: (column) => column);

  GeneratedColumn<String> get stripeSessionId => $composableBuilder(
      column: $table.stripeSessionId, builder: (column) => column);

  GeneratedColumn<double> get pricePaid =>
      $composableBuilder(column: $table.pricePaid, builder: (column) => column);

  GeneratedColumn<DateTime> get purchasedAt => $composableBuilder(
      column: $table.purchasedAt, builder: (column) => column);
}

class $$PurchasedPoisTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PurchasedPoisTableTable,
    PurchasedPoi,
    $$PurchasedPoisTableTableFilterComposer,
    $$PurchasedPoisTableTableOrderingComposer,
    $$PurchasedPoisTableTableAnnotationComposer,
    $$PurchasedPoisTableTableCreateCompanionBuilder,
    $$PurchasedPoisTableTableUpdateCompanionBuilder,
    (
      PurchasedPoi,
      BaseReferences<_$AppDatabase, $PurchasedPoisTableTable, PurchasedPoi>
    ),
    PurchasedPoi,
    PrefetchHooks Function()> {
  $$PurchasedPoisTableTableTableManager(
      _$AppDatabase db, $PurchasedPoisTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchasedPoisTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchasedPoisTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchasedPoisTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> poiId = const Value.absent(),
            Value<String?> stripeSessionId = const Value.absent(),
            Value<double> pricePaid = const Value.absent(),
            Value<DateTime> purchasedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PurchasedPoisTableCompanion(
            poiId: poiId,
            stripeSessionId: stripeSessionId,
            pricePaid: pricePaid,
            purchasedAt: purchasedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String poiId,
            Value<String?> stripeSessionId = const Value.absent(),
            required double pricePaid,
            required DateTime purchasedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PurchasedPoisTableCompanion.insert(
            poiId: poiId,
            stripeSessionId: stripeSessionId,
            pricePaid: pricePaid,
            purchasedAt: purchasedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PurchasedPoisTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PurchasedPoisTableTable,
    PurchasedPoi,
    $$PurchasedPoisTableTableFilterComposer,
    $$PurchasedPoisTableTableOrderingComposer,
    $$PurchasedPoisTableTableAnnotationComposer,
    $$PurchasedPoisTableTableCreateCompanionBuilder,
    $$PurchasedPoisTableTableUpdateCompanionBuilder,
    (
      PurchasedPoi,
      BaseReferences<_$AppDatabase, $PurchasedPoisTableTable, PurchasedPoi>
    ),
    PurchasedPoi,
    PrefetchHooks Function()>;
typedef $$PurchasedCityBundlesTableTableCreateCompanionBuilder
    = PurchasedCityBundlesTableCompanion Function({
  required String cityId,
  Value<String?> stripeSessionId,
  required double pricePaid,
  required DateTime purchasedAt,
  Value<int> rowid,
});
typedef $$PurchasedCityBundlesTableTableUpdateCompanionBuilder
    = PurchasedCityBundlesTableCompanion Function({
  Value<String> cityId,
  Value<String?> stripeSessionId,
  Value<double> pricePaid,
  Value<DateTime> purchasedAt,
  Value<int> rowid,
});

class $$PurchasedCityBundlesTableTableFilterComposer
    extends Composer<_$AppDatabase, $PurchasedCityBundlesTableTable> {
  $$PurchasedCityBundlesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cityId => $composableBuilder(
      column: $table.cityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stripeSessionId => $composableBuilder(
      column: $table.stripeSessionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get pricePaid => $composableBuilder(
      column: $table.pricePaid, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get purchasedAt => $composableBuilder(
      column: $table.purchasedAt, builder: (column) => ColumnFilters(column));
}

class $$PurchasedCityBundlesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchasedCityBundlesTableTable> {
  $$PurchasedCityBundlesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cityId => $composableBuilder(
      column: $table.cityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stripeSessionId => $composableBuilder(
      column: $table.stripeSessionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get pricePaid => $composableBuilder(
      column: $table.pricePaid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get purchasedAt => $composableBuilder(
      column: $table.purchasedAt, builder: (column) => ColumnOrderings(column));
}

class $$PurchasedCityBundlesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchasedCityBundlesTableTable> {
  $$PurchasedCityBundlesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cityId =>
      $composableBuilder(column: $table.cityId, builder: (column) => column);

  GeneratedColumn<String> get stripeSessionId => $composableBuilder(
      column: $table.stripeSessionId, builder: (column) => column);

  GeneratedColumn<double> get pricePaid =>
      $composableBuilder(column: $table.pricePaid, builder: (column) => column);

  GeneratedColumn<DateTime> get purchasedAt => $composableBuilder(
      column: $table.purchasedAt, builder: (column) => column);
}

class $$PurchasedCityBundlesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PurchasedCityBundlesTableTable,
    PurchasedCityBundle,
    $$PurchasedCityBundlesTableTableFilterComposer,
    $$PurchasedCityBundlesTableTableOrderingComposer,
    $$PurchasedCityBundlesTableTableAnnotationComposer,
    $$PurchasedCityBundlesTableTableCreateCompanionBuilder,
    $$PurchasedCityBundlesTableTableUpdateCompanionBuilder,
    (
      PurchasedCityBundle,
      BaseReferences<_$AppDatabase, $PurchasedCityBundlesTableTable,
          PurchasedCityBundle>
    ),
    PurchasedCityBundle,
    PrefetchHooks Function()> {
  $$PurchasedCityBundlesTableTableTableManager(
      _$AppDatabase db, $PurchasedCityBundlesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchasedCityBundlesTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchasedCityBundlesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchasedCityBundlesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> cityId = const Value.absent(),
            Value<String?> stripeSessionId = const Value.absent(),
            Value<double> pricePaid = const Value.absent(),
            Value<DateTime> purchasedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PurchasedCityBundlesTableCompanion(
            cityId: cityId,
            stripeSessionId: stripeSessionId,
            pricePaid: pricePaid,
            purchasedAt: purchasedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String cityId,
            Value<String?> stripeSessionId = const Value.absent(),
            required double pricePaid,
            required DateTime purchasedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PurchasedCityBundlesTableCompanion.insert(
            cityId: cityId,
            stripeSessionId: stripeSessionId,
            pricePaid: pricePaid,
            purchasedAt: purchasedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PurchasedCityBundlesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PurchasedCityBundlesTableTable,
        PurchasedCityBundle,
        $$PurchasedCityBundlesTableTableFilterComposer,
        $$PurchasedCityBundlesTableTableOrderingComposer,
        $$PurchasedCityBundlesTableTableAnnotationComposer,
        $$PurchasedCityBundlesTableTableCreateCompanionBuilder,
        $$PurchasedCityBundlesTableTableUpdateCompanionBuilder,
        (
          PurchasedCityBundle,
          BaseReferences<_$AppDatabase, $PurchasedCityBundlesTableTable,
              PurchasedCityBundle>
        ),
        PurchasedCityBundle,
        PrefetchHooks Function()>;
typedef $$CachedAudioGuidesTableTableCreateCompanionBuilder
    = CachedAudioGuidesTableCompanion Function({
  required String id,
  required String poiId,
  required String langCode,
  Value<String> title,
  required String url,
  Value<int?> durationSec,
  Value<int> sortOrder,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});
typedef $$CachedAudioGuidesTableTableUpdateCompanionBuilder
    = CachedAudioGuidesTableCompanion Function({
  Value<String> id,
  Value<String> poiId,
  Value<String> langCode,
  Value<String> title,
  Value<String> url,
  Value<int?> durationSec,
  Value<int> sortOrder,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$CachedAudioGuidesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CachedAudioGuidesTableTable> {
  $$CachedAudioGuidesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get poiId => $composableBuilder(
      column: $table.poiId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get langCode => $composableBuilder(
      column: $table.langCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSec => $composableBuilder(
      column: $table.durationSec, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedAudioGuidesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedAudioGuidesTableTable> {
  $$CachedAudioGuidesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get poiId => $composableBuilder(
      column: $table.poiId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get langCode => $composableBuilder(
      column: $table.langCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSec => $composableBuilder(
      column: $table.durationSec, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedAudioGuidesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedAudioGuidesTableTable> {
  $$CachedAudioGuidesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get poiId =>
      $composableBuilder(column: $table.poiId, builder: (column) => column);

  GeneratedColumn<String> get langCode =>
      $composableBuilder(column: $table.langCode, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
      column: $table.durationSec, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedAudioGuidesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedAudioGuidesTableTable,
    CachedAudioGuide,
    $$CachedAudioGuidesTableTableFilterComposer,
    $$CachedAudioGuidesTableTableOrderingComposer,
    $$CachedAudioGuidesTableTableAnnotationComposer,
    $$CachedAudioGuidesTableTableCreateCompanionBuilder,
    $$CachedAudioGuidesTableTableUpdateCompanionBuilder,
    (
      CachedAudioGuide,
      BaseReferences<_$AppDatabase, $CachedAudioGuidesTableTable,
          CachedAudioGuide>
    ),
    CachedAudioGuide,
    PrefetchHooks Function()> {
  $$CachedAudioGuidesTableTableTableManager(
      _$AppDatabase db, $CachedAudioGuidesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAudioGuidesTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedAudioGuidesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedAudioGuidesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> poiId = const Value.absent(),
            Value<String> langCode = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> url = const Value.absent(),
            Value<int?> durationSec = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedAudioGuidesTableCompanion(
            id: id,
            poiId: poiId,
            langCode: langCode,
            title: title,
            url: url,
            durationSec: durationSec,
            sortOrder: sortOrder,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String poiId,
            required String langCode,
            Value<String> title = const Value.absent(),
            required String url,
            Value<int?> durationSec = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedAudioGuidesTableCompanion.insert(
            id: id,
            poiId: poiId,
            langCode: langCode,
            title: title,
            url: url,
            durationSec: durationSec,
            sortOrder: sortOrder,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedAudioGuidesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CachedAudioGuidesTableTable,
        CachedAudioGuide,
        $$CachedAudioGuidesTableTableFilterComposer,
        $$CachedAudioGuidesTableTableOrderingComposer,
        $$CachedAudioGuidesTableTableAnnotationComposer,
        $$CachedAudioGuidesTableTableCreateCompanionBuilder,
        $$CachedAudioGuidesTableTableUpdateCompanionBuilder,
        (
          CachedAudioGuide,
          BaseReferences<_$AppDatabase, $CachedAudioGuidesTableTable,
              CachedAudioGuide>
        ),
        CachedAudioGuide,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VisitedPoisTableTableTableManager get visitedPoisTable =>
      $$VisitedPoisTableTableTableManager(_db, _db.visitedPoisTable);
  $$CachedPoisTableTableTableManager get cachedPoisTable =>
      $$CachedPoisTableTableTableManager(_db, _db.cachedPoisTable);
  $$FreeVisitsTableTableTableManager get freeVisitsTable =>
      $$FreeVisitsTableTableTableManager(_db, _db.freeVisitsTable);
  $$RatedPoisTableTableTableManager get ratedPoisTable =>
      $$RatedPoisTableTableTableManager(_db, _db.ratedPoisTable);
  $$PurchasedPoisTableTableTableManager get purchasedPoisTable =>
      $$PurchasedPoisTableTableTableManager(_db, _db.purchasedPoisTable);
  $$PurchasedCityBundlesTableTableTableManager get purchasedCityBundlesTable =>
      $$PurchasedCityBundlesTableTableTableManager(
          _db, _db.purchasedCityBundlesTable);
  $$CachedAudioGuidesTableTableTableManager get cachedAudioGuidesTable =>
      $$CachedAudioGuidesTableTableTableManager(
          _db, _db.cachedAudioGuidesTable);
}
