// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meya_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identityIdMeta = const VerificationMeta(
    'identityId',
  );
  @override
  late final GeneratedColumn<String> identityId = GeneratedColumn<String>(
    'identity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meyaIdMeta = const VerificationMeta('meyaId');
  @override
  late final GeneratedColumn<String> meyaId = GeneratedColumn<String>(
    'meya_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identityPublicKeyMeta = const VerificationMeta(
    'identityPublicKey',
  );
  @override
  late final GeneratedColumn<String> identityPublicKey =
      GeneratedColumn<String>(
        'identity_public_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    identityId,
    meyaId,
    name,
    username,
    createdAt,
    identityPublicKey,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('identity_id')) {
      context.handle(
        _identityIdMeta,
        identityId.isAcceptableOrUnknown(data['identity_id']!, _identityIdMeta),
      );
    }
    if (data.containsKey('meya_id')) {
      context.handle(
        _meyaIdMeta,
        meyaId.isAcceptableOrUnknown(data['meya_id']!, _meyaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_meyaIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('identity_public_key')) {
      context.handle(
        _identityPublicKeyMeta,
        identityPublicKey.isAcceptableOrUnknown(
          data['identity_public_key']!,
          _identityPublicKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identityPublicKeyMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      identityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_id'],
      ),
      meyaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meya_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      identityPublicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_public_key'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String accountId;
  final String? identityId;
  final String meyaId;
  final String name;
  final String username;
  final String createdAt;
  final String identityPublicKey;
  final bool isActive;
  const Account({
    required this.accountId,
    this.identityId,
    required this.meyaId,
    required this.name,
    required this.username,
    required this.createdAt,
    required this.identityPublicKey,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || identityId != null) {
      map['identity_id'] = Variable<String>(identityId);
    }
    map['meya_id'] = Variable<String>(meyaId);
    map['name'] = Variable<String>(name);
    map['username'] = Variable<String>(username);
    map['created_at'] = Variable<String>(createdAt);
    map['identity_public_key'] = Variable<String>(identityPublicKey);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      accountId: Value(accountId),
      identityId: identityId == null && nullToAbsent
          ? const Value.absent()
          : Value(identityId),
      meyaId: Value(meyaId),
      name: Value(name),
      username: Value(username),
      createdAt: Value(createdAt),
      identityPublicKey: Value(identityPublicKey),
      isActive: Value(isActive),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      accountId: serializer.fromJson<String>(json['accountId']),
      identityId: serializer.fromJson<String?>(json['identityId']),
      meyaId: serializer.fromJson<String>(json['meyaId']),
      name: serializer.fromJson<String>(json['name']),
      username: serializer.fromJson<String>(json['username']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      identityPublicKey: serializer.fromJson<String>(json['identityPublicKey']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'identityId': serializer.toJson<String?>(identityId),
      'meyaId': serializer.toJson<String>(meyaId),
      'name': serializer.toJson<String>(name),
      'username': serializer.toJson<String>(username),
      'createdAt': serializer.toJson<String>(createdAt),
      'identityPublicKey': serializer.toJson<String>(identityPublicKey),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Account copyWith({
    String? accountId,
    Value<String?> identityId = const Value.absent(),
    String? meyaId,
    String? name,
    String? username,
    String? createdAt,
    String? identityPublicKey,
    bool? isActive,
  }) => Account(
    accountId: accountId ?? this.accountId,
    identityId: identityId.present ? identityId.value : this.identityId,
    meyaId: meyaId ?? this.meyaId,
    name: name ?? this.name,
    username: username ?? this.username,
    createdAt: createdAt ?? this.createdAt,
    identityPublicKey: identityPublicKey ?? this.identityPublicKey,
    isActive: isActive ?? this.isActive,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      identityId: data.identityId.present
          ? data.identityId.value
          : this.identityId,
      meyaId: data.meyaId.present ? data.meyaId.value : this.meyaId,
      name: data.name.present ? data.name.value : this.name,
      username: data.username.present ? data.username.value : this.username,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      identityPublicKey: data.identityPublicKey.present
          ? data.identityPublicKey.value
          : this.identityPublicKey,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('accountId: $accountId, ')
          ..write('identityId: $identityId, ')
          ..write('meyaId: $meyaId, ')
          ..write('name: $name, ')
          ..write('username: $username, ')
          ..write('createdAt: $createdAt, ')
          ..write('identityPublicKey: $identityPublicKey, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    identityId,
    meyaId,
    name,
    username,
    createdAt,
    identityPublicKey,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.accountId == this.accountId &&
          other.identityId == this.identityId &&
          other.meyaId == this.meyaId &&
          other.name == this.name &&
          other.username == this.username &&
          other.createdAt == this.createdAt &&
          other.identityPublicKey == this.identityPublicKey &&
          other.isActive == this.isActive);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> accountId;
  final Value<String?> identityId;
  final Value<String> meyaId;
  final Value<String> name;
  final Value<String> username;
  final Value<String> createdAt;
  final Value<String> identityPublicKey;
  final Value<bool> isActive;
  final Value<int> rowid;
  const AccountsCompanion({
    this.accountId = const Value.absent(),
    this.identityId = const Value.absent(),
    this.meyaId = const Value.absent(),
    this.name = const Value.absent(),
    this.username = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.identityPublicKey = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String accountId,
    this.identityId = const Value.absent(),
    required String meyaId,
    required String name,
    required String username,
    required String createdAt,
    required String identityPublicKey,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       meyaId = Value(meyaId),
       name = Value(name),
       username = Value(username),
       createdAt = Value(createdAt),
       identityPublicKey = Value(identityPublicKey);
  static Insertable<Account> custom({
    Expression<String>? accountId,
    Expression<String>? identityId,
    Expression<String>? meyaId,
    Expression<String>? name,
    Expression<String>? username,
    Expression<String>? createdAt,
    Expression<String>? identityPublicKey,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (identityId != null) 'identity_id': identityId,
      if (meyaId != null) 'meya_id': meyaId,
      if (name != null) 'name': name,
      if (username != null) 'username': username,
      if (createdAt != null) 'created_at': createdAt,
      if (identityPublicKey != null) 'identity_public_key': identityPublicKey,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? accountId,
    Value<String?>? identityId,
    Value<String>? meyaId,
    Value<String>? name,
    Value<String>? username,
    Value<String>? createdAt,
    Value<String>? identityPublicKey,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      accountId: accountId ?? this.accountId,
      identityId: identityId ?? this.identityId,
      meyaId: meyaId ?? this.meyaId,
      name: name ?? this.name,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      identityPublicKey: identityPublicKey ?? this.identityPublicKey,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (identityId.present) {
      map['identity_id'] = Variable<String>(identityId.value);
    }
    if (meyaId.present) {
      map['meya_id'] = Variable<String>(meyaId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (identityPublicKey.present) {
      map['identity_public_key'] = Variable<String>(identityPublicKey.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('identityId: $identityId, ')
          ..write('meyaId: $meyaId, ')
          ..write('name: $name, ')
          ..write('username: $username, ')
          ..write('createdAt: $createdAt, ')
          ..write('identityPublicKey: $identityPublicKey, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (account_id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _devicePublicKeyMeta = const VerificationMeta(
    'devicePublicKey',
  );
  @override
  late final GeneratedColumn<String> devicePublicKey = GeneratedColumn<String>(
    'device_public_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _certificateSignatureMeta =
      const VerificationMeta('certificateSignature');
  @override
  late final GeneratedColumn<String> certificateSignature =
      GeneratedColumn<String>(
        'certificate_signature',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isTrustedMeta = const VerificationMeta(
    'isTrusted',
  );
  @override
  late final GeneratedColumn<bool> isTrusted = GeneratedColumn<bool>(
    'is_trusted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_trusted" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isRevokedMeta = const VerificationMeta(
    'isRevoked',
  );
  @override
  late final GeneratedColumn<bool> isRevoked = GeneratedColumn<bool>(
    'is_revoked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_revoked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    accountId,
    createdAt,
    devicePublicKey,
    certificateSignature,
    isTrusted,
    isRevoked,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Device> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('device_public_key')) {
      context.handle(
        _devicePublicKeyMeta,
        devicePublicKey.isAcceptableOrUnknown(
          data['device_public_key']!,
          _devicePublicKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_devicePublicKeyMeta);
    }
    if (data.containsKey('certificate_signature')) {
      context.handle(
        _certificateSignatureMeta,
        certificateSignature.isAcceptableOrUnknown(
          data['certificate_signature']!,
          _certificateSignatureMeta,
        ),
      );
    }
    if (data.containsKey('is_trusted')) {
      context.handle(
        _isTrustedMeta,
        isTrusted.isAcceptableOrUnknown(data['is_trusted']!, _isTrustedMeta),
      );
    }
    if (data.containsKey('is_revoked')) {
      context.handle(
        _isRevokedMeta,
        isRevoked.isAcceptableOrUnknown(data['is_revoked']!, _isRevokedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      devicePublicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_public_key'],
      )!,
      certificateSignature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certificate_signature'],
      ),
      isTrusted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_trusted'],
      )!,
      isRevoked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_revoked'],
      )!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  final String deviceId;
  final String accountId;
  final String createdAt;
  final String devicePublicKey;
  final String? certificateSignature;
  final bool isTrusted;
  final bool isRevoked;
  const Device({
    required this.deviceId,
    required this.accountId,
    required this.createdAt,
    required this.devicePublicKey,
    this.certificateSignature,
    required this.isTrusted,
    required this.isRevoked,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['account_id'] = Variable<String>(accountId);
    map['created_at'] = Variable<String>(createdAt);
    map['device_public_key'] = Variable<String>(devicePublicKey);
    if (!nullToAbsent || certificateSignature != null) {
      map['certificate_signature'] = Variable<String>(certificateSignature);
    }
    map['is_trusted'] = Variable<bool>(isTrusted);
    map['is_revoked'] = Variable<bool>(isRevoked);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      deviceId: Value(deviceId),
      accountId: Value(accountId),
      createdAt: Value(createdAt),
      devicePublicKey: Value(devicePublicKey),
      certificateSignature: certificateSignature == null && nullToAbsent
          ? const Value.absent()
          : Value(certificateSignature),
      isTrusted: Value(isTrusted),
      isRevoked: Value(isRevoked),
    );
  }

  factory Device.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      devicePublicKey: serializer.fromJson<String>(json['devicePublicKey']),
      certificateSignature: serializer.fromJson<String?>(
        json['certificateSignature'],
      ),
      isTrusted: serializer.fromJson<bool>(json['isTrusted']),
      isRevoked: serializer.fromJson<bool>(json['isRevoked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'accountId': serializer.toJson<String>(accountId),
      'createdAt': serializer.toJson<String>(createdAt),
      'devicePublicKey': serializer.toJson<String>(devicePublicKey),
      'certificateSignature': serializer.toJson<String?>(certificateSignature),
      'isTrusted': serializer.toJson<bool>(isTrusted),
      'isRevoked': serializer.toJson<bool>(isRevoked),
    };
  }

  Device copyWith({
    String? deviceId,
    String? accountId,
    String? createdAt,
    String? devicePublicKey,
    Value<String?> certificateSignature = const Value.absent(),
    bool? isTrusted,
    bool? isRevoked,
  }) => Device(
    deviceId: deviceId ?? this.deviceId,
    accountId: accountId ?? this.accountId,
    createdAt: createdAt ?? this.createdAt,
    devicePublicKey: devicePublicKey ?? this.devicePublicKey,
    certificateSignature: certificateSignature.present
        ? certificateSignature.value
        : this.certificateSignature,
    isTrusted: isTrusted ?? this.isTrusted,
    isRevoked: isRevoked ?? this.isRevoked,
  );
  Device copyWithCompanion(DevicesCompanion data) {
    return Device(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      devicePublicKey: data.devicePublicKey.present
          ? data.devicePublicKey.value
          : this.devicePublicKey,
      certificateSignature: data.certificateSignature.present
          ? data.certificateSignature.value
          : this.certificateSignature,
      isTrusted: data.isTrusted.present ? data.isTrusted.value : this.isTrusted,
      isRevoked: data.isRevoked.present ? data.isRevoked.value : this.isRevoked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('deviceId: $deviceId, ')
          ..write('accountId: $accountId, ')
          ..write('createdAt: $createdAt, ')
          ..write('devicePublicKey: $devicePublicKey, ')
          ..write('certificateSignature: $certificateSignature, ')
          ..write('isTrusted: $isTrusted, ')
          ..write('isRevoked: $isRevoked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    accountId,
    createdAt,
    devicePublicKey,
    certificateSignature,
    isTrusted,
    isRevoked,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.deviceId == this.deviceId &&
          other.accountId == this.accountId &&
          other.createdAt == this.createdAt &&
          other.devicePublicKey == this.devicePublicKey &&
          other.certificateSignature == this.certificateSignature &&
          other.isTrusted == this.isTrusted &&
          other.isRevoked == this.isRevoked);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<String> deviceId;
  final Value<String> accountId;
  final Value<String> createdAt;
  final Value<String> devicePublicKey;
  final Value<String?> certificateSignature;
  final Value<bool> isTrusted;
  final Value<bool> isRevoked;
  final Value<int> rowid;
  const DevicesCompanion({
    this.deviceId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.devicePublicKey = const Value.absent(),
    this.certificateSignature = const Value.absent(),
    this.isTrusted = const Value.absent(),
    this.isRevoked = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String deviceId,
    required String accountId,
    required String createdAt,
    required String devicePublicKey,
    this.certificateSignature = const Value.absent(),
    this.isTrusted = const Value.absent(),
    this.isRevoked = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       accountId = Value(accountId),
       createdAt = Value(createdAt),
       devicePublicKey = Value(devicePublicKey);
  static Insertable<Device> custom({
    Expression<String>? deviceId,
    Expression<String>? accountId,
    Expression<String>? createdAt,
    Expression<String>? devicePublicKey,
    Expression<String>? certificateSignature,
    Expression<bool>? isTrusted,
    Expression<bool>? isRevoked,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (accountId != null) 'account_id': accountId,
      if (createdAt != null) 'created_at': createdAt,
      if (devicePublicKey != null) 'device_public_key': devicePublicKey,
      if (certificateSignature != null)
        'certificate_signature': certificateSignature,
      if (isTrusted != null) 'is_trusted': isTrusted,
      if (isRevoked != null) 'is_revoked': isRevoked,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? accountId,
    Value<String>? createdAt,
    Value<String>? devicePublicKey,
    Value<String?>? certificateSignature,
    Value<bool>? isTrusted,
    Value<bool>? isRevoked,
    Value<int>? rowid,
  }) {
    return DevicesCompanion(
      deviceId: deviceId ?? this.deviceId,
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
      devicePublicKey: devicePublicKey ?? this.devicePublicKey,
      certificateSignature: certificateSignature ?? this.certificateSignature,
      isTrusted: isTrusted ?? this.isTrusted,
      isRevoked: isRevoked ?? this.isRevoked,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (devicePublicKey.present) {
      map['device_public_key'] = Variable<String>(devicePublicKey.value);
    }
    if (certificateSignature.present) {
      map['certificate_signature'] = Variable<String>(
        certificateSignature.value,
      );
    }
    if (isTrusted.present) {
      map['is_trusted'] = Variable<bool>(isTrusted.value);
    }
    if (isRevoked.present) {
      map['is_revoked'] = Variable<bool>(isRevoked.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('accountId: $accountId, ')
          ..write('createdAt: $createdAt, ')
          ..write('devicePublicKey: $devicePublicKey, ')
          ..write('certificateSignature: $certificateSignature, ')
          ..write('isTrusted: $isTrusted, ')
          ..write('isRevoked: $isRevoked, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactsTable extends Contacts with TableInfo<$ContactsTable, Contact> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
    'contact_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identityIdMeta = const VerificationMeta(
    'identityId',
  );
  @override
  late final GeneratedColumn<String> identityId = GeneratedColumn<String>(
    'identity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identityPublicKeyMeta = const VerificationMeta(
    'identityPublicKey',
  );
  @override
  late final GeneratedColumn<String> identityPublicKey =
      GeneratedColumn<String>(
        'identity_public_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _trustStateMeta = const VerificationMeta(
    'trustState',
  );
  @override
  late final GeneratedColumn<String> trustState = GeneratedColumn<String>(
    'trust_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('trusted'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRevokedMeta = const VerificationMeta(
    'isRevoked',
  );
  @override
  late final GeneratedColumn<bool> isRevoked = GeneratedColumn<bool>(
    'is_revoked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_revoked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    contactId,
    identityId,
    displayName,
    identityPublicKey,
    trustState,
    createdAt,
    updatedAt,
    isRevoked,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Contact> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('identity_id')) {
      context.handle(
        _identityIdMeta,
        identityId.isAcceptableOrUnknown(data['identity_id']!, _identityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_identityIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('identity_public_key')) {
      context.handle(
        _identityPublicKeyMeta,
        identityPublicKey.isAcceptableOrUnknown(
          data['identity_public_key']!,
          _identityPublicKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identityPublicKeyMeta);
    }
    if (data.containsKey('trust_state')) {
      context.handle(
        _trustStateMeta,
        trustState.isAcceptableOrUnknown(data['trust_state']!, _trustStateMeta),
      );
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
    if (data.containsKey('is_revoked')) {
      context.handle(
        _isRevokedMeta,
        isRevoked.isAcceptableOrUnknown(data['is_revoked']!, _isRevokedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contactId};
  @override
  Contact map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contact(
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_id'],
      )!,
      identityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      identityPublicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_public_key'],
      )!,
      trustState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trust_state'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      isRevoked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_revoked'],
      )!,
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class Contact extends DataClass implements Insertable<Contact> {
  final String contactId;
  final String identityId;
  final String displayName;
  final String identityPublicKey;
  final String trustState;
  final String createdAt;
  final String updatedAt;
  final bool isRevoked;
  const Contact({
    required this.contactId,
    required this.identityId,
    required this.displayName,
    required this.identityPublicKey,
    required this.trustState,
    required this.createdAt,
    required this.updatedAt,
    required this.isRevoked,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['contact_id'] = Variable<String>(contactId);
    map['identity_id'] = Variable<String>(identityId);
    map['display_name'] = Variable<String>(displayName);
    map['identity_public_key'] = Variable<String>(identityPublicKey);
    map['trust_state'] = Variable<String>(trustState);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['is_revoked'] = Variable<bool>(isRevoked);
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      contactId: Value(contactId),
      identityId: Value(identityId),
      displayName: Value(displayName),
      identityPublicKey: Value(identityPublicKey),
      trustState: Value(trustState),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isRevoked: Value(isRevoked),
    );
  }

  factory Contact.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contact(
      contactId: serializer.fromJson<String>(json['contactId']),
      identityId: serializer.fromJson<String>(json['identityId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      identityPublicKey: serializer.fromJson<String>(json['identityPublicKey']),
      trustState: serializer.fromJson<String>(json['trustState']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      isRevoked: serializer.fromJson<bool>(json['isRevoked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contactId': serializer.toJson<String>(contactId),
      'identityId': serializer.toJson<String>(identityId),
      'displayName': serializer.toJson<String>(displayName),
      'identityPublicKey': serializer.toJson<String>(identityPublicKey),
      'trustState': serializer.toJson<String>(trustState),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'isRevoked': serializer.toJson<bool>(isRevoked),
    };
  }

  Contact copyWith({
    String? contactId,
    String? identityId,
    String? displayName,
    String? identityPublicKey,
    String? trustState,
    String? createdAt,
    String? updatedAt,
    bool? isRevoked,
  }) => Contact(
    contactId: contactId ?? this.contactId,
    identityId: identityId ?? this.identityId,
    displayName: displayName ?? this.displayName,
    identityPublicKey: identityPublicKey ?? this.identityPublicKey,
    trustState: trustState ?? this.trustState,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isRevoked: isRevoked ?? this.isRevoked,
  );
  Contact copyWithCompanion(ContactsCompanion data) {
    return Contact(
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      identityId: data.identityId.present
          ? data.identityId.value
          : this.identityId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      identityPublicKey: data.identityPublicKey.present
          ? data.identityPublicKey.value
          : this.identityPublicKey,
      trustState: data.trustState.present
          ? data.trustState.value
          : this.trustState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isRevoked: data.isRevoked.present ? data.isRevoked.value : this.isRevoked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contact(')
          ..write('contactId: $contactId, ')
          ..write('identityId: $identityId, ')
          ..write('displayName: $displayName, ')
          ..write('identityPublicKey: $identityPublicKey, ')
          ..write('trustState: $trustState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isRevoked: $isRevoked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    contactId,
    identityId,
    displayName,
    identityPublicKey,
    trustState,
    createdAt,
    updatedAt,
    isRevoked,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contact &&
          other.contactId == this.contactId &&
          other.identityId == this.identityId &&
          other.displayName == this.displayName &&
          other.identityPublicKey == this.identityPublicKey &&
          other.trustState == this.trustState &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isRevoked == this.isRevoked);
}

class ContactsCompanion extends UpdateCompanion<Contact> {
  final Value<String> contactId;
  final Value<String> identityId;
  final Value<String> displayName;
  final Value<String> identityPublicKey;
  final Value<String> trustState;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<bool> isRevoked;
  final Value<int> rowid;
  const ContactsCompanion({
    this.contactId = const Value.absent(),
    this.identityId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.identityPublicKey = const Value.absent(),
    this.trustState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isRevoked = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactsCompanion.insert({
    required String contactId,
    required String identityId,
    required String displayName,
    required String identityPublicKey,
    this.trustState = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.isRevoked = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : contactId = Value(contactId),
       identityId = Value(identityId),
       displayName = Value(displayName),
       identityPublicKey = Value(identityPublicKey),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Contact> custom({
    Expression<String>? contactId,
    Expression<String>? identityId,
    Expression<String>? displayName,
    Expression<String>? identityPublicKey,
    Expression<String>? trustState,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<bool>? isRevoked,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contactId != null) 'contact_id': contactId,
      if (identityId != null) 'identity_id': identityId,
      if (displayName != null) 'display_name': displayName,
      if (identityPublicKey != null) 'identity_public_key': identityPublicKey,
      if (trustState != null) 'trust_state': trustState,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isRevoked != null) 'is_revoked': isRevoked,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactsCompanion copyWith({
    Value<String>? contactId,
    Value<String>? identityId,
    Value<String>? displayName,
    Value<String>? identityPublicKey,
    Value<String>? trustState,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<bool>? isRevoked,
    Value<int>? rowid,
  }) {
    return ContactsCompanion(
      contactId: contactId ?? this.contactId,
      identityId: identityId ?? this.identityId,
      displayName: displayName ?? this.displayName,
      identityPublicKey: identityPublicKey ?? this.identityPublicKey,
      trustState: trustState ?? this.trustState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRevoked: isRevoked ?? this.isRevoked,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (identityId.present) {
      map['identity_id'] = Variable<String>(identityId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (identityPublicKey.present) {
      map['identity_public_key'] = Variable<String>(identityPublicKey.value);
    }
    if (trustState.present) {
      map['trust_state'] = Variable<String>(trustState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (isRevoked.present) {
      map['is_revoked'] = Variable<bool>(isRevoked.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('contactId: $contactId, ')
          ..write('identityId: $identityId, ')
          ..write('displayName: $displayName, ')
          ..write('identityPublicKey: $identityPublicKey, ')
          ..write('trustState: $trustState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isRevoked: $isRevoked, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactDevicesTable extends ContactDevices
    with TableInfo<$ContactDevicesTable, ContactDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
    'contact_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contacts (contact_id)',
    ),
  );
  static const VerificationMeta _devicePublicKeyMeta = const VerificationMeta(
    'devicePublicKey',
  );
  @override
  late final GeneratedColumn<String> devicePublicKey = GeneratedColumn<String>(
    'device_public_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _certificateSignatureMeta =
      const VerificationMeta('certificateSignature');
  @override
  late final GeneratedColumn<String> certificateSignature =
      GeneratedColumn<String>(
        'certificate_signature',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _keyPackageMeta = const VerificationMeta(
    'keyPackage',
  );
  @override
  late final GeneratedColumn<Uint8List> keyPackage = GeneratedColumn<Uint8List>(
    'key_package',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRevokedMeta = const VerificationMeta(
    'isRevoked',
  );
  @override
  late final GeneratedColumn<bool> isRevoked = GeneratedColumn<bool>(
    'is_revoked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_revoked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    contactId,
    devicePublicKey,
    certificateSignature,
    keyPackage,
    createdAt,
    updatedAt,
    isRevoked,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactDevice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('device_public_key')) {
      context.handle(
        _devicePublicKeyMeta,
        devicePublicKey.isAcceptableOrUnknown(
          data['device_public_key']!,
          _devicePublicKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_devicePublicKeyMeta);
    }
    if (data.containsKey('certificate_signature')) {
      context.handle(
        _certificateSignatureMeta,
        certificateSignature.isAcceptableOrUnknown(
          data['certificate_signature']!,
          _certificateSignatureMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_certificateSignatureMeta);
    }
    if (data.containsKey('key_package')) {
      context.handle(
        _keyPackageMeta,
        keyPackage.isAcceptableOrUnknown(data['key_package']!, _keyPackageMeta),
      );
    } else if (isInserting) {
      context.missing(_keyPackageMeta);
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
    if (data.containsKey('is_revoked')) {
      context.handle(
        _isRevokedMeta,
        isRevoked.isAcceptableOrUnknown(data['is_revoked']!, _isRevokedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  ContactDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactDevice(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_id'],
      )!,
      devicePublicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_public_key'],
      )!,
      certificateSignature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certificate_signature'],
      )!,
      keyPackage: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}key_package'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      isRevoked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_revoked'],
      )!,
    );
  }

  @override
  $ContactDevicesTable createAlias(String alias) {
    return $ContactDevicesTable(attachedDatabase, alias);
  }
}

class ContactDevice extends DataClass implements Insertable<ContactDevice> {
  final String deviceId;
  final String contactId;
  final String devicePublicKey;
  final String certificateSignature;
  final Uint8List keyPackage;
  final String createdAt;
  final String updatedAt;
  final bool isRevoked;
  const ContactDevice({
    required this.deviceId,
    required this.contactId,
    required this.devicePublicKey,
    required this.certificateSignature,
    required this.keyPackage,
    required this.createdAt,
    required this.updatedAt,
    required this.isRevoked,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['contact_id'] = Variable<String>(contactId);
    map['device_public_key'] = Variable<String>(devicePublicKey);
    map['certificate_signature'] = Variable<String>(certificateSignature);
    map['key_package'] = Variable<Uint8List>(keyPackage);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['is_revoked'] = Variable<bool>(isRevoked);
    return map;
  }

  ContactDevicesCompanion toCompanion(bool nullToAbsent) {
    return ContactDevicesCompanion(
      deviceId: Value(deviceId),
      contactId: Value(contactId),
      devicePublicKey: Value(devicePublicKey),
      certificateSignature: Value(certificateSignature),
      keyPackage: Value(keyPackage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isRevoked: Value(isRevoked),
    );
  }

  factory ContactDevice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactDevice(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      contactId: serializer.fromJson<String>(json['contactId']),
      devicePublicKey: serializer.fromJson<String>(json['devicePublicKey']),
      certificateSignature: serializer.fromJson<String>(
        json['certificateSignature'],
      ),
      keyPackage: serializer.fromJson<Uint8List>(json['keyPackage']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      isRevoked: serializer.fromJson<bool>(json['isRevoked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'contactId': serializer.toJson<String>(contactId),
      'devicePublicKey': serializer.toJson<String>(devicePublicKey),
      'certificateSignature': serializer.toJson<String>(certificateSignature),
      'keyPackage': serializer.toJson<Uint8List>(keyPackage),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'isRevoked': serializer.toJson<bool>(isRevoked),
    };
  }

  ContactDevice copyWith({
    String? deviceId,
    String? contactId,
    String? devicePublicKey,
    String? certificateSignature,
    Uint8List? keyPackage,
    String? createdAt,
    String? updatedAt,
    bool? isRevoked,
  }) => ContactDevice(
    deviceId: deviceId ?? this.deviceId,
    contactId: contactId ?? this.contactId,
    devicePublicKey: devicePublicKey ?? this.devicePublicKey,
    certificateSignature: certificateSignature ?? this.certificateSignature,
    keyPackage: keyPackage ?? this.keyPackage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isRevoked: isRevoked ?? this.isRevoked,
  );
  ContactDevice copyWithCompanion(ContactDevicesCompanion data) {
    return ContactDevice(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      devicePublicKey: data.devicePublicKey.present
          ? data.devicePublicKey.value
          : this.devicePublicKey,
      certificateSignature: data.certificateSignature.present
          ? data.certificateSignature.value
          : this.certificateSignature,
      keyPackage: data.keyPackage.present
          ? data.keyPackage.value
          : this.keyPackage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isRevoked: data.isRevoked.present ? data.isRevoked.value : this.isRevoked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactDevice(')
          ..write('deviceId: $deviceId, ')
          ..write('contactId: $contactId, ')
          ..write('devicePublicKey: $devicePublicKey, ')
          ..write('certificateSignature: $certificateSignature, ')
          ..write('keyPackage: $keyPackage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isRevoked: $isRevoked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    contactId,
    devicePublicKey,
    certificateSignature,
    $driftBlobEquality.hash(keyPackage),
    createdAt,
    updatedAt,
    isRevoked,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactDevice &&
          other.deviceId == this.deviceId &&
          other.contactId == this.contactId &&
          other.devicePublicKey == this.devicePublicKey &&
          other.certificateSignature == this.certificateSignature &&
          $driftBlobEquality.equals(other.keyPackage, this.keyPackage) &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isRevoked == this.isRevoked);
}

class ContactDevicesCompanion extends UpdateCompanion<ContactDevice> {
  final Value<String> deviceId;
  final Value<String> contactId;
  final Value<String> devicePublicKey;
  final Value<String> certificateSignature;
  final Value<Uint8List> keyPackage;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<bool> isRevoked;
  final Value<int> rowid;
  const ContactDevicesCompanion({
    this.deviceId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.devicePublicKey = const Value.absent(),
    this.certificateSignature = const Value.absent(),
    this.keyPackage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isRevoked = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactDevicesCompanion.insert({
    required String deviceId,
    required String contactId,
    required String devicePublicKey,
    required String certificateSignature,
    required Uint8List keyPackage,
    required String createdAt,
    required String updatedAt,
    this.isRevoked = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       contactId = Value(contactId),
       devicePublicKey = Value(devicePublicKey),
       certificateSignature = Value(certificateSignature),
       keyPackage = Value(keyPackage),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ContactDevice> custom({
    Expression<String>? deviceId,
    Expression<String>? contactId,
    Expression<String>? devicePublicKey,
    Expression<String>? certificateSignature,
    Expression<Uint8List>? keyPackage,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<bool>? isRevoked,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (contactId != null) 'contact_id': contactId,
      if (devicePublicKey != null) 'device_public_key': devicePublicKey,
      if (certificateSignature != null)
        'certificate_signature': certificateSignature,
      if (keyPackage != null) 'key_package': keyPackage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isRevoked != null) 'is_revoked': isRevoked,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactDevicesCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? contactId,
    Value<String>? devicePublicKey,
    Value<String>? certificateSignature,
    Value<Uint8List>? keyPackage,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<bool>? isRevoked,
    Value<int>? rowid,
  }) {
    return ContactDevicesCompanion(
      deviceId: deviceId ?? this.deviceId,
      contactId: contactId ?? this.contactId,
      devicePublicKey: devicePublicKey ?? this.devicePublicKey,
      certificateSignature: certificateSignature ?? this.certificateSignature,
      keyPackage: keyPackage ?? this.keyPackage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRevoked: isRevoked ?? this.isRevoked,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (devicePublicKey.present) {
      map['device_public_key'] = Variable<String>(devicePublicKey.value);
    }
    if (certificateSignature.present) {
      map['certificate_signature'] = Variable<String>(
        certificateSignature.value,
      );
    }
    if (keyPackage.present) {
      map['key_package'] = Variable<Uint8List>(keyPackage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (isRevoked.present) {
      map['is_revoked'] = Variable<bool>(isRevoked.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactDevicesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('contactId: $contactId, ')
          ..write('devicePublicKey: $devicePublicKey, ')
          ..write('certificateSignature: $certificateSignature, ')
          ..write('keyPackage: $keyPackage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isRevoked: $isRevoked, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConnectionRequestsTable extends ConnectionRequests
    with TableInfo<$ConnectionRequestsTable, ConnectionRequest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdentityIdMeta = const VerificationMeta(
    'senderIdentityId',
  );
  @override
  late final GeneratedColumn<String> senderIdentityId = GeneratedColumn<String>(
    'sender_identity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderDeviceIdMeta = const VerificationMeta(
    'senderDeviceId',
  );
  @override
  late final GeneratedColumn<String> senderDeviceId = GeneratedColumn<String>(
    'sender_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderUsernameMeta = const VerificationMeta(
    'senderUsername',
  );
  @override
  late final GeneratedColumn<String> senderUsername = GeneratedColumn<String>(
    'sender_username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdentityPublicKeyMeta =
      const VerificationMeta('senderIdentityPublicKey');
  @override
  late final GeneratedColumn<String> senderIdentityPublicKey =
      GeneratedColumn<String>(
        'sender_identity_public_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _recipientDeviceIdMeta = const VerificationMeta(
    'recipientDeviceId',
  );
  @override
  late final GeneratedColumn<String> recipientDeviceId =
      GeneratedColumn<String>(
        'recipient_device_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _recipientIdentityIdMeta =
      const VerificationMeta('recipientIdentityId');
  @override
  late final GeneratedColumn<String> recipientIdentityId =
      GeneratedColumn<String>(
        'recipient_identity_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _recipientIdentityPublicKeyMeta =
      const VerificationMeta('recipientIdentityPublicKey');
  @override
  late final GeneratedColumn<String> recipientIdentityPublicKey =
      GeneratedColumn<String>(
        'recipient_identity_public_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    requestId,
    senderIdentityId,
    senderDeviceId,
    senderUsername,
    senderIdentityPublicKey,
    recipientDeviceId,
    recipientIdentityId,
    recipientIdentityPublicKey,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connection_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConnectionRequest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_requestIdMeta);
    }
    if (data.containsKey('sender_identity_id')) {
      context.handle(
        _senderIdentityIdMeta,
        senderIdentityId.isAcceptableOrUnknown(
          data['sender_identity_id']!,
          _senderIdentityIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_senderIdentityIdMeta);
    }
    if (data.containsKey('sender_device_id')) {
      context.handle(
        _senderDeviceIdMeta,
        senderDeviceId.isAcceptableOrUnknown(
          data['sender_device_id']!,
          _senderDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_senderDeviceIdMeta);
    }
    if (data.containsKey('sender_username')) {
      context.handle(
        _senderUsernameMeta,
        senderUsername.isAcceptableOrUnknown(
          data['sender_username']!,
          _senderUsernameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_senderUsernameMeta);
    }
    if (data.containsKey('sender_identity_public_key')) {
      context.handle(
        _senderIdentityPublicKeyMeta,
        senderIdentityPublicKey.isAcceptableOrUnknown(
          data['sender_identity_public_key']!,
          _senderIdentityPublicKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_senderIdentityPublicKeyMeta);
    }
    if (data.containsKey('recipient_device_id')) {
      context.handle(
        _recipientDeviceIdMeta,
        recipientDeviceId.isAcceptableOrUnknown(
          data['recipient_device_id']!,
          _recipientDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientDeviceIdMeta);
    }
    if (data.containsKey('recipient_identity_id')) {
      context.handle(
        _recipientIdentityIdMeta,
        recipientIdentityId.isAcceptableOrUnknown(
          data['recipient_identity_id']!,
          _recipientIdentityIdMeta,
        ),
      );
    }
    if (data.containsKey('recipient_identity_public_key')) {
      context.handle(
        _recipientIdentityPublicKeyMeta,
        recipientIdentityPublicKey.isAcceptableOrUnknown(
          data['recipient_identity_public_key']!,
          _recipientIdentityPublicKeyMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {requestId};
  @override
  ConnectionRequest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectionRequest(
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      )!,
      senderIdentityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_identity_id'],
      )!,
      senderDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_device_id'],
      )!,
      senderUsername: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_username'],
      )!,
      senderIdentityPublicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_identity_public_key'],
      )!,
      recipientDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_device_id'],
      )!,
      recipientIdentityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_identity_id'],
      ),
      recipientIdentityPublicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_identity_public_key'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ConnectionRequestsTable createAlias(String alias) {
    return $ConnectionRequestsTable(attachedDatabase, alias);
  }
}

class ConnectionRequest extends DataClass
    implements Insertable<ConnectionRequest> {
  final String requestId;
  final String senderIdentityId;
  final String senderDeviceId;
  final String senderUsername;
  final String senderIdentityPublicKey;
  final String recipientDeviceId;

  /// For outgoing requests: the identity ID and identity public key read from
  /// the scanned QR code. A response is trusted only if it matches both.
  final String? recipientIdentityId;
  final String? recipientIdentityPublicKey;
  final String status;
  final String createdAt;
  final String updatedAt;
  const ConnectionRequest({
    required this.requestId,
    required this.senderIdentityId,
    required this.senderDeviceId,
    required this.senderUsername,
    required this.senderIdentityPublicKey,
    required this.recipientDeviceId,
    this.recipientIdentityId,
    this.recipientIdentityPublicKey,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['request_id'] = Variable<String>(requestId);
    map['sender_identity_id'] = Variable<String>(senderIdentityId);
    map['sender_device_id'] = Variable<String>(senderDeviceId);
    map['sender_username'] = Variable<String>(senderUsername);
    map['sender_identity_public_key'] = Variable<String>(
      senderIdentityPublicKey,
    );
    map['recipient_device_id'] = Variable<String>(recipientDeviceId);
    if (!nullToAbsent || recipientIdentityId != null) {
      map['recipient_identity_id'] = Variable<String>(recipientIdentityId);
    }
    if (!nullToAbsent || recipientIdentityPublicKey != null) {
      map['recipient_identity_public_key'] = Variable<String>(
        recipientIdentityPublicKey,
      );
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  ConnectionRequestsCompanion toCompanion(bool nullToAbsent) {
    return ConnectionRequestsCompanion(
      requestId: Value(requestId),
      senderIdentityId: Value(senderIdentityId),
      senderDeviceId: Value(senderDeviceId),
      senderUsername: Value(senderUsername),
      senderIdentityPublicKey: Value(senderIdentityPublicKey),
      recipientDeviceId: Value(recipientDeviceId),
      recipientIdentityId: recipientIdentityId == null && nullToAbsent
          ? const Value.absent()
          : Value(recipientIdentityId),
      recipientIdentityPublicKey:
          recipientIdentityPublicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(recipientIdentityPublicKey),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ConnectionRequest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectionRequest(
      requestId: serializer.fromJson<String>(json['requestId']),
      senderIdentityId: serializer.fromJson<String>(json['senderIdentityId']),
      senderDeviceId: serializer.fromJson<String>(json['senderDeviceId']),
      senderUsername: serializer.fromJson<String>(json['senderUsername']),
      senderIdentityPublicKey: serializer.fromJson<String>(
        json['senderIdentityPublicKey'],
      ),
      recipientDeviceId: serializer.fromJson<String>(json['recipientDeviceId']),
      recipientIdentityId: serializer.fromJson<String?>(
        json['recipientIdentityId'],
      ),
      recipientIdentityPublicKey: serializer.fromJson<String?>(
        json['recipientIdentityPublicKey'],
      ),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'requestId': serializer.toJson<String>(requestId),
      'senderIdentityId': serializer.toJson<String>(senderIdentityId),
      'senderDeviceId': serializer.toJson<String>(senderDeviceId),
      'senderUsername': serializer.toJson<String>(senderUsername),
      'senderIdentityPublicKey': serializer.toJson<String>(
        senderIdentityPublicKey,
      ),
      'recipientDeviceId': serializer.toJson<String>(recipientDeviceId),
      'recipientIdentityId': serializer.toJson<String?>(recipientIdentityId),
      'recipientIdentityPublicKey': serializer.toJson<String?>(
        recipientIdentityPublicKey,
      ),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  ConnectionRequest copyWith({
    String? requestId,
    String? senderIdentityId,
    String? senderDeviceId,
    String? senderUsername,
    String? senderIdentityPublicKey,
    String? recipientDeviceId,
    Value<String?> recipientIdentityId = const Value.absent(),
    Value<String?> recipientIdentityPublicKey = const Value.absent(),
    String? status,
    String? createdAt,
    String? updatedAt,
  }) => ConnectionRequest(
    requestId: requestId ?? this.requestId,
    senderIdentityId: senderIdentityId ?? this.senderIdentityId,
    senderDeviceId: senderDeviceId ?? this.senderDeviceId,
    senderUsername: senderUsername ?? this.senderUsername,
    senderIdentityPublicKey:
        senderIdentityPublicKey ?? this.senderIdentityPublicKey,
    recipientDeviceId: recipientDeviceId ?? this.recipientDeviceId,
    recipientIdentityId: recipientIdentityId.present
        ? recipientIdentityId.value
        : this.recipientIdentityId,
    recipientIdentityPublicKey: recipientIdentityPublicKey.present
        ? recipientIdentityPublicKey.value
        : this.recipientIdentityPublicKey,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ConnectionRequest copyWithCompanion(ConnectionRequestsCompanion data) {
    return ConnectionRequest(
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      senderIdentityId: data.senderIdentityId.present
          ? data.senderIdentityId.value
          : this.senderIdentityId,
      senderDeviceId: data.senderDeviceId.present
          ? data.senderDeviceId.value
          : this.senderDeviceId,
      senderUsername: data.senderUsername.present
          ? data.senderUsername.value
          : this.senderUsername,
      senderIdentityPublicKey: data.senderIdentityPublicKey.present
          ? data.senderIdentityPublicKey.value
          : this.senderIdentityPublicKey,
      recipientDeviceId: data.recipientDeviceId.present
          ? data.recipientDeviceId.value
          : this.recipientDeviceId,
      recipientIdentityId: data.recipientIdentityId.present
          ? data.recipientIdentityId.value
          : this.recipientIdentityId,
      recipientIdentityPublicKey: data.recipientIdentityPublicKey.present
          ? data.recipientIdentityPublicKey.value
          : this.recipientIdentityPublicKey,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionRequest(')
          ..write('requestId: $requestId, ')
          ..write('senderIdentityId: $senderIdentityId, ')
          ..write('senderDeviceId: $senderDeviceId, ')
          ..write('senderUsername: $senderUsername, ')
          ..write('senderIdentityPublicKey: $senderIdentityPublicKey, ')
          ..write('recipientDeviceId: $recipientDeviceId, ')
          ..write('recipientIdentityId: $recipientIdentityId, ')
          ..write('recipientIdentityPublicKey: $recipientIdentityPublicKey, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    requestId,
    senderIdentityId,
    senderDeviceId,
    senderUsername,
    senderIdentityPublicKey,
    recipientDeviceId,
    recipientIdentityId,
    recipientIdentityPublicKey,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectionRequest &&
          other.requestId == this.requestId &&
          other.senderIdentityId == this.senderIdentityId &&
          other.senderDeviceId == this.senderDeviceId &&
          other.senderUsername == this.senderUsername &&
          other.senderIdentityPublicKey == this.senderIdentityPublicKey &&
          other.recipientDeviceId == this.recipientDeviceId &&
          other.recipientIdentityId == this.recipientIdentityId &&
          other.recipientIdentityPublicKey == this.recipientIdentityPublicKey &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ConnectionRequestsCompanion extends UpdateCompanion<ConnectionRequest> {
  final Value<String> requestId;
  final Value<String> senderIdentityId;
  final Value<String> senderDeviceId;
  final Value<String> senderUsername;
  final Value<String> senderIdentityPublicKey;
  final Value<String> recipientDeviceId;
  final Value<String?> recipientIdentityId;
  final Value<String?> recipientIdentityPublicKey;
  final Value<String> status;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const ConnectionRequestsCompanion({
    this.requestId = const Value.absent(),
    this.senderIdentityId = const Value.absent(),
    this.senderDeviceId = const Value.absent(),
    this.senderUsername = const Value.absent(),
    this.senderIdentityPublicKey = const Value.absent(),
    this.recipientDeviceId = const Value.absent(),
    this.recipientIdentityId = const Value.absent(),
    this.recipientIdentityPublicKey = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConnectionRequestsCompanion.insert({
    required String requestId,
    required String senderIdentityId,
    required String senderDeviceId,
    required String senderUsername,
    required String senderIdentityPublicKey,
    required String recipientDeviceId,
    this.recipientIdentityId = const Value.absent(),
    this.recipientIdentityPublicKey = const Value.absent(),
    this.status = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : requestId = Value(requestId),
       senderIdentityId = Value(senderIdentityId),
       senderDeviceId = Value(senderDeviceId),
       senderUsername = Value(senderUsername),
       senderIdentityPublicKey = Value(senderIdentityPublicKey),
       recipientDeviceId = Value(recipientDeviceId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ConnectionRequest> custom({
    Expression<String>? requestId,
    Expression<String>? senderIdentityId,
    Expression<String>? senderDeviceId,
    Expression<String>? senderUsername,
    Expression<String>? senderIdentityPublicKey,
    Expression<String>? recipientDeviceId,
    Expression<String>? recipientIdentityId,
    Expression<String>? recipientIdentityPublicKey,
    Expression<String>? status,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (requestId != null) 'request_id': requestId,
      if (senderIdentityId != null) 'sender_identity_id': senderIdentityId,
      if (senderDeviceId != null) 'sender_device_id': senderDeviceId,
      if (senderUsername != null) 'sender_username': senderUsername,
      if (senderIdentityPublicKey != null)
        'sender_identity_public_key': senderIdentityPublicKey,
      if (recipientDeviceId != null) 'recipient_device_id': recipientDeviceId,
      if (recipientIdentityId != null)
        'recipient_identity_id': recipientIdentityId,
      if (recipientIdentityPublicKey != null)
        'recipient_identity_public_key': recipientIdentityPublicKey,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConnectionRequestsCompanion copyWith({
    Value<String>? requestId,
    Value<String>? senderIdentityId,
    Value<String>? senderDeviceId,
    Value<String>? senderUsername,
    Value<String>? senderIdentityPublicKey,
    Value<String>? recipientDeviceId,
    Value<String?>? recipientIdentityId,
    Value<String?>? recipientIdentityPublicKey,
    Value<String>? status,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return ConnectionRequestsCompanion(
      requestId: requestId ?? this.requestId,
      senderIdentityId: senderIdentityId ?? this.senderIdentityId,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      senderUsername: senderUsername ?? this.senderUsername,
      senderIdentityPublicKey:
          senderIdentityPublicKey ?? this.senderIdentityPublicKey,
      recipientDeviceId: recipientDeviceId ?? this.recipientDeviceId,
      recipientIdentityId: recipientIdentityId ?? this.recipientIdentityId,
      recipientIdentityPublicKey:
          recipientIdentityPublicKey ?? this.recipientIdentityPublicKey,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (senderIdentityId.present) {
      map['sender_identity_id'] = Variable<String>(senderIdentityId.value);
    }
    if (senderDeviceId.present) {
      map['sender_device_id'] = Variable<String>(senderDeviceId.value);
    }
    if (senderUsername.present) {
      map['sender_username'] = Variable<String>(senderUsername.value);
    }
    if (senderIdentityPublicKey.present) {
      map['sender_identity_public_key'] = Variable<String>(
        senderIdentityPublicKey.value,
      );
    }
    if (recipientDeviceId.present) {
      map['recipient_device_id'] = Variable<String>(recipientDeviceId.value);
    }
    if (recipientIdentityId.present) {
      map['recipient_identity_id'] = Variable<String>(
        recipientIdentityId.value,
      );
    }
    if (recipientIdentityPublicKey.present) {
      map['recipient_identity_public_key'] = Variable<String>(
        recipientIdentityPublicKey.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionRequestsCompanion(')
          ..write('requestId: $requestId, ')
          ..write('senderIdentityId: $senderIdentityId, ')
          ..write('senderDeviceId: $senderDeviceId, ')
          ..write('senderUsername: $senderUsername, ')
          ..write('senderIdentityPublicKey: $senderIdentityPublicKey, ')
          ..write('recipientDeviceId: $recipientDeviceId, ')
          ..write('recipientIdentityId: $recipientIdentityId, ')
          ..write('recipientIdentityPublicKey: $recipientIdentityPublicKey, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTable extends Conversations
    with TableInfo<$ConversationsTable, Conversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mlsGroupIdMeta = const VerificationMeta(
    'mlsGroupId',
  );
  @override
  late final GeneratedColumn<String> mlsGroupId = GeneratedColumn<String>(
    'mls_group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isMutedMeta = const VerificationMeta(
    'isMuted',
  );
  @override
  late final GeneratedColumn<bool> isMuted = GeneratedColumn<bool>(
    'is_muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _markedUnreadMeta = const VerificationMeta(
    'markedUnread',
  );
  @override
  late final GeneratedColumn<bool> markedUnread = GeneratedColumn<bool>(
    'marked_unread',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("marked_unread" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    conversationId,
    type,
    mlsGroupId,
    createdAt,
    updatedAt,
    isArchived,
    unreadCount,
    isMuted,
    markedUnread,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Conversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('mls_group_id')) {
      context.handle(
        _mlsGroupIdMeta,
        mlsGroupId.isAcceptableOrUnknown(
          data['mls_group_id']!,
          _mlsGroupIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mlsGroupIdMeta);
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
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('is_muted')) {
      context.handle(
        _isMutedMeta,
        isMuted.isAcceptableOrUnknown(data['is_muted']!, _isMutedMeta),
      );
    }
    if (data.containsKey('marked_unread')) {
      context.handle(
        _markedUnreadMeta,
        markedUnread.isAcceptableOrUnknown(
          data['marked_unread']!,
          _markedUnreadMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId};
  @override
  Conversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conversation(
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      mlsGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mls_group_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      isMuted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_muted'],
      )!,
      markedUnread: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}marked_unread'],
      )!,
    );
  }

  @override
  $ConversationsTable createAlias(String alias) {
    return $ConversationsTable(attachedDatabase, alias);
  }
}

class Conversation extends DataClass implements Insertable<Conversation> {
  final String conversationId;
  final String type;
  final String mlsGroupId;
  final String createdAt;
  final String updatedAt;
  final bool isArchived;
  final int unreadCount;
  final bool isMuted;
  final bool markedUnread;
  const Conversation({
    required this.conversationId,
    required this.type,
    required this.mlsGroupId,
    required this.createdAt,
    required this.updatedAt,
    required this.isArchived,
    required this.unreadCount,
    required this.isMuted,
    required this.markedUnread,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    map['type'] = Variable<String>(type);
    map['mls_group_id'] = Variable<String>(mlsGroupId);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['is_archived'] = Variable<bool>(isArchived);
    map['unread_count'] = Variable<int>(unreadCount);
    map['is_muted'] = Variable<bool>(isMuted);
    map['marked_unread'] = Variable<bool>(markedUnread);
    return map;
  }

  ConversationsCompanion toCompanion(bool nullToAbsent) {
    return ConversationsCompanion(
      conversationId: Value(conversationId),
      type: Value(type),
      mlsGroupId: Value(mlsGroupId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isArchived: Value(isArchived),
      unreadCount: Value(unreadCount),
      isMuted: Value(isMuted),
      markedUnread: Value(markedUnread),
    );
  }

  factory Conversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conversation(
      conversationId: serializer.fromJson<String>(json['conversationId']),
      type: serializer.fromJson<String>(json['type']),
      mlsGroupId: serializer.fromJson<String>(json['mlsGroupId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      isMuted: serializer.fromJson<bool>(json['isMuted']),
      markedUnread: serializer.fromJson<bool>(json['markedUnread']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversationId': serializer.toJson<String>(conversationId),
      'type': serializer.toJson<String>(type),
      'mlsGroupId': serializer.toJson<String>(mlsGroupId),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'isArchived': serializer.toJson<bool>(isArchived),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'isMuted': serializer.toJson<bool>(isMuted),
      'markedUnread': serializer.toJson<bool>(markedUnread),
    };
  }

  Conversation copyWith({
    String? conversationId,
    String? type,
    String? mlsGroupId,
    String? createdAt,
    String? updatedAt,
    bool? isArchived,
    int? unreadCount,
    bool? isMuted,
    bool? markedUnread,
  }) => Conversation(
    conversationId: conversationId ?? this.conversationId,
    type: type ?? this.type,
    mlsGroupId: mlsGroupId ?? this.mlsGroupId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isArchived: isArchived ?? this.isArchived,
    unreadCount: unreadCount ?? this.unreadCount,
    isMuted: isMuted ?? this.isMuted,
    markedUnread: markedUnread ?? this.markedUnread,
  );
  Conversation copyWithCompanion(ConversationsCompanion data) {
    return Conversation(
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      type: data.type.present ? data.type.value : this.type,
      mlsGroupId: data.mlsGroupId.present
          ? data.mlsGroupId.value
          : this.mlsGroupId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      isMuted: data.isMuted.present ? data.isMuted.value : this.isMuted,
      markedUnread: data.markedUnread.present
          ? data.markedUnread.value
          : this.markedUnread,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conversation(')
          ..write('conversationId: $conversationId, ')
          ..write('type: $type, ')
          ..write('mlsGroupId: $mlsGroupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('isMuted: $isMuted, ')
          ..write('markedUnread: $markedUnread')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    conversationId,
    type,
    mlsGroupId,
    createdAt,
    updatedAt,
    isArchived,
    unreadCount,
    isMuted,
    markedUnread,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conversation &&
          other.conversationId == this.conversationId &&
          other.type == this.type &&
          other.mlsGroupId == this.mlsGroupId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isArchived == this.isArchived &&
          other.unreadCount == this.unreadCount &&
          other.isMuted == this.isMuted &&
          other.markedUnread == this.markedUnread);
}

class ConversationsCompanion extends UpdateCompanion<Conversation> {
  final Value<String> conversationId;
  final Value<String> type;
  final Value<String> mlsGroupId;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<bool> isArchived;
  final Value<int> unreadCount;
  final Value<bool> isMuted;
  final Value<bool> markedUnread;
  final Value<int> rowid;
  const ConversationsCompanion({
    this.conversationId = const Value.absent(),
    this.type = const Value.absent(),
    this.mlsGroupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.markedUnread = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsCompanion.insert({
    required String conversationId,
    required String type,
    required String mlsGroupId,
    required String createdAt,
    required String updatedAt,
    this.isArchived = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.markedUnread = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : conversationId = Value(conversationId),
       type = Value(type),
       mlsGroupId = Value(mlsGroupId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Conversation> custom({
    Expression<String>? conversationId,
    Expression<String>? type,
    Expression<String>? mlsGroupId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<bool>? isArchived,
    Expression<int>? unreadCount,
    Expression<bool>? isMuted,
    Expression<bool>? markedUnread,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (type != null) 'type': type,
      if (mlsGroupId != null) 'mls_group_id': mlsGroupId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isArchived != null) 'is_archived': isArchived,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (isMuted != null) 'is_muted': isMuted,
      if (markedUnread != null) 'marked_unread': markedUnread,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsCompanion copyWith({
    Value<String>? conversationId,
    Value<String>? type,
    Value<String>? mlsGroupId,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<bool>? isArchived,
    Value<int>? unreadCount,
    Value<bool>? isMuted,
    Value<bool>? markedUnread,
    Value<int>? rowid,
  }) {
    return ConversationsCompanion(
      conversationId: conversationId ?? this.conversationId,
      type: type ?? this.type,
      mlsGroupId: mlsGroupId ?? this.mlsGroupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      markedUnread: markedUnread ?? this.markedUnread,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (mlsGroupId.present) {
      map['mls_group_id'] = Variable<String>(mlsGroupId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (isMuted.present) {
      map['is_muted'] = Variable<bool>(isMuted.value);
    }
    if (markedUnread.present) {
      map['marked_unread'] = Variable<bool>(markedUnread.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsCompanion(')
          ..write('conversationId: $conversationId, ')
          ..write('type: $type, ')
          ..write('mlsGroupId: $mlsGroupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('isMuted: $isMuted, ')
          ..write('markedUnread: $markedUnread, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationParticipantsTable extends ConversationParticipants
    with TableInfo<$ConversationParticipantsTable, ConversationParticipant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationParticipantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _participantIdMeta = const VerificationMeta(
    'participantId',
  );
  @override
  late final GeneratedColumn<String> participantId = GeneratedColumn<String>(
    'participant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES conversations (conversation_id)',
    ),
  );
  static const VerificationMeta _identityIdMeta = const VerificationMeta(
    'identityId',
  );
  @override
  late final GeneratedColumn<String> identityId = GeneratedColumn<String>(
    'identity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
    'contact_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contacts (contact_id)',
    ),
  );
  static const VerificationMeta _isLocalMeta = const VerificationMeta(
    'isLocal',
  );
  @override
  late final GeneratedColumn<bool> isLocal = GeneratedColumn<bool>(
    'is_local',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_local" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    participantId,
    conversationId,
    identityId,
    deviceId,
    contactId,
    isLocal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversation_participants';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationParticipant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('participant_id')) {
      context.handle(
        _participantIdMeta,
        participantId.isAcceptableOrUnknown(
          data['participant_id']!,
          _participantIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('identity_id')) {
      context.handle(
        _identityIdMeta,
        identityId.isAcceptableOrUnknown(data['identity_id']!, _identityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_identityIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    }
    if (data.containsKey('is_local')) {
      context.handle(
        _isLocalMeta,
        isLocal.isAcceptableOrUnknown(data['is_local']!, _isLocalMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {participantId};
  @override
  ConversationParticipant map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationParticipant(
      participantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      identityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_id'],
      ),
      isLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_local'],
      )!,
    );
  }

  @override
  $ConversationParticipantsTable createAlias(String alias) {
    return $ConversationParticipantsTable(attachedDatabase, alias);
  }
}

class ConversationParticipant extends DataClass
    implements Insertable<ConversationParticipant> {
  final String participantId;
  final String conversationId;
  final String identityId;
  final String deviceId;
  final String? contactId;
  final bool isLocal;
  const ConversationParticipant({
    required this.participantId,
    required this.conversationId,
    required this.identityId,
    required this.deviceId,
    this.contactId,
    required this.isLocal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['participant_id'] = Variable<String>(participantId);
    map['conversation_id'] = Variable<String>(conversationId);
    map['identity_id'] = Variable<String>(identityId);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || contactId != null) {
      map['contact_id'] = Variable<String>(contactId);
    }
    map['is_local'] = Variable<bool>(isLocal);
    return map;
  }

  ConversationParticipantsCompanion toCompanion(bool nullToAbsent) {
    return ConversationParticipantsCompanion(
      participantId: Value(participantId),
      conversationId: Value(conversationId),
      identityId: Value(identityId),
      deviceId: Value(deviceId),
      contactId: contactId == null && nullToAbsent
          ? const Value.absent()
          : Value(contactId),
      isLocal: Value(isLocal),
    );
  }

  factory ConversationParticipant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationParticipant(
      participantId: serializer.fromJson<String>(json['participantId']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      identityId: serializer.fromJson<String>(json['identityId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      contactId: serializer.fromJson<String?>(json['contactId']),
      isLocal: serializer.fromJson<bool>(json['isLocal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'participantId': serializer.toJson<String>(participantId),
      'conversationId': serializer.toJson<String>(conversationId),
      'identityId': serializer.toJson<String>(identityId),
      'deviceId': serializer.toJson<String>(deviceId),
      'contactId': serializer.toJson<String?>(contactId),
      'isLocal': serializer.toJson<bool>(isLocal),
    };
  }

  ConversationParticipant copyWith({
    String? participantId,
    String? conversationId,
    String? identityId,
    String? deviceId,
    Value<String?> contactId = const Value.absent(),
    bool? isLocal,
  }) => ConversationParticipant(
    participantId: participantId ?? this.participantId,
    conversationId: conversationId ?? this.conversationId,
    identityId: identityId ?? this.identityId,
    deviceId: deviceId ?? this.deviceId,
    contactId: contactId.present ? contactId.value : this.contactId,
    isLocal: isLocal ?? this.isLocal,
  );
  ConversationParticipant copyWithCompanion(
    ConversationParticipantsCompanion data,
  ) {
    return ConversationParticipant(
      participantId: data.participantId.present
          ? data.participantId.value
          : this.participantId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      identityId: data.identityId.present
          ? data.identityId.value
          : this.identityId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      isLocal: data.isLocal.present ? data.isLocal.value : this.isLocal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationParticipant(')
          ..write('participantId: $participantId, ')
          ..write('conversationId: $conversationId, ')
          ..write('identityId: $identityId, ')
          ..write('deviceId: $deviceId, ')
          ..write('contactId: $contactId, ')
          ..write('isLocal: $isLocal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    participantId,
    conversationId,
    identityId,
    deviceId,
    contactId,
    isLocal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationParticipant &&
          other.participantId == this.participantId &&
          other.conversationId == this.conversationId &&
          other.identityId == this.identityId &&
          other.deviceId == this.deviceId &&
          other.contactId == this.contactId &&
          other.isLocal == this.isLocal);
}

class ConversationParticipantsCompanion
    extends UpdateCompanion<ConversationParticipant> {
  final Value<String> participantId;
  final Value<String> conversationId;
  final Value<String> identityId;
  final Value<String> deviceId;
  final Value<String?> contactId;
  final Value<bool> isLocal;
  final Value<int> rowid;
  const ConversationParticipantsCompanion({
    this.participantId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.identityId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.isLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationParticipantsCompanion.insert({
    required String participantId,
    required String conversationId,
    required String identityId,
    required String deviceId,
    this.contactId = const Value.absent(),
    this.isLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : participantId = Value(participantId),
       conversationId = Value(conversationId),
       identityId = Value(identityId),
       deviceId = Value(deviceId);
  static Insertable<ConversationParticipant> custom({
    Expression<String>? participantId,
    Expression<String>? conversationId,
    Expression<String>? identityId,
    Expression<String>? deviceId,
    Expression<String>? contactId,
    Expression<bool>? isLocal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (participantId != null) 'participant_id': participantId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (identityId != null) 'identity_id': identityId,
      if (deviceId != null) 'device_id': deviceId,
      if (contactId != null) 'contact_id': contactId,
      if (isLocal != null) 'is_local': isLocal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationParticipantsCompanion copyWith({
    Value<String>? participantId,
    Value<String>? conversationId,
    Value<String>? identityId,
    Value<String>? deviceId,
    Value<String?>? contactId,
    Value<bool>? isLocal,
    Value<int>? rowid,
  }) {
    return ConversationParticipantsCompanion(
      participantId: participantId ?? this.participantId,
      conversationId: conversationId ?? this.conversationId,
      identityId: identityId ?? this.identityId,
      deviceId: deviceId ?? this.deviceId,
      contactId: contactId ?? this.contactId,
      isLocal: isLocal ?? this.isLocal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (participantId.present) {
      map['participant_id'] = Variable<String>(participantId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (identityId.present) {
      map['identity_id'] = Variable<String>(identityId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (isLocal.present) {
      map['is_local'] = Variable<bool>(isLocal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationParticipantsCompanion(')
          ..write('participantId: $participantId, ')
          ..write('conversationId: $conversationId, ')
          ..write('identityId: $identityId, ')
          ..write('deviceId: $deviceId, ')
          ..write('contactId: $contactId, ')
          ..write('isLocal: $isLocal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES conversations (conversation_id)',
    ),
  );
  static const VerificationMeta _senderDeviceIdMeta = const VerificationMeta(
    'senderDeviceId',
  );
  @override
  late final GeneratedColumn<String> senderDeviceId = GeneratedColumn<String>(
    'sender_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedEnvelopeMeta = const VerificationMeta(
    'encryptedEnvelope',
  );
  @override
  late final GeneratedColumn<Uint8List> encryptedEnvelope =
      GeneratedColumn<Uint8List>(
        'encrypted_envelope',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _localDisplayCiphertextMeta =
      const VerificationMeta('localDisplayCiphertext');
  @override
  late final GeneratedColumn<Uint8List> localDisplayCiphertext =
      GeneratedColumn<Uint8List>(
        'local_display_ciphertext',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _deliveryStateMeta = const VerificationMeta(
    'deliveryState',
  );
  @override
  late final GeneratedColumn<String> deliveryState = GeneratedColumn<String>(
    'delivery_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isStarredMeta = const VerificationMeta(
    'isStarred',
  );
  @override
  late final GeneratedColumn<bool> isStarred = GeneratedColumn<bool>(
    'is_starred',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_starred" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<String> editedAt = GeneratedColumn<String>(
    'edited_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    conversationId,
    senderDeviceId,
    createdAt,
    encryptedEnvelope,
    localDisplayCiphertext,
    deliveryState,
    isRead,
    retryCount,
    isStarred,
    isPinned,
    isDeleted,
    editedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('sender_device_id')) {
      context.handle(
        _senderDeviceIdMeta,
        senderDeviceId.isAcceptableOrUnknown(
          data['sender_device_id']!,
          _senderDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_senderDeviceIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('encrypted_envelope')) {
      context.handle(
        _encryptedEnvelopeMeta,
        encryptedEnvelope.isAcceptableOrUnknown(
          data['encrypted_envelope']!,
          _encryptedEnvelopeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedEnvelopeMeta);
    }
    if (data.containsKey('local_display_ciphertext')) {
      context.handle(
        _localDisplayCiphertextMeta,
        localDisplayCiphertext.isAcceptableOrUnknown(
          data['local_display_ciphertext']!,
          _localDisplayCiphertextMeta,
        ),
      );
    }
    if (data.containsKey('delivery_state')) {
      context.handle(
        _deliveryStateMeta,
        deliveryState.isAcceptableOrUnknown(
          data['delivery_state']!,
          _deliveryStateMeta,
        ),
      );
    }
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('is_starred')) {
      context.handle(
        _isStarredMeta,
        isStarred.isAcceptableOrUnknown(data['is_starred']!, _isStarredMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      senderDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_device_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      encryptedEnvelope: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_envelope'],
      )!,
      localDisplayCiphertext: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}local_display_ciphertext'],
      ),
      deliveryState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_state'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      isStarred: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_starred'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edited_at'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final String messageId;
  final String conversationId;
  final String senderDeviceId;
  final String createdAt;
  final Uint8List encryptedEnvelope;
  final Uint8List? localDisplayCiphertext;
  final String deliveryState;
  final bool isRead;
  final int retryCount;
  final bool isStarred;
  final bool isPinned;
  final bool isDeleted;
  final String? editedAt;
  const Message({
    required this.messageId,
    required this.conversationId,
    required this.senderDeviceId,
    required this.createdAt,
    required this.encryptedEnvelope,
    this.localDisplayCiphertext,
    required this.deliveryState,
    required this.isRead,
    required this.retryCount,
    required this.isStarred,
    required this.isPinned,
    required this.isDeleted,
    this.editedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['conversation_id'] = Variable<String>(conversationId);
    map['sender_device_id'] = Variable<String>(senderDeviceId);
    map['created_at'] = Variable<String>(createdAt);
    map['encrypted_envelope'] = Variable<Uint8List>(encryptedEnvelope);
    if (!nullToAbsent || localDisplayCiphertext != null) {
      map['local_display_ciphertext'] = Variable<Uint8List>(
        localDisplayCiphertext,
      );
    }
    map['delivery_state'] = Variable<String>(deliveryState);
    map['is_read'] = Variable<bool>(isRead);
    map['retry_count'] = Variable<int>(retryCount);
    map['is_starred'] = Variable<bool>(isStarred);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<String>(editedAt);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      messageId: Value(messageId),
      conversationId: Value(conversationId),
      senderDeviceId: Value(senderDeviceId),
      createdAt: Value(createdAt),
      encryptedEnvelope: Value(encryptedEnvelope),
      localDisplayCiphertext: localDisplayCiphertext == null && nullToAbsent
          ? const Value.absent()
          : Value(localDisplayCiphertext),
      deliveryState: Value(deliveryState),
      isRead: Value(isRead),
      retryCount: Value(retryCount),
      isStarred: Value(isStarred),
      isPinned: Value(isPinned),
      isDeleted: Value(isDeleted),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      messageId: serializer.fromJson<String>(json['messageId']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      senderDeviceId: serializer.fromJson<String>(json['senderDeviceId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      encryptedEnvelope: serializer.fromJson<Uint8List>(
        json['encryptedEnvelope'],
      ),
      localDisplayCiphertext: serializer.fromJson<Uint8List?>(
        json['localDisplayCiphertext'],
      ),
      deliveryState: serializer.fromJson<String>(json['deliveryState']),
      isRead: serializer.fromJson<bool>(json['isRead']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      isStarred: serializer.fromJson<bool>(json['isStarred']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      editedAt: serializer.fromJson<String?>(json['editedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'conversationId': serializer.toJson<String>(conversationId),
      'senderDeviceId': serializer.toJson<String>(senderDeviceId),
      'createdAt': serializer.toJson<String>(createdAt),
      'encryptedEnvelope': serializer.toJson<Uint8List>(encryptedEnvelope),
      'localDisplayCiphertext': serializer.toJson<Uint8List?>(
        localDisplayCiphertext,
      ),
      'deliveryState': serializer.toJson<String>(deliveryState),
      'isRead': serializer.toJson<bool>(isRead),
      'retryCount': serializer.toJson<int>(retryCount),
      'isStarred': serializer.toJson<bool>(isStarred),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'editedAt': serializer.toJson<String?>(editedAt),
    };
  }

  Message copyWith({
    String? messageId,
    String? conversationId,
    String? senderDeviceId,
    String? createdAt,
    Uint8List? encryptedEnvelope,
    Value<Uint8List?> localDisplayCiphertext = const Value.absent(),
    String? deliveryState,
    bool? isRead,
    int? retryCount,
    bool? isStarred,
    bool? isPinned,
    bool? isDeleted,
    Value<String?> editedAt = const Value.absent(),
  }) => Message(
    messageId: messageId ?? this.messageId,
    conversationId: conversationId ?? this.conversationId,
    senderDeviceId: senderDeviceId ?? this.senderDeviceId,
    createdAt: createdAt ?? this.createdAt,
    encryptedEnvelope: encryptedEnvelope ?? this.encryptedEnvelope,
    localDisplayCiphertext: localDisplayCiphertext.present
        ? localDisplayCiphertext.value
        : this.localDisplayCiphertext,
    deliveryState: deliveryState ?? this.deliveryState,
    isRead: isRead ?? this.isRead,
    retryCount: retryCount ?? this.retryCount,
    isStarred: isStarred ?? this.isStarred,
    isPinned: isPinned ?? this.isPinned,
    isDeleted: isDeleted ?? this.isDeleted,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      senderDeviceId: data.senderDeviceId.present
          ? data.senderDeviceId.value
          : this.senderDeviceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      encryptedEnvelope: data.encryptedEnvelope.present
          ? data.encryptedEnvelope.value
          : this.encryptedEnvelope,
      localDisplayCiphertext: data.localDisplayCiphertext.present
          ? data.localDisplayCiphertext.value
          : this.localDisplayCiphertext,
      deliveryState: data.deliveryState.present
          ? data.deliveryState.value
          : this.deliveryState,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      isStarred: data.isStarred.present ? data.isStarred.value : this.isStarred,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderDeviceId: $senderDeviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('encryptedEnvelope: $encryptedEnvelope, ')
          ..write('localDisplayCiphertext: $localDisplayCiphertext, ')
          ..write('deliveryState: $deliveryState, ')
          ..write('isRead: $isRead, ')
          ..write('retryCount: $retryCount, ')
          ..write('isStarred: $isStarred, ')
          ..write('isPinned: $isPinned, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    messageId,
    conversationId,
    senderDeviceId,
    createdAt,
    $driftBlobEquality.hash(encryptedEnvelope),
    $driftBlobEquality.hash(localDisplayCiphertext),
    deliveryState,
    isRead,
    retryCount,
    isStarred,
    isPinned,
    isDeleted,
    editedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.messageId == this.messageId &&
          other.conversationId == this.conversationId &&
          other.senderDeviceId == this.senderDeviceId &&
          other.createdAt == this.createdAt &&
          $driftBlobEquality.equals(
            other.encryptedEnvelope,
            this.encryptedEnvelope,
          ) &&
          $driftBlobEquality.equals(
            other.localDisplayCiphertext,
            this.localDisplayCiphertext,
          ) &&
          other.deliveryState == this.deliveryState &&
          other.isRead == this.isRead &&
          other.retryCount == this.retryCount &&
          other.isStarred == this.isStarred &&
          other.isPinned == this.isPinned &&
          other.isDeleted == this.isDeleted &&
          other.editedAt == this.editedAt);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<String> messageId;
  final Value<String> conversationId;
  final Value<String> senderDeviceId;
  final Value<String> createdAt;
  final Value<Uint8List> encryptedEnvelope;
  final Value<Uint8List?> localDisplayCiphertext;
  final Value<String> deliveryState;
  final Value<bool> isRead;
  final Value<int> retryCount;
  final Value<bool> isStarred;
  final Value<bool> isPinned;
  final Value<bool> isDeleted;
  final Value<String?> editedAt;
  final Value<int> rowid;
  const MessagesCompanion({
    this.messageId = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.senderDeviceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.encryptedEnvelope = const Value.absent(),
    this.localDisplayCiphertext = const Value.absent(),
    this.deliveryState = const Value.absent(),
    this.isRead = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesCompanion.insert({
    required String messageId,
    required String conversationId,
    required String senderDeviceId,
    required String createdAt,
    required Uint8List encryptedEnvelope,
    this.localDisplayCiphertext = const Value.absent(),
    this.deliveryState = const Value.absent(),
    this.isRead = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.isStarred = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       conversationId = Value(conversationId),
       senderDeviceId = Value(senderDeviceId),
       createdAt = Value(createdAt),
       encryptedEnvelope = Value(encryptedEnvelope);
  static Insertable<Message> custom({
    Expression<String>? messageId,
    Expression<String>? conversationId,
    Expression<String>? senderDeviceId,
    Expression<String>? createdAt,
    Expression<Uint8List>? encryptedEnvelope,
    Expression<Uint8List>? localDisplayCiphertext,
    Expression<String>? deliveryState,
    Expression<bool>? isRead,
    Expression<int>? retryCount,
    Expression<bool>? isStarred,
    Expression<bool>? isPinned,
    Expression<bool>? isDeleted,
    Expression<String>? editedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (conversationId != null) 'conversation_id': conversationId,
      if (senderDeviceId != null) 'sender_device_id': senderDeviceId,
      if (createdAt != null) 'created_at': createdAt,
      if (encryptedEnvelope != null) 'encrypted_envelope': encryptedEnvelope,
      if (localDisplayCiphertext != null)
        'local_display_ciphertext': localDisplayCiphertext,
      if (deliveryState != null) 'delivery_state': deliveryState,
      if (isRead != null) 'is_read': isRead,
      if (retryCount != null) 'retry_count': retryCount,
      if (isStarred != null) 'is_starred': isStarred,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (editedAt != null) 'edited_at': editedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesCompanion copyWith({
    Value<String>? messageId,
    Value<String>? conversationId,
    Value<String>? senderDeviceId,
    Value<String>? createdAt,
    Value<Uint8List>? encryptedEnvelope,
    Value<Uint8List?>? localDisplayCiphertext,
    Value<String>? deliveryState,
    Value<bool>? isRead,
    Value<int>? retryCount,
    Value<bool>? isStarred,
    Value<bool>? isPinned,
    Value<bool>? isDeleted,
    Value<String?>? editedAt,
    Value<int>? rowid,
  }) {
    return MessagesCompanion(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      createdAt: createdAt ?? this.createdAt,
      encryptedEnvelope: encryptedEnvelope ?? this.encryptedEnvelope,
      localDisplayCiphertext:
          localDisplayCiphertext ?? this.localDisplayCiphertext,
      deliveryState: deliveryState ?? this.deliveryState,
      isRead: isRead ?? this.isRead,
      retryCount: retryCount ?? this.retryCount,
      isStarred: isStarred ?? this.isStarred,
      isPinned: isPinned ?? this.isPinned,
      isDeleted: isDeleted ?? this.isDeleted,
      editedAt: editedAt ?? this.editedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (senderDeviceId.present) {
      map['sender_device_id'] = Variable<String>(senderDeviceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (encryptedEnvelope.present) {
      map['encrypted_envelope'] = Variable<Uint8List>(encryptedEnvelope.value);
    }
    if (localDisplayCiphertext.present) {
      map['local_display_ciphertext'] = Variable<Uint8List>(
        localDisplayCiphertext.value,
      );
    }
    if (deliveryState.present) {
      map['delivery_state'] = Variable<String>(deliveryState.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (isStarred.present) {
      map['is_starred'] = Variable<bool>(isStarred.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<String>(editedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('messageId: $messageId, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderDeviceId: $senderDeviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('encryptedEnvelope: $encryptedEnvelope, ')
          ..write('localDisplayCiphertext: $localDisplayCiphertext, ')
          ..write('deliveryState: $deliveryState, ')
          ..write('isRead: $isRead, ')
          ..write('retryCount: $retryCount, ')
          ..write('isStarred: $isStarred, ')
          ..write('isPinned: $isPinned, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('editedAt: $editedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  @override
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
    'attachment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES messages (message_id)',
    ),
  );
  static const VerificationMeta _encryptedStorageReferenceMeta =
      const VerificationMeta('encryptedStorageReference');
  @override
  late final GeneratedColumn<String> encryptedStorageReference =
      GeneratedColumn<String>(
        'encrypted_storage_reference',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _encryptedMetadataMeta = const VerificationMeta(
    'encryptedMetadata',
  );
  @override
  late final GeneratedColumn<Uint8List> encryptedMetadata =
      GeneratedColumn<Uint8List>(
        'encrypted_metadata',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferStateMeta = const VerificationMeta(
    'transferState',
  );
  @override
  late final GeneratedColumn<String> transferState = GeneratedColumn<String>(
    'transfer_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _integrityHashMeta = const VerificationMeta(
    'integrityHash',
  );
  @override
  late final GeneratedColumn<String> integrityHash = GeneratedColumn<String>(
    'integrity_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    attachmentId,
    messageId,
    encryptedStorageReference,
    encryptedMetadata,
    sizeBytes,
    mediaType,
    transferState,
    integrityHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    }
    if (data.containsKey('encrypted_storage_reference')) {
      context.handle(
        _encryptedStorageReferenceMeta,
        encryptedStorageReference.isAcceptableOrUnknown(
          data['encrypted_storage_reference']!,
          _encryptedStorageReferenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedStorageReferenceMeta);
    }
    if (data.containsKey('encrypted_metadata')) {
      context.handle(
        _encryptedMetadataMeta,
        encryptedMetadata.isAcceptableOrUnknown(
          data['encrypted_metadata']!,
          _encryptedMetadataMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedMetadataMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('transfer_state')) {
      context.handle(
        _transferStateMeta,
        transferState.isAcceptableOrUnknown(
          data['transfer_state']!,
          _transferStateMeta,
        ),
      );
    }
    if (data.containsKey('integrity_hash')) {
      context.handle(
        _integrityHashMeta,
        integrityHash.isAcceptableOrUnknown(
          data['integrity_hash']!,
          _integrityHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_integrityHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attachmentId};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      attachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      ),
      encryptedStorageReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_storage_reference'],
      )!,
      encryptedMetadata: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_metadata'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      transferState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_state'],
      )!,
      integrityHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}integrity_hash'],
      )!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final String attachmentId;
  final String? messageId;
  final String encryptedStorageReference;
  final Uint8List encryptedMetadata;
  final int sizeBytes;
  final String mediaType;
  final String transferState;
  final String integrityHash;
  const Attachment({
    required this.attachmentId,
    this.messageId,
    required this.encryptedStorageReference,
    required this.encryptedMetadata,
    required this.sizeBytes,
    required this.mediaType,
    required this.transferState,
    required this.integrityHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attachment_id'] = Variable<String>(attachmentId);
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    map['encrypted_storage_reference'] = Variable<String>(
      encryptedStorageReference,
    );
    map['encrypted_metadata'] = Variable<Uint8List>(encryptedMetadata);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['media_type'] = Variable<String>(mediaType);
    map['transfer_state'] = Variable<String>(transferState);
    map['integrity_hash'] = Variable<String>(integrityHash);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      attachmentId: Value(attachmentId),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      encryptedStorageReference: Value(encryptedStorageReference),
      encryptedMetadata: Value(encryptedMetadata),
      sizeBytes: Value(sizeBytes),
      mediaType: Value(mediaType),
      transferState: Value(transferState),
      integrityHash: Value(integrityHash),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      attachmentId: serializer.fromJson<String>(json['attachmentId']),
      messageId: serializer.fromJson<String?>(json['messageId']),
      encryptedStorageReference: serializer.fromJson<String>(
        json['encryptedStorageReference'],
      ),
      encryptedMetadata: serializer.fromJson<Uint8List>(
        json['encryptedMetadata'],
      ),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      transferState: serializer.fromJson<String>(json['transferState']),
      integrityHash: serializer.fromJson<String>(json['integrityHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attachmentId': serializer.toJson<String>(attachmentId),
      'messageId': serializer.toJson<String?>(messageId),
      'encryptedStorageReference': serializer.toJson<String>(
        encryptedStorageReference,
      ),
      'encryptedMetadata': serializer.toJson<Uint8List>(encryptedMetadata),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'mediaType': serializer.toJson<String>(mediaType),
      'transferState': serializer.toJson<String>(transferState),
      'integrityHash': serializer.toJson<String>(integrityHash),
    };
  }

  Attachment copyWith({
    String? attachmentId,
    Value<String?> messageId = const Value.absent(),
    String? encryptedStorageReference,
    Uint8List? encryptedMetadata,
    int? sizeBytes,
    String? mediaType,
    String? transferState,
    String? integrityHash,
  }) => Attachment(
    attachmentId: attachmentId ?? this.attachmentId,
    messageId: messageId.present ? messageId.value : this.messageId,
    encryptedStorageReference:
        encryptedStorageReference ?? this.encryptedStorageReference,
    encryptedMetadata: encryptedMetadata ?? this.encryptedMetadata,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    mediaType: mediaType ?? this.mediaType,
    transferState: transferState ?? this.transferState,
    integrityHash: integrityHash ?? this.integrityHash,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      encryptedStorageReference: data.encryptedStorageReference.present
          ? data.encryptedStorageReference.value
          : this.encryptedStorageReference,
      encryptedMetadata: data.encryptedMetadata.present
          ? data.encryptedMetadata.value
          : this.encryptedMetadata,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      transferState: data.transferState.present
          ? data.transferState.value
          : this.transferState,
      integrityHash: data.integrityHash.present
          ? data.integrityHash.value
          : this.integrityHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('attachmentId: $attachmentId, ')
          ..write('messageId: $messageId, ')
          ..write('encryptedStorageReference: $encryptedStorageReference, ')
          ..write('encryptedMetadata: $encryptedMetadata, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('mediaType: $mediaType, ')
          ..write('transferState: $transferState, ')
          ..write('integrityHash: $integrityHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    attachmentId,
    messageId,
    encryptedStorageReference,
    $driftBlobEquality.hash(encryptedMetadata),
    sizeBytes,
    mediaType,
    transferState,
    integrityHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.attachmentId == this.attachmentId &&
          other.messageId == this.messageId &&
          other.encryptedStorageReference == this.encryptedStorageReference &&
          $driftBlobEquality.equals(
            other.encryptedMetadata,
            this.encryptedMetadata,
          ) &&
          other.sizeBytes == this.sizeBytes &&
          other.mediaType == this.mediaType &&
          other.transferState == this.transferState &&
          other.integrityHash == this.integrityHash);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> attachmentId;
  final Value<String?> messageId;
  final Value<String> encryptedStorageReference;
  final Value<Uint8List> encryptedMetadata;
  final Value<int> sizeBytes;
  final Value<String> mediaType;
  final Value<String> transferState;
  final Value<String> integrityHash;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.attachmentId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.encryptedStorageReference = const Value.absent(),
    this.encryptedMetadata = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.transferState = const Value.absent(),
    this.integrityHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String attachmentId,
    this.messageId = const Value.absent(),
    required String encryptedStorageReference,
    required Uint8List encryptedMetadata,
    required int sizeBytes,
    required String mediaType,
    this.transferState = const Value.absent(),
    required String integrityHash,
    this.rowid = const Value.absent(),
  }) : attachmentId = Value(attachmentId),
       encryptedStorageReference = Value(encryptedStorageReference),
       encryptedMetadata = Value(encryptedMetadata),
       sizeBytes = Value(sizeBytes),
       mediaType = Value(mediaType),
       integrityHash = Value(integrityHash);
  static Insertable<Attachment> custom({
    Expression<String>? attachmentId,
    Expression<String>? messageId,
    Expression<String>? encryptedStorageReference,
    Expression<Uint8List>? encryptedMetadata,
    Expression<int>? sizeBytes,
    Expression<String>? mediaType,
    Expression<String>? transferState,
    Expression<String>? integrityHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (messageId != null) 'message_id': messageId,
      if (encryptedStorageReference != null)
        'encrypted_storage_reference': encryptedStorageReference,
      if (encryptedMetadata != null) 'encrypted_metadata': encryptedMetadata,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (mediaType != null) 'media_type': mediaType,
      if (transferState != null) 'transfer_state': transferState,
      if (integrityHash != null) 'integrity_hash': integrityHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? attachmentId,
    Value<String?>? messageId,
    Value<String>? encryptedStorageReference,
    Value<Uint8List>? encryptedMetadata,
    Value<int>? sizeBytes,
    Value<String>? mediaType,
    Value<String>? transferState,
    Value<String>? integrityHash,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      attachmentId: attachmentId ?? this.attachmentId,
      messageId: messageId ?? this.messageId,
      encryptedStorageReference:
          encryptedStorageReference ?? this.encryptedStorageReference,
      encryptedMetadata: encryptedMetadata ?? this.encryptedMetadata,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mediaType: mediaType ?? this.mediaType,
      transferState: transferState ?? this.transferState,
      integrityHash: integrityHash ?? this.integrityHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (encryptedStorageReference.present) {
      map['encrypted_storage_reference'] = Variable<String>(
        encryptedStorageReference.value,
      );
    }
    if (encryptedMetadata.present) {
      map['encrypted_metadata'] = Variable<Uint8List>(encryptedMetadata.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (transferState.present) {
      map['transfer_state'] = Variable<String>(transferState.value);
    }
    if (integrityHash.present) {
      map['integrity_hash'] = Variable<String>(integrityHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('attachmentId: $attachmentId, ')
          ..write('messageId: $messageId, ')
          ..write('encryptedStorageReference: $encryptedStorageReference, ')
          ..write('encryptedMetadata: $encryptedMetadata, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('mediaType: $mediaType, ')
          ..write('transferState: $transferState, ')
          ..write('integrityHash: $integrityHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReactionsTable extends Reactions
    with TableInfo<$ReactionsTable, Reaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reactorDeviceIdMeta = const VerificationMeta(
    'reactorDeviceId',
  );
  @override
  late final GeneratedColumn<String> reactorDeviceId = GeneratedColumn<String>(
    'reactor_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    reactorDeviceId,
    emoji,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('reactor_device_id')) {
      context.handle(
        _reactorDeviceIdMeta,
        reactorDeviceId.isAcceptableOrUnknown(
          data['reactor_device_id']!,
          _reactorDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reactorDeviceIdMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId, reactorDeviceId};
  @override
  Reaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reaction(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      reactorDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reactor_device_id'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReactionsTable createAlias(String alias) {
    return $ReactionsTable(attachedDatabase, alias);
  }
}

class Reaction extends DataClass implements Insertable<Reaction> {
  final String messageId;
  final String reactorDeviceId;
  final String emoji;
  final String updatedAt;
  const Reaction({
    required this.messageId,
    required this.reactorDeviceId,
    required this.emoji,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['reactor_device_id'] = Variable<String>(reactorDeviceId);
    map['emoji'] = Variable<String>(emoji);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  ReactionsCompanion toCompanion(bool nullToAbsent) {
    return ReactionsCompanion(
      messageId: Value(messageId),
      reactorDeviceId: Value(reactorDeviceId),
      emoji: Value(emoji),
      updatedAt: Value(updatedAt),
    );
  }

  factory Reaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reaction(
      messageId: serializer.fromJson<String>(json['messageId']),
      reactorDeviceId: serializer.fromJson<String>(json['reactorDeviceId']),
      emoji: serializer.fromJson<String>(json['emoji']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'reactorDeviceId': serializer.toJson<String>(reactorDeviceId),
      'emoji': serializer.toJson<String>(emoji),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Reaction copyWith({
    String? messageId,
    String? reactorDeviceId,
    String? emoji,
    String? updatedAt,
  }) => Reaction(
    messageId: messageId ?? this.messageId,
    reactorDeviceId: reactorDeviceId ?? this.reactorDeviceId,
    emoji: emoji ?? this.emoji,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Reaction copyWithCompanion(ReactionsCompanion data) {
    return Reaction(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      reactorDeviceId: data.reactorDeviceId.present
          ? data.reactorDeviceId.value
          : this.reactorDeviceId,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reaction(')
          ..write('messageId: $messageId, ')
          ..write('reactorDeviceId: $reactorDeviceId, ')
          ..write('emoji: $emoji, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(messageId, reactorDeviceId, emoji, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reaction &&
          other.messageId == this.messageId &&
          other.reactorDeviceId == this.reactorDeviceId &&
          other.emoji == this.emoji &&
          other.updatedAt == this.updatedAt);
}

class ReactionsCompanion extends UpdateCompanion<Reaction> {
  final Value<String> messageId;
  final Value<String> reactorDeviceId;
  final Value<String> emoji;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const ReactionsCompanion({
    this.messageId = const Value.absent(),
    this.reactorDeviceId = const Value.absent(),
    this.emoji = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReactionsCompanion.insert({
    required String messageId,
    required String reactorDeviceId,
    required String emoji,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       reactorDeviceId = Value(reactorDeviceId),
       emoji = Value(emoji),
       updatedAt = Value(updatedAt);
  static Insertable<Reaction> custom({
    Expression<String>? messageId,
    Expression<String>? reactorDeviceId,
    Expression<String>? emoji,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (reactorDeviceId != null) 'reactor_device_id': reactorDeviceId,
      if (emoji != null) 'emoji': emoji,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReactionsCompanion copyWith({
    Value<String>? messageId,
    Value<String>? reactorDeviceId,
    Value<String>? emoji,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReactionsCompanion(
      messageId: messageId ?? this.messageId,
      reactorDeviceId: reactorDeviceId ?? this.reactorDeviceId,
      emoji: emoji ?? this.emoji,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (reactorDeviceId.present) {
      map['reactor_device_id'] = Variable<String>(reactorDeviceId.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReactionsCompanion(')
          ..write('messageId: $messageId, ')
          ..write('reactorDeviceId: $reactorDeviceId, ')
          ..write('emoji: $emoji, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _outboxIdMeta = const VerificationMeta(
    'outboxId',
  );
  @override
  late final GeneratedColumn<String> outboxId = GeneratedColumn<String>(
    'outbox_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<String> contactId = GeneratedColumn<String>(
    'contact_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sealedFieldsMeta = const VerificationMeta(
    'sealedFields',
  );
  @override
  late final GeneratedColumn<Uint8List> sealedFields =
      GeneratedColumn<Uint8List>(
        'sealed_fields',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    outboxId,
    contactId,
    sealedFields,
    createdAt,
    attempts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('outbox_id')) {
      context.handle(
        _outboxIdMeta,
        outboxId.isAcceptableOrUnknown(data['outbox_id']!, _outboxIdMeta),
      );
    } else if (isInserting) {
      context.missing(_outboxIdMeta);
    }
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('sealed_fields')) {
      context.handle(
        _sealedFieldsMeta,
        sealedFields.isAcceptableOrUnknown(
          data['sealed_fields']!,
          _sealedFieldsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sealedFieldsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {outboxId};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      outboxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outbox_id'],
      )!,
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_id'],
      )!,
      sealedFields: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}sealed_fields'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  final String outboxId;
  final String contactId;
  final Uint8List sealedFields;
  final String createdAt;
  final int attempts;
  const OutboxData({
    required this.outboxId,
    required this.contactId,
    required this.sealedFields,
    required this.createdAt,
    required this.attempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['outbox_id'] = Variable<String>(outboxId);
    map['contact_id'] = Variable<String>(contactId);
    map['sealed_fields'] = Variable<Uint8List>(sealedFields);
    map['created_at'] = Variable<String>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      outboxId: Value(outboxId),
      contactId: Value(contactId),
      sealedFields: Value(sealedFields),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      outboxId: serializer.fromJson<String>(json['outboxId']),
      contactId: serializer.fromJson<String>(json['contactId']),
      sealedFields: serializer.fromJson<Uint8List>(json['sealedFields']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'outboxId': serializer.toJson<String>(outboxId),
      'contactId': serializer.toJson<String>(contactId),
      'sealedFields': serializer.toJson<Uint8List>(sealedFields),
      'createdAt': serializer.toJson<String>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  OutboxData copyWith({
    String? outboxId,
    String? contactId,
    Uint8List? sealedFields,
    String? createdAt,
    int? attempts,
  }) => OutboxData(
    outboxId: outboxId ?? this.outboxId,
    contactId: contactId ?? this.contactId,
    sealedFields: sealedFields ?? this.sealedFields,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      outboxId: data.outboxId.present ? data.outboxId.value : this.outboxId,
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      sealedFields: data.sealedFields.present
          ? data.sealedFields.value
          : this.sealedFields,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('outboxId: $outboxId, ')
          ..write('contactId: $contactId, ')
          ..write('sealedFields: $sealedFields, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    outboxId,
    contactId,
    $driftBlobEquality.hash(sealedFields),
    createdAt,
    attempts,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.outboxId == this.outboxId &&
          other.contactId == this.contactId &&
          $driftBlobEquality.equals(other.sealedFields, this.sealedFields) &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<String> outboxId;
  final Value<String> contactId;
  final Value<Uint8List> sealedFields;
  final Value<String> createdAt;
  final Value<int> attempts;
  final Value<int> rowid;
  const OutboxCompanion({
    this.outboxId = const Value.absent(),
    this.contactId = const Value.absent(),
    this.sealedFields = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String outboxId,
    required String contactId,
    required Uint8List sealedFields,
    required String createdAt,
    this.attempts = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : outboxId = Value(outboxId),
       contactId = Value(contactId),
       sealedFields = Value(sealedFields),
       createdAt = Value(createdAt);
  static Insertable<OutboxData> custom({
    Expression<String>? outboxId,
    Expression<String>? contactId,
    Expression<Uint8List>? sealedFields,
    Expression<String>? createdAt,
    Expression<int>? attempts,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (outboxId != null) 'outbox_id': outboxId,
      if (contactId != null) 'contact_id': contactId,
      if (sealedFields != null) 'sealed_fields': sealedFields,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? outboxId,
    Value<String>? contactId,
    Value<Uint8List>? sealedFields,
    Value<String>? createdAt,
    Value<int>? attempts,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      outboxId: outboxId ?? this.outboxId,
      contactId: contactId ?? this.contactId,
      sealedFields: sealedFields ?? this.sealedFields,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (outboxId.present) {
      map['outbox_id'] = Variable<String>(outboxId.value);
    }
    if (contactId.present) {
      map['contact_id'] = Variable<String>(contactId.value);
    }
    if (sealedFields.present) {
      map['sealed_fields'] = Variable<Uint8List>(sealedFields.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('outboxId: $outboxId, ')
          ..write('contactId: $contactId, ')
          ..write('sealedFields: $sealedFields, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeyaGroupsTable extends MeyaGroups
    with TableInfo<$MeyaGroupsTable, MeyaGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeyaGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adminDeviceIdMeta = const VerificationMeta(
    'adminDeviceId',
  );
  @override
  late final GeneratedColumn<String> adminDeviceId = GeneratedColumn<String>(
    'admin_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupId,
    name,
    adminDeviceId,
    revision,
    createdAt,
    updatedAt,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meya_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeyaGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('admin_device_id')) {
      context.handle(
        _adminDeviceIdMeta,
        adminDeviceId.isAcceptableOrUnknown(
          data['admin_device_id']!,
          _adminDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_adminDeviceIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
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
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  MeyaGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeyaGroup(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      adminDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}admin_device_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $MeyaGroupsTable createAlias(String alias) {
    return $MeyaGroupsTable(attachedDatabase, alias);
  }
}

class MeyaGroup extends DataClass implements Insertable<MeyaGroup> {
  final String groupId;
  final String name;
  final String adminDeviceId;
  final int revision;
  final String createdAt;
  final String updatedAt;

  /// False once this device left or was removed. History stays readable.
  final bool isActive;
  const MeyaGroup({
    required this.groupId,
    required this.name,
    required this.adminDeviceId,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['name'] = Variable<String>(name);
    map['admin_device_id'] = Variable<String>(adminDeviceId);
    map['revision'] = Variable<int>(revision);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  MeyaGroupsCompanion toCompanion(bool nullToAbsent) {
    return MeyaGroupsCompanion(
      groupId: Value(groupId),
      name: Value(name),
      adminDeviceId: Value(adminDeviceId),
      revision: Value(revision),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isActive: Value(isActive),
    );
  }

  factory MeyaGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeyaGroup(
      groupId: serializer.fromJson<String>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      adminDeviceId: serializer.fromJson<String>(json['adminDeviceId']),
      revision: serializer.fromJson<int>(json['revision']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'name': serializer.toJson<String>(name),
      'adminDeviceId': serializer.toJson<String>(adminDeviceId),
      'revision': serializer.toJson<int>(revision),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  MeyaGroup copyWith({
    String? groupId,
    String? name,
    String? adminDeviceId,
    int? revision,
    String? createdAt,
    String? updatedAt,
    bool? isActive,
  }) => MeyaGroup(
    groupId: groupId ?? this.groupId,
    name: name ?? this.name,
    adminDeviceId: adminDeviceId ?? this.adminDeviceId,
    revision: revision ?? this.revision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isActive: isActive ?? this.isActive,
  );
  MeyaGroup copyWithCompanion(MeyaGroupsCompanion data) {
    return MeyaGroup(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      adminDeviceId: data.adminDeviceId.present
          ? data.adminDeviceId.value
          : this.adminDeviceId,
      revision: data.revision.present ? data.revision.value : this.revision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeyaGroup(')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('adminDeviceId: $adminDeviceId, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    groupId,
    name,
    adminDeviceId,
    revision,
    createdAt,
    updatedAt,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeyaGroup &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.adminDeviceId == this.adminDeviceId &&
          other.revision == this.revision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isActive == this.isActive);
}

class MeyaGroupsCompanion extends UpdateCompanion<MeyaGroup> {
  final Value<String> groupId;
  final Value<String> name;
  final Value<String> adminDeviceId;
  final Value<int> revision;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<bool> isActive;
  final Value<int> rowid;
  const MeyaGroupsCompanion({
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.adminDeviceId = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeyaGroupsCompanion.insert({
    required String groupId,
    required String name,
    required String adminDeviceId,
    this.revision = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       name = Value(name),
       adminDeviceId = Value(adminDeviceId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MeyaGroup> custom({
    Expression<String>? groupId,
    Expression<String>? name,
    Expression<String>? adminDeviceId,
    Expression<int>? revision,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (adminDeviceId != null) 'admin_device_id': adminDeviceId,
      if (revision != null) 'revision': revision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeyaGroupsCompanion copyWith({
    Value<String>? groupId,
    Value<String>? name,
    Value<String>? adminDeviceId,
    Value<int>? revision,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return MeyaGroupsCompanion(
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      adminDeviceId: adminDeviceId ?? this.adminDeviceId,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (adminDeviceId.present) {
      map['admin_device_id'] = Variable<String>(adminDeviceId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeyaGroupsCompanion(')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('adminDeviceId: $adminDeviceId, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupMembersTable extends GroupMembers
    with TableInfo<$GroupMembersTable, GroupMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES meya_groups (group_id)',
    ),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identityIdMeta = const VerificationMeta(
    'identityId',
  );
  @override
  late final GeneratedColumn<String> identityId = GeneratedColumn<String>(
    'identity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identityPublicKeyMeta = const VerificationMeta(
    'identityPublicKey',
  );
  @override
  late final GeneratedColumn<String> identityPublicKey =
      GeneratedColumn<String>(
        'identity_public_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<String> addedAt = GeneratedColumn<String>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupId,
    deviceId,
    identityId,
    displayName,
    identityPublicKey,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('identity_id')) {
      context.handle(
        _identityIdMeta,
        identityId.isAcceptableOrUnknown(data['identity_id']!, _identityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_identityIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('identity_public_key')) {
      context.handle(
        _identityPublicKeyMeta,
        identityPublicKey.isAcceptableOrUnknown(
          data['identity_public_key']!,
          _identityPublicKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identityPublicKeyMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, deviceId};
  @override
  GroupMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMember(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      identityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      identityPublicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_public_key'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $GroupMembersTable createAlias(String alias) {
    return $GroupMembersTable(attachedDatabase, alias);
  }
}

class GroupMember extends DataClass implements Insertable<GroupMember> {
  final String groupId;
  final String deviceId;
  final String identityId;
  final String displayName;
  final String identityPublicKey;
  final String addedAt;
  const GroupMember({
    required this.groupId,
    required this.deviceId,
    required this.identityId,
    required this.displayName,
    required this.identityPublicKey,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['device_id'] = Variable<String>(deviceId);
    map['identity_id'] = Variable<String>(identityId);
    map['display_name'] = Variable<String>(displayName);
    map['identity_public_key'] = Variable<String>(identityPublicKey);
    map['added_at'] = Variable<String>(addedAt);
    return map;
  }

  GroupMembersCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersCompanion(
      groupId: Value(groupId),
      deviceId: Value(deviceId),
      identityId: Value(identityId),
      displayName: Value(displayName),
      identityPublicKey: Value(identityPublicKey),
      addedAt: Value(addedAt),
    );
  }

  factory GroupMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMember(
      groupId: serializer.fromJson<String>(json['groupId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      identityId: serializer.fromJson<String>(json['identityId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      identityPublicKey: serializer.fromJson<String>(json['identityPublicKey']),
      addedAt: serializer.fromJson<String>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'deviceId': serializer.toJson<String>(deviceId),
      'identityId': serializer.toJson<String>(identityId),
      'displayName': serializer.toJson<String>(displayName),
      'identityPublicKey': serializer.toJson<String>(identityPublicKey),
      'addedAt': serializer.toJson<String>(addedAt),
    };
  }

  GroupMember copyWith({
    String? groupId,
    String? deviceId,
    String? identityId,
    String? displayName,
    String? identityPublicKey,
    String? addedAt,
  }) => GroupMember(
    groupId: groupId ?? this.groupId,
    deviceId: deviceId ?? this.deviceId,
    identityId: identityId ?? this.identityId,
    displayName: displayName ?? this.displayName,
    identityPublicKey: identityPublicKey ?? this.identityPublicKey,
    addedAt: addedAt ?? this.addedAt,
  );
  GroupMember copyWithCompanion(GroupMembersCompanion data) {
    return GroupMember(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      identityId: data.identityId.present
          ? data.identityId.value
          : this.identityId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      identityPublicKey: data.identityPublicKey.present
          ? data.identityPublicKey.value
          : this.identityPublicKey,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupMember(')
          ..write('groupId: $groupId, ')
          ..write('deviceId: $deviceId, ')
          ..write('identityId: $identityId, ')
          ..write('displayName: $displayName, ')
          ..write('identityPublicKey: $identityPublicKey, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    groupId,
    deviceId,
    identityId,
    displayName,
    identityPublicKey,
    addedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMember &&
          other.groupId == this.groupId &&
          other.deviceId == this.deviceId &&
          other.identityId == this.identityId &&
          other.displayName == this.displayName &&
          other.identityPublicKey == this.identityPublicKey &&
          other.addedAt == this.addedAt);
}

class GroupMembersCompanion extends UpdateCompanion<GroupMember> {
  final Value<String> groupId;
  final Value<String> deviceId;
  final Value<String> identityId;
  final Value<String> displayName;
  final Value<String> identityPublicKey;
  final Value<String> addedAt;
  final Value<int> rowid;
  const GroupMembersCompanion({
    this.groupId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.identityId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.identityPublicKey = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMembersCompanion.insert({
    required String groupId,
    required String deviceId,
    required String identityId,
    required String displayName,
    required String identityPublicKey,
    required String addedAt,
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       deviceId = Value(deviceId),
       identityId = Value(identityId),
       displayName = Value(displayName),
       identityPublicKey = Value(identityPublicKey),
       addedAt = Value(addedAt);
  static Insertable<GroupMember> custom({
    Expression<String>? groupId,
    Expression<String>? deviceId,
    Expression<String>? identityId,
    Expression<String>? displayName,
    Expression<String>? identityPublicKey,
    Expression<String>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (deviceId != null) 'device_id': deviceId,
      if (identityId != null) 'identity_id': identityId,
      if (displayName != null) 'display_name': displayName,
      if (identityPublicKey != null) 'identity_public_key': identityPublicKey,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMembersCompanion copyWith({
    Value<String>? groupId,
    Value<String>? deviceId,
    Value<String>? identityId,
    Value<String>? displayName,
    Value<String>? identityPublicKey,
    Value<String>? addedAt,
    Value<int>? rowid,
  }) {
    return GroupMembersCompanion(
      groupId: groupId ?? this.groupId,
      deviceId: deviceId ?? this.deviceId,
      identityId: identityId ?? this.identityId,
      displayName: displayName ?? this.displayName,
      identityPublicKey: identityPublicKey ?? this.identityPublicKey,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (identityId.present) {
      map['identity_id'] = Variable<String>(identityId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (identityPublicKey.present) {
      map['identity_public_key'] = Variable<String>(identityPublicKey.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<String>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersCompanion(')
          ..write('groupId: $groupId, ')
          ..write('deviceId: $deviceId, ')
          ..write('identityId: $identityId, ')
          ..write('displayName: $displayName, ')
          ..write('identityPublicKey: $identityPublicKey, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MeyaDatabase extends GeneratedDatabase {
  _$MeyaDatabase(QueryExecutor e) : super(e);
  $MeyaDatabaseManager get managers => $MeyaDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $ContactDevicesTable contactDevices = $ContactDevicesTable(this);
  late final $ConnectionRequestsTable connectionRequests =
      $ConnectionRequestsTable(this);
  late final $ConversationsTable conversations = $ConversationsTable(this);
  late final $ConversationParticipantsTable conversationParticipants =
      $ConversationParticipantsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $ReactionsTable reactions = $ReactionsTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $MeyaGroupsTable meyaGroups = $MeyaGroupsTable(this);
  late final $GroupMembersTable groupMembers = $GroupMembersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    devices,
    contacts,
    contactDevices,
    connectionRequests,
    conversations,
    conversationParticipants,
    messages,
    attachments,
    reactions,
    outbox,
    meyaGroups,
    groupMembers,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String accountId,
  Value<String?> identityId,
  required String meyaId,
  required String name,
  required String username,
  required String createdAt,
  required String identityPublicKey,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> accountId,
  Value<String?> identityId,
  Value<String> meyaId,
  Value<String> name,
  Value<String> username,
  Value<String> createdAt,
  Value<String> identityPublicKey,
  Value<bool> isActive,
  Value<int> rowid,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$MeyaDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DevicesTable, List<Device>> _devicesRefsTable(
    _$MeyaDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.devices,
    aliasName: 'accounts__account_id__devices__account_id',
  );

  $$DevicesTableProcessedTableManager get devicesRefs {
    final manager = $$DevicesTableTableManager($_db, $_db.devices).filter(
      (f) =>
          f.accountId.accountId.sqlEquals($_itemColumn<String>('account_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_devicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$MeyaDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meyaId => $composableBuilder(
    column: $table.meyaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> devicesRefs(
    Expression<bool> Function($$DevicesTableFilterComposer f) f,
  ) {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$MeyaDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meyaId => $composableBuilder(
    column: $table.meyaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$MeyaDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meyaId =>
      $composableBuilder(column: $table.meyaId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> devicesRefs<T extends Object>(
    Expression<T> Function($$DevicesTableAnnotationComposer a) f,
  ) {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$MeyaDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({bool devicesRefs})
        > {
  $$AccountsTableTableManager(_$MeyaDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String?> identityId = const Value.absent(),
                Value<String> meyaId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> identityPublicKey = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                accountId: accountId,
                identityId: identityId,
                meyaId: meyaId,
                name: name,
                username: username,
                createdAt: createdAt,
                identityPublicKey: identityPublicKey,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                Value<String?> identityId = const Value.absent(),
                required String meyaId,
                required String name,
                required String username,
                required String createdAt,
                required String identityPublicKey,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                accountId: accountId,
                identityId: identityId,
                meyaId: meyaId,
                name: name,
                username: username,
                createdAt: createdAt,
                identityPublicKey: identityPublicKey,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, Account>(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({devicesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (devicesRefs) db.devices],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (devicesRefs)
                    await $_getPrefetchedData<Account, $AccountsTable, Device>(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences
                          ._devicesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AccountsTableReferences(db, table, p0).devicesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.accountId == item.accountId,
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

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$MeyaDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({bool devicesRefs})
    >;
typedef $$DevicesTableCreateCompanionBuilder = DevicesCompanion Function({
  required String deviceId,
  required String accountId,
  required String createdAt,
  required String devicePublicKey,
  Value<String?> certificateSignature,
  Value<bool> isTrusted,
  Value<bool> isRevoked,
  Value<int> rowid,
});
typedef $$DevicesTableUpdateCompanionBuilder = DevicesCompanion Function({
  Value<String> deviceId,
  Value<String> accountId,
  Value<String> createdAt,
  Value<String> devicePublicKey,
  Value<String?> certificateSignature,
  Value<bool> isTrusted,
  Value<bool> isRevoked,
  Value<int> rowid,
});

final class $$DevicesTableReferences
    extends BaseReferences<_$MeyaDatabase, $DevicesTable, Device> {
  $$DevicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$MeyaDatabase db) =>
      db.accounts.createAlias('devices__account_id__accounts__account_id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.accountId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DevicesTableFilterComposer
    extends Composer<_$MeyaDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devicePublicKey => $composableBuilder(
    column: $table.devicePublicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get certificateSignature => $composableBuilder(
    column: $table.certificateSignature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTrusted => $composableBuilder(
    column: $table.isTrusted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRevoked => $composableBuilder(
    column: $table.isRevoked,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevicesTableOrderingComposer
    extends Composer<_$MeyaDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devicePublicKey => $composableBuilder(
    column: $table.devicePublicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certificateSignature => $composableBuilder(
    column: $table.certificateSignature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTrusted => $composableBuilder(
    column: $table.isTrusted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRevoked => $composableBuilder(
    column: $table.isRevoked,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$MeyaDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get devicePublicKey => $composableBuilder(
    column: $table.devicePublicKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get certificateSignature => $composableBuilder(
    column: $table.certificateSignature,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTrusted =>
      $composableBuilder(column: $table.isTrusted, builder: (column) => column);

  GeneratedColumn<bool> get isRevoked =>
      $composableBuilder(column: $table.isRevoked, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevicesTableTableManager
    extends
        RootTableManager<
          _$MeyaDatabase,
          $DevicesTable,
          Device,
          $$DevicesTableFilterComposer,
          $$DevicesTableOrderingComposer,
          $$DevicesTableAnnotationComposer,
          $$DevicesTableCreateCompanionBuilder,
          $$DevicesTableUpdateCompanionBuilder,
          (Device, $$DevicesTableReferences),
          Device,
          PrefetchHooks Function({bool accountId})
        > {
  $$DevicesTableTableManager(_$MeyaDatabase db, $DevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> devicePublicKey = const Value.absent(),
                Value<String?> certificateSignature = const Value.absent(),
                Value<bool> isTrusted = const Value.absent(),
                Value<bool> isRevoked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion(
                deviceId: deviceId,
                accountId: accountId,
                createdAt: createdAt,
                devicePublicKey: devicePublicKey,
                certificateSignature: certificateSignature,
                isTrusted: isTrusted,
                isRevoked: isRevoked,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required String accountId,
                required String createdAt,
                required String devicePublicKey,
                Value<String?> certificateSignature = const Value.absent(),
                Value<bool> isTrusted = const Value.absent(),
                Value<bool> isRevoked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion.insert(
                deviceId: deviceId,
                accountId: accountId,
                createdAt: createdAt,
                devicePublicKey: devicePublicKey,
                certificateSignature: certificateSignature,
                isTrusted: isTrusted,
                isRevoked: isRevoked,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DevicesTable, Device>(table),
                  $$DevicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
                    if (accountId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.accountId,
                        referencedTable: $$DevicesTableReferences
                            ._accountIdTable(db),
                        referencedColumn: $$DevicesTableReferences
                            ._accountIdTable(db)
                            .accountId,
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

typedef $$DevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$MeyaDatabase,
      $DevicesTable,
      Device,
      $$DevicesTableFilterComposer,
      $$DevicesTableOrderingComposer,
      $$DevicesTableAnnotationComposer,
      $$DevicesTableCreateCompanionBuilder,
      $$DevicesTableUpdateCompanionBuilder,
      (Device, $$DevicesTableReferences),
      Device,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$ContactsTableCreateCompanionBuilder = ContactsCompanion Function({
  required String contactId,
  required String identityId,
  required String displayName,
  required String identityPublicKey,
  Value<String> trustState,
  required String createdAt,
  required String updatedAt,
  Value<bool> isRevoked,
  Value<int> rowid,
});
typedef $$ContactsTableUpdateCompanionBuilder = ContactsCompanion Function({
  Value<String> contactId,
  Value<String> identityId,
  Value<String> displayName,
  Value<String> identityPublicKey,
  Value<String> trustState,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<bool> isRevoked,
  Value<int> rowid,
});

final class $$ContactsTableReferences
    extends BaseReferences<_$MeyaDatabase, $ContactsTable, Contact> {
  $$ContactsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ContactDevicesTable, List<ContactDevice>>
  _contactDevicesRefsTable(_$MeyaDatabase db) => MultiTypedResultKey.fromTable(
    db.contactDevices,
    aliasName: 'contacts__contact_id__contact_devices__contact_id',
  );

  $$ContactDevicesTableProcessedTableManager get contactDevicesRefs {
    final manager = $$ContactDevicesTableTableManager($_db, $_db.contactDevices)
        .filter(
          (f) => f.contactId.contactId.sqlEquals(
            $_itemColumn<String>('contact_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_contactDevicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ConversationParticipantsTable,
    List<ConversationParticipant>
  >
  _conversationParticipantsRefsTable(_$MeyaDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.conversationParticipants,
        aliasName:
            'contacts__contact_id__conversation_participants__contact_id',
      );

  $$ConversationParticipantsTableProcessedTableManager
  get conversationParticipantsRefs {
    final manager =
        $$ConversationParticipantsTableTableManager(
          $_db,
          $_db.conversationParticipants,
        ).filter(
          (f) => f.contactId.contactId.sqlEquals(
            $_itemColumn<String>('contact_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _conversationParticipantsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContactsTableFilterComposer
    extends Composer<_$MeyaDatabase, $ContactsTable> {
  $$ContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trustState => $composableBuilder(
    column: $table.trustState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRevoked => $composableBuilder(
    column: $table.isRevoked,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> contactDevicesRefs(
    Expression<bool> Function($$ContactDevicesTableFilterComposer f) f,
  ) {
    final $$ContactDevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contactDevices,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactDevicesTableFilterComposer(
            $db: $db,
            $table: $db.contactDevices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> conversationParticipantsRefs(
    Expression<bool> Function($$ConversationParticipantsTableFilterComposer f)
    f,
  ) {
    final $$ConversationParticipantsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contactId,
          referencedTable: $db.conversationParticipants,
          getReferencedColumn: (t) => t.contactId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConversationParticipantsTableFilterComposer(
                $db: $db,
                $table: $db.conversationParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ContactsTableOrderingComposer
    extends Composer<_$MeyaDatabase, $ContactsTable> {
  $$ContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trustState => $composableBuilder(
    column: $table.trustState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRevoked => $composableBuilder(
    column: $table.isRevoked,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$MeyaDatabase, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contactId =>
      $composableBuilder(column: $table.contactId, builder: (column) => column);

  GeneratedColumn<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trustState => $composableBuilder(
    column: $table.trustState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isRevoked =>
      $composableBuilder(column: $table.isRevoked, builder: (column) => column);

  Expression<T> contactDevicesRefs<T extends Object>(
    Expression<T> Function($$ContactDevicesTableAnnotationComposer a) f,
  ) {
    final $$ContactDevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contactDevices,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactDevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.contactDevices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> conversationParticipantsRefs<T extends Object>(
    Expression<T> Function($$ConversationParticipantsTableAnnotationComposer a)
    f,
  ) {
    final $$ConversationParticipantsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.contactId,
          referencedTable: $db.conversationParticipants,
          getReferencedColumn: (t) => t.contactId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConversationParticipantsTableAnnotationComposer(
                $db: $db,
                $table: $db.conversationParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ContactsTableTableManager
    extends
        RootTableManager<
          _$MeyaDatabase,
          $ContactsTable,
          Contact,
          $$ContactsTableFilterComposer,
          $$ContactsTableOrderingComposer,
          $$ContactsTableAnnotationComposer,
          $$ContactsTableCreateCompanionBuilder,
          $$ContactsTableUpdateCompanionBuilder,
          (Contact, $$ContactsTableReferences),
          Contact,
          PrefetchHooks Function({
            bool contactDevicesRefs,
            bool conversationParticipantsRefs,
          })
        > {
  $$ContactsTableTableManager(_$MeyaDatabase db, $ContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> contactId = const Value.absent(),
                Value<String> identityId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> identityPublicKey = const Value.absent(),
                Value<String> trustState = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<bool> isRevoked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion(
                contactId: contactId,
                identityId: identityId,
                displayName: displayName,
                identityPublicKey: identityPublicKey,
                trustState: trustState,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isRevoked: isRevoked,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contactId,
                required String identityId,
                required String displayName,
                required String identityPublicKey,
                Value<String> trustState = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<bool> isRevoked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactsCompanion.insert(
                contactId: contactId,
                identityId: identityId,
                displayName: displayName,
                identityPublicKey: identityPublicKey,
                trustState: trustState,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isRevoked: isRevoked,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContactsTable, Contact>(table),
                  $$ContactsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                contactDevicesRefs = false,
                conversationParticipantsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (contactDevicesRefs) db.contactDevices,
                    if (conversationParticipantsRefs)
                      db.conversationParticipants,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (contactDevicesRefs)
                        await $_getPrefetchedData<
                          Contact,
                          $ContactsTable,
                          ContactDevice
                        >(
                          currentTable: table,
                          referencedTable: $$ContactsTableReferences
                              ._contactDevicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContactsTableReferences(
                                db,
                                table,
                                p0,
                              ).contactDevicesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contactId == item.contactId,
                              ),
                          typedResults: items,
                        ),
                      if (conversationParticipantsRefs)
                        await $_getPrefetchedData<
                          Contact,
                          $ContactsTable,
                          ConversationParticipant
                        >(
                          currentTable: table,
                          referencedTable: $$ContactsTableReferences
                              ._conversationParticipantsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContactsTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationParticipantsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contactId == item.contactId,
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

typedef $$ContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$MeyaDatabase,
      $ContactsTable,
      Contact,
      $$ContactsTableFilterComposer,
      $$ContactsTableOrderingComposer,
      $$ContactsTableAnnotationComposer,
      $$ContactsTableCreateCompanionBuilder,
      $$ContactsTableUpdateCompanionBuilder,
      (Contact, $$ContactsTableReferences),
      Contact,
      PrefetchHooks Function({
        bool contactDevicesRefs,
        bool conversationParticipantsRefs,
      })
    >;
typedef $$ContactDevicesTableCreateCompanionBuilder =
    ContactDevicesCompanion Function({
      required String deviceId,
      required String contactId,
      required String devicePublicKey,
      required String certificateSignature,
      required Uint8List keyPackage,
      required String createdAt,
      required String updatedAt,
      Value<bool> isRevoked,
      Value<int> rowid,
    });
typedef $$ContactDevicesTableUpdateCompanionBuilder =
    ContactDevicesCompanion Function({
      Value<String> deviceId,
      Value<String> contactId,
      Value<String> devicePublicKey,
      Value<String> certificateSignature,
      Value<Uint8List> keyPackage,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<bool> isRevoked,
      Value<int> rowid,
    });

final class $$ContactDevicesTableReferences
    extends
        BaseReferences<_$MeyaDatabase, $ContactDevicesTable, ContactDevice> {
  $$ContactDevicesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ContactsTable _contactIdTable(_$MeyaDatabase db) => db.contacts
      .createAlias('contact_devices__contact_id__contacts__contact_id');

  $$ContactsTableProcessedTableManager get contactId {
    final $_column = $_itemColumn<String>('contact_id')!;

    final manager = $$ContactsTableTableManager(
      $_db,
      $_db.contacts,
    ).filter((f) => f.contactId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ContactDevicesTableFilterComposer
    extends Composer<_$MeyaDatabase, $ContactDevicesTable> {
  $$ContactDevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devicePublicKey => $composableBuilder(
    column: $table.devicePublicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get certificateSignature => $composableBuilder(
    column: $table.certificateSignature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get keyPackage => $composableBuilder(
    column: $table.keyPackage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRevoked => $composableBuilder(
    column: $table.isRevoked,
    builder: (column) => ColumnFilters(column),
  );

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableFilterComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactDevicesTableOrderingComposer
    extends Composer<_$MeyaDatabase, $ContactDevicesTable> {
  $$ContactDevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devicePublicKey => $composableBuilder(
    column: $table.devicePublicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certificateSignature => $composableBuilder(
    column: $table.certificateSignature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get keyPackage => $composableBuilder(
    column: $table.keyPackage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRevoked => $composableBuilder(
    column: $table.isRevoked,
    builder: (column) => ColumnOrderings(column),
  );

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableOrderingComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactDevicesTableAnnotationComposer
    extends Composer<_$MeyaDatabase, $ContactDevicesTable> {
  $$ContactDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get devicePublicKey => $composableBuilder(
    column: $table.devicePublicKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get certificateSignature => $composableBuilder(
    column: $table.certificateSignature,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get keyPackage => $composableBuilder(
    column: $table.keyPackage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isRevoked =>
      $composableBuilder(column: $table.isRevoked, builder: (column) => column);

  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableAnnotationComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactDevicesTableTableManager
    extends
        RootTableManager<
          _$MeyaDatabase,
          $ContactDevicesTable,
          ContactDevice,
          $$ContactDevicesTableFilterComposer,
          $$ContactDevicesTableOrderingComposer,
          $$ContactDevicesTableAnnotationComposer,
          $$ContactDevicesTableCreateCompanionBuilder,
          $$ContactDevicesTableUpdateCompanionBuilder,
          (ContactDevice, $$ContactDevicesTableReferences),
          ContactDevice,
          PrefetchHooks Function({bool contactId})
        > {
  $$ContactDevicesTableTableManager(
    _$MeyaDatabase db,
    $ContactDevicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<String> contactId = const Value.absent(),
                Value<String> devicePublicKey = const Value.absent(),
                Value<String> certificateSignature = const Value.absent(),
                Value<Uint8List> keyPackage = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<bool> isRevoked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactDevicesCompanion(
                deviceId: deviceId,
                contactId: contactId,
                devicePublicKey: devicePublicKey,
                certificateSignature: certificateSignature,
                keyPackage: keyPackage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isRevoked: isRevoked,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required String contactId,
                required String devicePublicKey,
                required String certificateSignature,
                required Uint8List keyPackage,
                required String createdAt,
                required String updatedAt,
                Value<bool> isRevoked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactDevicesCompanion.insert(
                deviceId: deviceId,
                contactId: contactId,
                devicePublicKey: devicePublicKey,
                certificateSignature: certificateSignature,
                keyPackage: keyPackage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isRevoked: isRevoked,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContactDevicesTable, ContactDevice>(table),
                  $$ContactDevicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({contactId = false}) {
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
                    if (contactId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.contactId,
                        referencedTable: $$ContactDevicesTableReferences
                            ._contactIdTable(db),
                        referencedColumn: $$ContactDevicesTableReferences
                            ._contactIdTable(db)
                            .contactId,
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

typedef $$ContactDevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$MeyaDatabase,
      $ContactDevicesTable,
      ContactDevice,
      $$ContactDevicesTableFilterComposer,
      $$ContactDevicesTableOrderingComposer,
      $$ContactDevicesTableAnnotationComposer,
      $$ContactDevicesTableCreateCompanionBuilder,
      $$ContactDevicesTableUpdateCompanionBuilder,
      (ContactDevice, $$ContactDevicesTableReferences),
      ContactDevice,
      PrefetchHooks Function({bool contactId})
    >;
typedef $$ConnectionRequestsTableCreateCompanionBuilder =
    ConnectionRequestsCompanion Function({
      required String requestId,
      required String senderIdentityId,
      required String senderDeviceId,
      required String senderUsername,
      required String senderIdentityPublicKey,
      required String recipientDeviceId,
      Value<String?> recipientIdentityId,
      Value<String?> recipientIdentityPublicKey,
      Value<String> status,
      required String createdAt,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$ConnectionRequestsTableUpdateCompanionBuilder =
    ConnectionRequestsCompanion Function({
      Value<String> requestId,
      Value<String> senderIdentityId,
      Value<String> senderDeviceId,
      Value<String> senderUsername,
      Value<String> senderIdentityPublicKey,
      Value<String> recipientDeviceId,
      Value<String?> recipientIdentityId,
      Value<String?> recipientIdentityPublicKey,
      Value<String> status,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$ConnectionRequestsTableFilterComposer
    extends Composer<_$MeyaDatabase, $ConnectionRequestsTable> {
  $$ConnectionRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderIdentityId => $composableBuilder(
    column: $table.senderIdentityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderDeviceId => $composableBuilder(
    column: $table.senderDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderUsername => $composableBuilder(
    column: $table.senderUsername,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderIdentityPublicKey => $composableBuilder(
    column: $table.senderIdentityPublicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipientDeviceId => $composableBuilder(
    column: $table.recipientDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipientIdentityId => $composableBuilder(
    column: $table.recipientIdentityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipientIdentityPublicKey => $composableBuilder(
    column: $table.recipientIdentityPublicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConnectionRequestsTableOrderingComposer
    extends Composer<_$MeyaDatabase, $ConnectionRequestsTable> {
  $$ConnectionRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderIdentityId => $composableBuilder(
    column: $table.senderIdentityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderDeviceId => $composableBuilder(
    column: $table.senderDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderUsername => $composableBuilder(
    column: $table.senderUsername,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderIdentityPublicKey => $composableBuilder(
    column: $table.senderIdentityPublicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipientDeviceId => $composableBuilder(
    column: $table.recipientDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipientIdentityId => $composableBuilder(
    column: $table.recipientIdentityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipientIdentityPublicKey => $composableBuilder(
    column: $table.recipientIdentityPublicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConnectionRequestsTableAnnotationComposer
    extends Composer<_$MeyaDatabase, $ConnectionRequestsTable> {
  $$ConnectionRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get senderIdentityId => $composableBuilder(
    column: $table.senderIdentityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderDeviceId => $composableBuilder(
    column: $table.senderDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderUsername => $composableBuilder(
    column: $table.senderUsername,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderIdentityPublicKey => $composableBuilder(
    column: $table.senderIdentityPublicKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recipientDeviceId => $composableBuilder(
    column: $table.recipientDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recipientIdentityId => $composableBuilder(
    column: $table.recipientIdentityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recipientIdentityPublicKey => $composableBuilder(
    column: $table.recipientIdentityPublicKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ConnectionRequestsTableTableManager
    extends
        RootTableManager<
          _$MeyaDatabase,
          $ConnectionRequestsTable,
          ConnectionRequest,
          $$ConnectionRequestsTableFilterComposer,
          $$ConnectionRequestsTableOrderingComposer,
          $$ConnectionRequestsTableAnnotationComposer,
          $$ConnectionRequestsTableCreateCompanionBuilder,
          $$ConnectionRequestsTableUpdateCompanionBuilder,
          (
            ConnectionRequest,
            BaseReferences<
              _$MeyaDatabase,
              $ConnectionRequestsTable,
              ConnectionRequest
            >,
          ),
          ConnectionRequest,
          PrefetchHooks Function()
        > {
  $$ConnectionRequestsTableTableManager(
    _$MeyaDatabase db,
    $ConnectionRequestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectionRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConnectionRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConnectionRequestsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> requestId = const Value.absent(),
                Value<String> senderIdentityId = const Value.absent(),
                Value<String> senderDeviceId = const Value.absent(),
                Value<String> senderUsername = const Value.absent(),
                Value<String> senderIdentityPublicKey = const Value.absent(),
                Value<String> recipientDeviceId = const Value.absent(),
                Value<String?> recipientIdentityId = const Value.absent(),
                Value<String?> recipientIdentityPublicKey =
                    const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConnectionRequestsCompanion(
                requestId: requestId,
                senderIdentityId: senderIdentityId,
                senderDeviceId: senderDeviceId,
                senderUsername: senderUsername,
                senderIdentityPublicKey: senderIdentityPublicKey,
                recipientDeviceId: recipientDeviceId,
                recipientIdentityId: recipientIdentityId,
                recipientIdentityPublicKey: recipientIdentityPublicKey,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String requestId,
                required String senderIdentityId,
                required String senderDeviceId,
                required String senderUsername,
                required String senderIdentityPublicKey,
                required String recipientDeviceId,
                Value<String?> recipientIdentityId = const Value.absent(),
                Value<String?> recipientIdentityPublicKey =
                    const Value.absent(),
                Value<String> status = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ConnectionRequestsCompanion.insert(
                requestId: requestId,
                senderIdentityId: senderIdentityId,
                senderDeviceId: senderDeviceId,
                senderUsername: senderUsername,
                senderIdentityPublicKey: senderIdentityPublicKey,
                recipientDeviceId: recipientDeviceId,
                recipientIdentityId: recipientIdentityId,
                recipientIdentityPublicKey: recipientIdentityPublicKey,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConnectionRequestsTable, ConnectionRequest>(
                    table,
                  ),
                  BaseReferences<
                    _$MeyaDatabase,
                    $ConnectionRequestsTable,
                    ConnectionRequest
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConnectionRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$MeyaDatabase,
      $ConnectionRequestsTable,
      ConnectionRequest,
      $$ConnectionRequestsTableFilterComposer,
      $$ConnectionRequestsTableOrderingComposer,
      $$ConnectionRequestsTableAnnotationComposer,
      $$ConnectionRequestsTableCreateCompanionBuilder,
      $$ConnectionRequestsTableUpdateCompanionBuilder,
      (
        ConnectionRequest,
        BaseReferences<
          _$MeyaDatabase,
          $ConnectionRequestsTable,
          ConnectionRequest
        >,
      ),
      ConnectionRequest,
      PrefetchHooks Function()
    >;
typedef $$ConversationsTableCreateCompanionBuilder =
    ConversationsCompanion Function({
      required String conversationId,
      required String type,
      required String mlsGroupId,
      required String createdAt,
      required String updatedAt,
      Value<bool> isArchived,
      Value<int> unreadCount,
      Value<bool> isMuted,
      Value<bool> markedUnread,
      Value<int> rowid,
    });
typedef $$ConversationsTableUpdateCompanionBuilder =
    ConversationsCompanion Function({
      Value<String> conversationId,
      Value<String> type,
      Value<String> mlsGroupId,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<bool> isArchived,
      Value<int> unreadCount,
      Value<bool> isMuted,
      Value<bool> markedUnread,
      Value<int> rowid,
    });

final class $$ConversationsTableReferences
    extends BaseReferences<_$MeyaDatabase, $ConversationsTable, Conversation> {
  $$ConversationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $ConversationParticipantsTable,
    List<ConversationParticipant>
  >
  _conversationParticipantsRefsTable(_$MeyaDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.conversationParticipants,
        aliasName: 'conversations__conversation_id__conversation_participants__conversation_id',
      );

  $$ConversationParticipantsTableProcessedTableManager
  get conversationParticipantsRefs {
    final manager =
        $$ConversationParticipantsTableTableManager(
          $_db,
          $_db.conversationParticipants,
        ).filter(
          (f) => f.conversationId.conversationId.sqlEquals(
            $_itemColumn<String>('conversation_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _conversationParticipantsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MessagesTable, List<Message>> _messagesRefsTable(
    _$MeyaDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: 'conversations__conversation_id__messages__conversation_id',
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager($_db, $_db.messages).filter(
      (f) => f.conversationId.conversationId.sqlEquals(
        $_itemColumn<String>('conversation_id')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConversationsTableFilterComposer
    extends Composer<_$MeyaDatabase, $ConversationsTable> {
  $$ConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mlsGroupId => $composableBuilder(
    column: $table.mlsGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get markedUnread => $composableBuilder(
    column: $table.markedUnread,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> conversationParticipantsRefs(
    Expression<bool> Function($$ConversationParticipantsTableFilterComposer f)
    f,
  ) {
    final $$ConversationParticipantsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationId,
          referencedTable: $db.conversationParticipants,
          getReferencedColumn: (t) => t.conversationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConversationParticipantsTableFilterComposer(
                $db: $db,
                $table: $db.conversationParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableOrderingComposer
    extends Composer<_$MeyaDatabase, $ConversationsTable> {
  $$ConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mlsGroupId => $composableBuilder(
    column: $table.mlsGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get markedUnread => $composableBuilder(
    column: $table.markedUnread,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableAnnotationComposer
    extends Composer<_$MeyaDatabase, $ConversationsTable> {
  $$ConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get mlsGroupId => $composableBuilder(
    column: $table.mlsGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isMuted =>
      $composableBuilder(column: $table.isMuted, builder: (column) => column);

  GeneratedColumn<bool> get markedUnread => $composableBuilder(
    column: $table.markedUnread,
    builder: (column) => column,
  );

  Expression<T> conversationParticipantsRefs<T extends Object>(
    Expression<T> Function($$ConversationParticipantsTableAnnotationComposer a)
    f,
  ) {
    final $$ConversationParticipantsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationId,
          referencedTable: $db.conversationParticipants,
          getReferencedColumn: (t) => t.conversationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ConversationParticipantsTableAnnotationComposer(
                $db: $db,
                $table: $db.conversationParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConversationsTableTableManager
    extends
        RootTableManager<
          _$MeyaDatabase,
          $ConversationsTable,
          Conversation,
          $$ConversationsTableFilterComposer,
          $$ConversationsTableOrderingComposer,
          $$ConversationsTableAnnotationComposer,
          $$ConversationsTableCreateCompanionBuilder,
          $$ConversationsTableUpdateCompanionBuilder,
          (Conversation, $$ConversationsTableReferences),
          Conversation,
          PrefetchHooks Function({
            bool conversationParticipantsRefs,
            bool messagesRefs,
          })
        > {
  $$ConversationsTableTableManager(_$MeyaDatabase db, $ConversationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> conversationId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> mlsGroupId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<bool> markedUnread = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion(
                conversationId: conversationId,
                type: type,
                mlsGroupId: mlsGroupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isArchived: isArchived,
                unreadCount: unreadCount,
                isMuted: isMuted,
                markedUnread: markedUnread,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String conversationId,
                required String type,
                required String mlsGroupId,
                required String createdAt,
                required String updatedAt,
                Value<bool> isArchived = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<bool> markedUnread = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsCompanion.insert(
                conversationId: conversationId,
                type: type,
                mlsGroupId: mlsGroupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isArchived: isArchived,
                unreadCount: unreadCount,
                isMuted: isMuted,
                markedUnread: markedUnread,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConversationsTable, Conversation>(table),
                  $$ConversationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({conversationParticipantsRefs = false, messagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (conversationParticipantsRefs)
                      db.conversationParticipants,
                    if (messagesRefs) db.messages,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (conversationParticipantsRefs)
                        await $_getPrefetchedData<
                          Conversation,
                          $ConversationsTable,
                          ConversationParticipant
                        >(
                          currentTable: table,
                          referencedTable: $$ConversationsTableReferences
                              ._conversationParticipantsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConversationsTableReferences(
                                db,
                                table,
                                p0,
                              ).conversationParticipantsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.conversationId == item.conversationId,
                              ),
                          typedResults: items,
                        ),
                      if (messagesRefs)
                        await $_getPrefetchedData<
                          Conversation,
                          $ConversationsTable,
                          Message
                        >(
                          currentTable: table,
                          referencedTable: $$ConversationsTableReferences
                              ._messagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConversationsTableReferences(
                                db,
                                table,
                                p0,
                              ).messagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.conversationId == item.conversationId,
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

typedef $$ConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$MeyaDatabase,
      $ConversationsTable,
      Conversation,
      $$ConversationsTableFilterComposer,
      $$ConversationsTableOrderingComposer,
      $$ConversationsTableAnnotationComposer,
      $$ConversationsTableCreateCompanionBuilder,
      $$ConversationsTableUpdateCompanionBuilder,
      (Conversation, $$ConversationsTableReferences),
      Conversation,
      PrefetchHooks Function({
        bool conversationParticipantsRefs,
        bool messagesRefs,
      })
    >;
typedef $$ConversationParticipantsTableCreateCompanionBuilder =
    ConversationParticipantsCompanion Function({
      required String participantId,
      required String conversationId,
      required String identityId,
      required String deviceId,
      Value<String?> contactId,
      Value<bool> isLocal,
      Value<int> rowid,
    });
typedef $$ConversationParticipantsTableUpdateCompanionBuilder =
    ConversationParticipantsCompanion Function({
      Value<String> participantId,
      Value<String> conversationId,
      Value<String> identityId,
      Value<String> deviceId,
      Value<String?> contactId,
      Value<bool> isLocal,
      Value<int> rowid,
    });

final class $$ConversationParticipantsTableReferences
    extends
        BaseReferences<
          _$MeyaDatabase,
          $ConversationParticipantsTable,
          ConversationParticipant
        > {
  $$ConversationParticipantsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ConversationsTable _conversationIdTable(_$MeyaDatabase db) =>
      db.conversations.createAlias(
        'conversation_participants__conversation_id__conversations__conversation_id',
      );

  $$ConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<String>('conversation_id')!;

    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.conversationId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ContactsTable _contactIdTable(_$MeyaDatabase db) =>
      db.contacts.createAlias(
        'conversation_participants__contact_id__contacts__contact_id',
      );

  $$ContactsTableProcessedTableManager? get contactId {
    final $_column = $_itemColumn<String>('contact_id');
    if ($_column == null) return null;
    final manager = $$ContactsTableTableManager(
      $_db,
      $_db.contacts,
    ).filter((f) => f.contactId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ConversationParticipantsTableFilterComposer
    extends Composer<_$MeyaDatabase, $ConversationParticipantsTable> {
  $$ConversationParticipantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get participantId => $composableBuilder(
    column: $table.participantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocal => $composableBuilder(
    column: $table.isLocal,
    builder: (column) => ColumnFilters(column),
  );

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableFilterComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationParticipantsTableOrderingComposer
    extends Composer<_$MeyaDatabase, $ConversationParticipantsTable> {
  $$ConversationParticipantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get participantId => $composableBuilder(
    column: $table.participantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocal => $composableBuilder(
    column: $table.isLocal,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableOrderingComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableOrderingComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationParticipantsTableAnnotationComposer
    extends Composer<_$MeyaDatabase, $ConversationParticipantsTable> {
  $$ConversationParticipantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get participantId => $composableBuilder(
    column: $table.participantId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isLocal =>
      $composableBuilder(column: $table.isLocal, builder: (column) => column);

  $$ConversationsTableAnnotationComposer get conversationId {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableAnnotationComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConversationParticipantsTableTableManager
    extends
        RootTableManager<
          _$MeyaDatabase,
          $ConversationParticipantsTable,
          ConversationParticipant,
          $$ConversationParticipantsTableFilterComposer,
          $$ConversationParticipantsTableOrderingComposer,
          $$ConversationParticipantsTableAnnotationComposer,
          $$ConversationParticipantsTableCreateCompanionBuilder,
          $$ConversationParticipantsTableUpdateCompanionBuilder,
          (ConversationParticipant, $$ConversationParticipantsTableReferences),
          ConversationParticipant,
          PrefetchHooks Function({bool conversationId, bool contactId})
        > {
  $$ConversationParticipantsTableTableManager(
    _$MeyaDatabase db,
    $ConversationParticipantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationParticipantsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ConversationParticipantsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ConversationParticipantsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> participantId = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> identityId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String?> contactId = const Value.absent(),
                Value<bool> isLocal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationParticipantsCompanion(
                participantId: participantId,
                conversationId: conversationId,
                identityId: identityId,
                deviceId: deviceId,
                contactId: contactId,
                isLocal: isLocal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String participantId,
                required String conversationId,
                required String identityId,
                required String deviceId,
                Value<String?> contactId = const Value.absent(),
                Value<bool> isLocal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationParticipantsCompanion.insert(
                participantId: participantId,
                conversationId: conversationId,
                identityId: identityId,
                deviceId: deviceId,
                contactId: contactId,
                isLocal: isLocal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ConversationParticipantsTable,
                    ConversationParticipant
                  >(table),
                  $$ConversationParticipantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({conversationId = false, contactId = false}) {
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
                    if (conversationId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.conversationId,
                        referencedTable:
                            $$ConversationParticipantsTableReferences
                                ._conversationIdTable(db),
                        referencedColumn:
                            $$ConversationParticipantsTableReferences
                                ._conversationIdTable(db)
                                .conversationId,
                      ) as T;
                    }
                    if (contactId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.contactId,
                        referencedTable:
                            $$ConversationParticipantsTableReferences
                                ._contactIdTable(db),
                        referencedColumn:
                            $$ConversationParticipantsTableReferences
                                ._contactIdTable(db)
                                .contactId,
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

typedef $$ConversationParticipantsTableProcessedTableManager =
    ProcessedTableManager<
      _$MeyaDatabase,
      $ConversationParticipantsTable,
      ConversationParticipant,
      $$ConversationParticipantsTableFilterComposer,
      $$ConversationParticipantsTableOrderingComposer,
      $$ConversationParticipantsTableAnnotationComposer,
      $$ConversationParticipantsTableCreateCompanionBuilder,
      $$ConversationParticipantsTableUpdateCompanionBuilder,
      (ConversationParticipant, $$ConversationParticipantsTableReferences),
      ConversationParticipant,
      PrefetchHooks Function({bool conversationId, bool contactId})
    >;
typedef $$MessagesTableCreateCompanionBuilder = MessagesCompanion Function({
  required String messageId,
  required String conversationId,
  required String senderDeviceId,
  required String createdAt,
  required Uint8List encryptedEnvelope,
  Value<Uint8List?> localDisplayCiphertext,
  Value<String> deliveryState,
  Value<bool> isRead,
  Value<int> retryCount,
  Value<bool> isStarred,
  Value<bool> isPinned,
  Value<bool> isDeleted,
  Value<String?> editedAt,
  Value<int> rowid,
});
typedef $$MessagesTableUpdateCompanionBuilder = MessagesCompanion Function({
  Value<String> messageId,
  Value<String> conversationId,
  Value<String> senderDeviceId,
  Value<String> createdAt,
  Value<Uint8List> encryptedEnvelope,
  Value<Uint8List?> localDisplayCiphertext,
  Value<String> deliveryState,
  Value<bool> isRead,
  Value<int> retryCount,
  Value<bool> isStarred,
  Value<bool> isPinned,
  Value<bool> isDeleted,
  Value<String?> editedAt,
  Value<int> rowid,
});

final class $$MessagesTableReferences
    extends BaseReferences<_$MeyaDatabase, $MessagesTable, Message> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConversationsTable _conversationIdTable(_$MeyaDatabase db) => db
      .conversations
      .createAlias('messages__conversation_id__conversations__conversation_id');

  $$ConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<String>('conversation_id')!;

    final manager = $$ConversationsTableTableManager(
      $_db,
      $_db.conversations,
    ).filter((f) => f.conversationId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<Attachment>>
  _attachmentsRefsTable(_$MeyaDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: 'messages__message_id__attachments__message_id',
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager($_db, $_db.attachments)
        .filter(
          (f) => f.messageId.messageId.sqlEquals(
            $_itemColumn<String>('message_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$MeyaDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderDeviceId => $composableBuilder(
    column: $table.senderDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get encryptedEnvelope => $composableBuilder(
    column: $table.encryptedEnvelope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get localDisplayCiphertext => $composableBuilder(
    column: $table.localDisplayCiphertext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deliveryState => $composableBuilder(
    column: $table.deliveryState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStarred => $composableBuilder(
    column: $table.isStarred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ConversationsTableFilterComposer get conversationId {
    final $$ConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableFilterComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$MeyaDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderDeviceId => $composableBuilder(
    column: $table.senderDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get encryptedEnvelope => $composableBuilder(
    column: $table.encryptedEnvelope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get localDisplayCiphertext => $composableBuilder(
    column: $table.localDisplayCiphertext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deliveryState => $composableBuilder(
    column: $table.deliveryState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStarred => $composableBuilder(
    column: $table.isStarred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConversationsTableOrderingComposer get conversationId {
    final $$ConversationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableOrderingComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$MeyaDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get senderDeviceId => $composableBuilder(
    column: $table.senderDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<Uint8List> get encryptedEnvelope => $composableBuilder(
    column: $table.encryptedEnvelope,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get localDisplayCiphertext => $composableBuilder(
    column: $table.localDisplayCiphertext,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deliveryState => $composableBuilder(
    column: $table.deliveryState,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isStarred =>
      $composableBuilder(column: $table.isStarred, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  $$ConversationsTableAnnotationComposer get conversationId {
    final $$ConversationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: $db.conversations,
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConversationsTableAnnotationComposer(
            $db: $db,
            $table: $db.conversations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$MeyaDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, $$MessagesTableReferences),
          Message,
          PrefetchHooks Function({bool conversationId, bool attachmentsRefs})
        > {
  $$MessagesTableTableManager(_$MeyaDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> senderDeviceId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<Uint8List> encryptedEnvelope = const Value.absent(),
                Value<Uint8List?> localDisplayCiphertext = const Value.absent(),
                Value<String> deliveryState = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<bool> isStarred = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String?> editedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion(
                messageId: messageId,
                conversationId: conversationId,
                senderDeviceId: senderDeviceId,
                createdAt: createdAt,
                encryptedEnvelope: encryptedEnvelope,
                localDisplayCiphertext: localDisplayCiphertext,
                deliveryState: deliveryState,
                isRead: isRead,
                retryCount: retryCount,
                isStarred: isStarred,
                isPinned: isPinned,
                isDeleted: isDeleted,
                editedAt: editedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required String conversationId,
                required String senderDeviceId,
                required String createdAt,
                required Uint8List encryptedEnvelope,
                Value<Uint8List?> localDisplayCiphertext = const Value.absent(),
                Value<String> deliveryState = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<bool> isStarred = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String?> editedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesCompanion.insert(
                messageId: messageId,
                conversationId: conversationId,
                senderDeviceId: senderDeviceId,
                createdAt: createdAt,
                encryptedEnvelope: encryptedEnvelope,
                localDisplayCiphertext: localDisplayCiphertext,
                deliveryState: deliveryState,
                isRead: isRead,
                retryCount: retryCount,
                isStarred: isStarred,
                isPinned: isPinned,
                isDeleted: isDeleted,
                editedAt: editedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MessagesTable, Message>(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({conversationId = false, attachmentsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attachmentsRefs) db.attachments,
                  ],
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
                        if (conversationId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.conversationId,
                            referencedTable: $$MessagesTableReferences
                                ._conversationIdTable(db),
                            referencedColumn: $$MessagesTableReferences
                                ._conversationIdTable(db)
                                .conversationId,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (attachmentsRefs)
                        await $_getPrefetchedData<
                          Message,
                          $MessagesTable,
                          Attachment
                        >(
                          currentTable: table,
                          referencedTable: $$MessagesTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MessagesTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.messageId == item.messageId,
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

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$MeyaDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, $$MessagesTableReferences),
      Message,
      PrefetchHooks Function({bool conversationId, bool attachmentsRefs})
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String attachmentId,
      Value<String?> messageId,
      required String encryptedStorageReference,
      required Uint8List encryptedMetadata,
      required int sizeBytes,
      required String mediaType,
      Value<String> transferState,
      required String integrityHash,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> attachmentId,
      Value<String?> messageId,
      Value<String> encryptedStorageReference,
      Value<Uint8List> encryptedMetadata,
      Value<int> sizeBytes,
      Value<String> mediaType,
      Value<String> transferState,
      Value<String> integrityHash,
      Value<int> rowid,
    });

final class $$AttachmentsTableReferences
    extends BaseReferences<_$MeyaDatabase, $AttachmentsTable, Attachment> {
  $$AttachmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MessagesTable _messageIdTable(_$MeyaDatabase db) =>
      db.messages.createAlias('attachments__message_id__messages__message_id');

  $$MessagesTableProcessedTableManager? get messageId {
    final $_column = $_itemColumn<String>('message_id');
    if ($_column == null) return null;
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.messageId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_messageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttachmentsTableFilterComposer
    extends Composer<_$MeyaDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedStorageReference => $composableBuilder(
    column: $table.encryptedStorageReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get encryptedMetadata => $composableBuilder(
    column: $table.encryptedMetadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferState => $composableBuilder(
    column: $table.transferState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get integrityHash => $composableBuilder(
    column: $table.integrityHash,
    builder: (column) => ColumnFilters(column),
  );

  $$MessagesTableFilterComposer get messageId {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$MeyaDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedStorageReference => $composableBuilder(
    column: $table.encryptedStorageReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get encryptedMetadata => $composableBuilder(
    column: $table.encryptedMetadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferState => $composableBuilder(
    column: $table.transferState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get integrityHash => $composableBuilder(
    column: $table.integrityHash,
    builder: (column) => ColumnOrderings(column),
  );

  $$MessagesTableOrderingComposer get messageId {
    final $$MessagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableOrderingComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$MeyaDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get encryptedStorageReference => $composableBuilder(
    column: $table.encryptedStorageReference,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get encryptedMetadata => $composableBuilder(
    column: $table.encryptedMetadata,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get transferState => $composableBuilder(
    column: $table.transferState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get integrityHash => $composableBuilder(
    column: $table.integrityHash,
    builder: (column) => column,
  );

  $$MessagesTableAnnotationComposer get messageId {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$MeyaDatabase,
          $AttachmentsTable,
          Attachment,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (Attachment, $$AttachmentsTableReferences),
          Attachment,
          PrefetchHooks Function({bool messageId})
        > {
  $$AttachmentsTableTableManager(_$MeyaDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> attachmentId = const Value.absent(),
                Value<String?> messageId = const Value.absent(),
                Value<String> encryptedStorageReference = const Value.absent(),
                Value<Uint8List> encryptedMetadata = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<String> transferState = const Value.absent(),
                Value<String> integrityHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                attachmentId: attachmentId,
                messageId: messageId,
                encryptedStorageReference: encryptedStorageReference,
                encryptedMetadata: encryptedMetadata,
                sizeBytes: sizeBytes,
                mediaType: mediaType,
                transferState: transferState,
                integrityHash: integrityHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String attachmentId,
                Value<String?> messageId = const Value.absent(),
                required String encryptedStorageReference,
                required Uint8List encryptedMetadata,
                required int sizeBytes,
                required String mediaType,
                Value<String> transferState = const Value.absent(),
                required String integrityHash,
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                attachmentId: attachmentId,
                messageId: messageId,
                encryptedStorageReference: encryptedStorageReference,
                encryptedMetadata: encryptedMetadata,
                sizeBytes: sizeBytes,
                mediaType: mediaType,
                transferState: transferState,
                integrityHash: integrityHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttachmentsTable, Attachment>(table),
                  $$AttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({messageId = false}) {
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
                    if (messageId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.messageId,
                        referencedTable: $$AttachmentsTableReferences
                            ._messageIdTable(db),
                        referencedColumn: $$AttachmentsTableReferences
                            ._messageIdTable(db)
                            .messageId,
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

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$MeyaDatabase,
      $AttachmentsTable,
      Attachment,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (Attachment, $$AttachmentsTableReferences),
      Attachment,
      PrefetchHooks Function({bool messageId})
    >;
typedef $$ReactionsTableCreateCompanionBuilder = ReactionsCompanion Function({
  required String messageId,
  required String reactorDeviceId,
  required String emoji,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$ReactionsTableUpdateCompanionBuilder = ReactionsCompanion Function({
  Value<String> messageId,
  Value<String> reactorDeviceId,
  Value<String> emoji,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$ReactionsTableFilterComposer
    extends Composer<_$MeyaDatabase, $ReactionsTable> {
  $$ReactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reactorDeviceId => $composableBuilder(
    column: $table.reactorDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReactionsTableOrderingComposer
    extends Composer<_$MeyaDatabase, $ReactionsTable> {
  $$ReactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reactorDeviceId => $composableBuilder(
    column: $table.reactorDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReactionsTableAnnotationComposer
    extends Composer<_$MeyaDatabase, $ReactionsTable> {
  $$ReactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get reactorDeviceId => $composableBuilder(
    column: $table.reactorDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReactionsTableTableManager
    extends
        RootTableManager<
          _$MeyaDatabase,
          $ReactionsTable,
          Reaction,
          $$ReactionsTableFilterComposer,
          $$ReactionsTableOrderingComposer,
          $$ReactionsTableAnnotationComposer,
          $$ReactionsTableCreateCompanionBuilder,
          $$ReactionsTableUpdateCompanionBuilder,
          (Reaction, BaseReferences<_$MeyaDatabase, $ReactionsTable, Reaction>),
          Reaction,
          PrefetchHooks Function()
        > {
  $$ReactionsTableTableManager(_$MeyaDatabase db, $ReactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<String> reactorDeviceId = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReactionsCompanion(
                messageId: messageId,
                reactorDeviceId: reactorDeviceId,
                emoji: emoji,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required String reactorDeviceId,
                required String emoji,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReactionsCompanion.insert(
                messageId: messageId,
                reactorDeviceId: reactorDeviceId,
                emoji: emoji,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReactionsTable, Reaction>(table),
                  BaseReferences<_$MeyaDatabase, $ReactionsTable, Reaction>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$MeyaDatabase,
      $ReactionsTable,
      Reaction,
      $$ReactionsTableFilterComposer,
      $$ReactionsTableOrderingComposer,
      $$ReactionsTableAnnotationComposer,
      $$ReactionsTableCreateCompanionBuilder,
      $$ReactionsTableUpdateCompanionBuilder,
      (Reaction, BaseReferences<_$MeyaDatabase, $ReactionsTable, Reaction>),
      Reaction,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  required String outboxId,
  required String contactId,
  required Uint8List sealedFields,
  required String createdAt,
  Value<int> attempts,
  Value<int> rowid,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<String> outboxId,
  Value<String> contactId,
  Value<Uint8List> sealedFields,
  Value<String> createdAt,
  Value<int> attempts,
  Value<int> rowid,
});

class $$OutboxTableFilterComposer
    extends Composer<_$MeyaDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get outboxId => $composableBuilder(
    column: $table.outboxId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get sealedFields => $composableBuilder(
    column: $table.sealedFields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$MeyaDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get outboxId => $composableBuilder(
    column: $table.outboxId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactId => $composableBuilder(
    column: $table.contactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get sealedFields => $composableBuilder(
    column: $table.sealedFields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$MeyaDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get outboxId =>
      $composableBuilder(column: $table.outboxId, builder: (column) => column);

  GeneratedColumn<String> get contactId =>
      $composableBuilder(column: $table.contactId, builder: (column) => column);

  GeneratedColumn<Uint8List> get sealedFields => $composableBuilder(
    column: $table.sealedFields,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$MeyaDatabase,
          $OutboxTable,
          OutboxData,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (
            OutboxData,
            BaseReferences<_$MeyaDatabase, $OutboxTable, OutboxData>,
          ),
          OutboxData,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$MeyaDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> outboxId = const Value.absent(),
                Value<String> contactId = const Value.absent(),
                Value<Uint8List> sealedFields = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion(
                outboxId: outboxId,
                contactId: contactId,
                sealedFields: sealedFields,
                createdAt: createdAt,
                attempts: attempts,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String outboxId,
                required String contactId,
                required Uint8List sealedFields,
                required String createdAt,
                Value<int> attempts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion.insert(
                outboxId: outboxId,
                contactId: contactId,
                sealedFields: sealedFields,
                createdAt: createdAt,
                attempts: attempts,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxData>(table),
                  BaseReferences<_$MeyaDatabase, $OutboxTable, OutboxData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$MeyaDatabase,
      $OutboxTable,
      OutboxData,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxData, BaseReferences<_$MeyaDatabase, $OutboxTable, OutboxData>),
      OutboxData,
      PrefetchHooks Function()
    >;
typedef $$MeyaGroupsTableCreateCompanionBuilder = MeyaGroupsCompanion Function({
  required String groupId,
  required String name,
  required String adminDeviceId,
  Value<int> revision,
  required String createdAt,
  required String updatedAt,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$MeyaGroupsTableUpdateCompanionBuilder = MeyaGroupsCompanion Function({
  Value<String> groupId,
  Value<String> name,
  Value<String> adminDeviceId,
  Value<int> revision,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<bool> isActive,
  Value<int> rowid,
});

final class $$MeyaGroupsTableReferences
    extends BaseReferences<_$MeyaDatabase, $MeyaGroupsTable, MeyaGroup> {
  $$MeyaGroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GroupMembersTable, List<GroupMember>>
  _groupMembersRefsTable(_$MeyaDatabase db) => MultiTypedResultKey.fromTable(
    db.groupMembers,
    aliasName: 'meya_groups__group_id__group_members__group_id',
  );

  $$GroupMembersTableProcessedTableManager get groupMembersRefs {
    final manager = $$GroupMembersTableTableManager($_db, $_db.groupMembers)
        .filter(
          (f) => f.groupId.groupId.sqlEquals($_itemColumn<String>('group_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_groupMembersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MeyaGroupsTableFilterComposer
    extends Composer<_$MeyaDatabase, $MeyaGroupsTable> {
  $$MeyaGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get adminDeviceId => $composableBuilder(
    column: $table.adminDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> groupMembersRefs(
    Expression<bool> Function($$GroupMembersTableFilterComposer f) f,
  ) {
    final $$GroupMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupMembers,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupMembersTableFilterComposer(
            $db: $db,
            $table: $db.groupMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MeyaGroupsTableOrderingComposer
    extends Composer<_$MeyaDatabase, $MeyaGroupsTable> {
  $$MeyaGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get adminDeviceId => $composableBuilder(
    column: $table.adminDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MeyaGroupsTableAnnotationComposer
    extends Composer<_$MeyaDatabase, $MeyaGroupsTable> {
  $$MeyaGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get adminDeviceId => $composableBuilder(
    column: $table.adminDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> groupMembersRefs<T extends Object>(
    Expression<T> Function($$GroupMembersTableAnnotationComposer a) f,
  ) {
    final $$GroupMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groupMembers,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.groupMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MeyaGroupsTableTableManager
    extends
        RootTableManager<
          _$MeyaDatabase,
          $MeyaGroupsTable,
          MeyaGroup,
          $$MeyaGroupsTableFilterComposer,
          $$MeyaGroupsTableOrderingComposer,
          $$MeyaGroupsTableAnnotationComposer,
          $$MeyaGroupsTableCreateCompanionBuilder,
          $$MeyaGroupsTableUpdateCompanionBuilder,
          (MeyaGroup, $$MeyaGroupsTableReferences),
          MeyaGroup,
          PrefetchHooks Function({bool groupMembersRefs})
        > {
  $$MeyaGroupsTableTableManager(_$MeyaDatabase db, $MeyaGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeyaGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeyaGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeyaGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> adminDeviceId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeyaGroupsCompanion(
                groupId: groupId,
                name: name,
                adminDeviceId: adminDeviceId,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required String name,
                required String adminDeviceId,
                Value<int> revision = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeyaGroupsCompanion.insert(
                groupId: groupId,
                name: name,
                adminDeviceId: adminDeviceId,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MeyaGroupsTable, MeyaGroup>(table),
                  $$MeyaGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupMembersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (groupMembersRefs) db.groupMembers],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (groupMembersRefs)
                    await $_getPrefetchedData<
                      MeyaGroup,
                      $MeyaGroupsTable,
                      GroupMember
                    >(
                      currentTable: table,
                      referencedTable: $$MeyaGroupsTableReferences
                          ._groupMembersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MeyaGroupsTableReferences(
                            db,
                            table,
                            p0,
                          ).groupMembersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.groupId == item.groupId,
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

typedef $$MeyaGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$MeyaDatabase,
      $MeyaGroupsTable,
      MeyaGroup,
      $$MeyaGroupsTableFilterComposer,
      $$MeyaGroupsTableOrderingComposer,
      $$MeyaGroupsTableAnnotationComposer,
      $$MeyaGroupsTableCreateCompanionBuilder,
      $$MeyaGroupsTableUpdateCompanionBuilder,
      (MeyaGroup, $$MeyaGroupsTableReferences),
      MeyaGroup,
      PrefetchHooks Function({bool groupMembersRefs})
    >;
typedef $$GroupMembersTableCreateCompanionBuilder =
    GroupMembersCompanion Function({
      required String groupId,
      required String deviceId,
      required String identityId,
      required String displayName,
      required String identityPublicKey,
      required String addedAt,
      Value<int> rowid,
    });
typedef $$GroupMembersTableUpdateCompanionBuilder =
    GroupMembersCompanion Function({
      Value<String> groupId,
      Value<String> deviceId,
      Value<String> identityId,
      Value<String> displayName,
      Value<String> identityPublicKey,
      Value<String> addedAt,
      Value<int> rowid,
    });

final class $$GroupMembersTableReferences
    extends BaseReferences<_$MeyaDatabase, $GroupMembersTable, GroupMember> {
  $$GroupMembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MeyaGroupsTable _groupIdTable(_$MeyaDatabase db) => db.meyaGroups
      .createAlias('group_members__group_id__meya_groups__group_id');

  $$MeyaGroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$MeyaGroupsTableTableManager(
      $_db,
      $_db.meyaGroups,
    ).filter((f) => f.groupId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GroupMembersTableFilterComposer
    extends Composer<_$MeyaDatabase, $GroupMembersTable> {
  $$GroupMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MeyaGroupsTableFilterComposer get groupId {
    final $$MeyaGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.meyaGroups,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeyaGroupsTableFilterComposer(
            $db: $db,
            $table: $db.meyaGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupMembersTableOrderingComposer
    extends Composer<_$MeyaDatabase, $GroupMembersTable> {
  $$GroupMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MeyaGroupsTableOrderingComposer get groupId {
    final $$MeyaGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.meyaGroups,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeyaGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.meyaGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupMembersTableAnnotationComposer
    extends Composer<_$MeyaDatabase, $GroupMembersTable> {
  $$GroupMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$MeyaGroupsTableAnnotationComposer get groupId {
    final $$MeyaGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.meyaGroups,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeyaGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.meyaGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupMembersTableTableManager
    extends
        RootTableManager<
          _$MeyaDatabase,
          $GroupMembersTable,
          GroupMember,
          $$GroupMembersTableFilterComposer,
          $$GroupMembersTableOrderingComposer,
          $$GroupMembersTableAnnotationComposer,
          $$GroupMembersTableCreateCompanionBuilder,
          $$GroupMembersTableUpdateCompanionBuilder,
          (GroupMember, $$GroupMembersTableReferences),
          GroupMember,
          PrefetchHooks Function({bool groupId})
        > {
  $$GroupMembersTableTableManager(_$MeyaDatabase db, $GroupMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> identityId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> identityPublicKey = const Value.absent(),
                Value<String> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupMembersCompanion(
                groupId: groupId,
                deviceId: deviceId,
                identityId: identityId,
                displayName: displayName,
                identityPublicKey: identityPublicKey,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required String deviceId,
                required String identityId,
                required String displayName,
                required String identityPublicKey,
                required String addedAt,
                Value<int> rowid = const Value.absent(),
              }) => GroupMembersCompanion.insert(
                groupId: groupId,
                deviceId: deviceId,
                identityId: identityId,
                displayName: displayName,
                identityPublicKey: identityPublicKey,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GroupMembersTable, GroupMember>(table),
                  $$GroupMembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false}) {
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
                    if (groupId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.groupId,
                        referencedTable: $$GroupMembersTableReferences
                            ._groupIdTable(db),
                        referencedColumn: $$GroupMembersTableReferences
                            ._groupIdTable(db)
                            .groupId,
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

typedef $$GroupMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$MeyaDatabase,
      $GroupMembersTable,
      GroupMember,
      $$GroupMembersTableFilterComposer,
      $$GroupMembersTableOrderingComposer,
      $$GroupMembersTableAnnotationComposer,
      $$GroupMembersTableCreateCompanionBuilder,
      $$GroupMembersTableUpdateCompanionBuilder,
      (GroupMember, $$GroupMembersTableReferences),
      GroupMember,
      PrefetchHooks Function({bool groupId})
    >;

class $MeyaDatabaseManager {
  final _$MeyaDatabase _db;
  $MeyaDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$ContactDevicesTableTableManager get contactDevices =>
      $$ContactDevicesTableTableManager(_db, _db.contactDevices);
  $$ConnectionRequestsTableTableManager get connectionRequests =>
      $$ConnectionRequestsTableTableManager(_db, _db.connectionRequests);
  $$ConversationsTableTableManager get conversations =>
      $$ConversationsTableTableManager(_db, _db.conversations);
  $$ConversationParticipantsTableTableManager get conversationParticipants =>
      $$ConversationParticipantsTableTableManager(
        _db,
        _db.conversationParticipants,
      );
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$ReactionsTableTableManager get reactions =>
      $$ReactionsTableTableManager(_db, _db.reactions);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$MeyaGroupsTableTableManager get meyaGroups =>
      $$MeyaGroupsTableTableManager(_db, _db.meyaGroups);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db, _db.groupMembers);
}
