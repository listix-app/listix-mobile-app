import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../lists/domain/entities/shopping_list.dart';
import '../failures/backup_failure.dart';

class BackupData {
  static const int currentSchemaVersion = 1;

  final int version;
  final DateTime exportedAt;
  final String appVersion;
  final List<ShoppingList> lists;

  const BackupData({
    required this.version,
    required this.exportedAt,
    required this.appVersion,
    required this.lists,
  });

  int get totalLists => lists.length;

  int get totalItems => lists.fold(0, (sum, list) => sum + list.items.length);

  BackupData copyWith({
    int? version,
    DateTime? exportedAt,
    String? appVersion,
    List<ShoppingList>? lists,
  }) {
    return BackupData(
      version: version ?? this.version,
      exportedAt: exportedAt ?? this.exportedAt,
      appVersion: appVersion ?? this.appVersion,
      lists: lists ?? this.lists,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'exportedAt': exportedAt.toIso8601String(),
    'appVersion': appVersion,
    'lists': lists.map((l) => l.toJson()).toList(),
  };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['version'];
    if (rawVersion is! int) {
      throw const BackupFailure('Invalid backup schema version');
    }

    final rawExportedAt = json['exportedAt'];
    DateTime parsedExportedAt;
    if (rawExportedAt is String) {
      try {
        parsedExportedAt = DateTime.parse(rawExportedAt);
      } catch (_) {
        throw const BackupFailure('Invalid backup export timestamp');
      }
    } else {
      parsedExportedAt = DateTime.now();
    }

    final rawAppVersion = json['appVersion'] as String? ?? '1.0.0';

    final rawLists = json['lists'];
    if (rawLists is! List) {
      throw const BackupFailure('Invalid backup lists payload');
    }

    final parsedLists = <ShoppingList>[];
    for (final item in rawLists) {
      if (item is Map<String, dynamic>) {
        parsedLists.add(ShoppingList.fromJson(item));
      } else if (item is Map) {
        parsedLists.add(ShoppingList.fromJson(Map<String, dynamic>.from(item)));
      } else {
        throw const BackupFailure('Invalid shopping list item in backup');
      }
    }

    return BackupData(
      version: rawVersion,
      exportedAt: parsedExportedAt,
      appVersion: rawAppVersion,
      lists: parsedLists,
    );
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  String toPlainTextSummary() {
    final buffer = StringBuffer();
    buffer.writeln('# Listix Backup Export');
    buffer.writeln(
      'Exported: ${exportedAt.year}-${exportedAt.month.toString().padLeft(2, '0')}-${exportedAt.day.toString().padLeft(2, '0')} ${exportedAt.hour.toString().padLeft(2, '0')}:${exportedAt.minute.toString().padLeft(2, '0')}',
    );
    buffer.writeln('Total lists: $totalLists');
    buffer.writeln('Total items: $totalItems');
    buffer.writeln();

    for (final list in lists) {
      buffer.writeln('## ${list.name}');
      if (list.items.isEmpty) {
        buffer.writeln('- (Empty)');
      } else {
        for (final item in list.items) {
          final mark = item.isCompleted ? '[x]' : '[ ]';
          buffer.writeln('- $mark ${item.title}');
        }
      }
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  String toCsv() {
    final buffer = StringBuffer();
    buffer.writeln('List,Item,Status,Created At');

    for (final list in lists) {
      if (list.items.isEmpty) {
        buffer.writeln(
          '${_escapeCsv(list.name)},"","","${list.createdAt.toIso8601String()}"',
        );
      } else {
        for (final item in list.items) {
          final status = item.isCompleted ? 'Completed' : 'Pending';
          buffer.writeln(
            '${_escapeCsv(list.name)},${_escapeCsv(item.title)},"$status","${item.createdAt.toIso8601String()}"',
          );
        }
      }
    }

    return buffer.toString().trimRight();
  }

  static String _escapeCsv(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupData &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          exportedAt == other.exportedAt &&
          appVersion == other.appVersion &&
          listEquals(lists, other.lists);

  @override
  int get hashCode =>
      Object.hash(version, exportedAt, appVersion, Object.hashAll(lists));
}
