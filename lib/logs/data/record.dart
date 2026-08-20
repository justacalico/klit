// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

class LogString {
  LogString({
    required this.time,
    required this.level,
    required this.logger,
    required this.body,
  });

  factory LogString.fromRecord(LogRecord record) {
    return LogString(
      time: record.time,
      level: record.level,
      logger: record.loggerName,
      body: _buildRecordMessage(record),
    );
  }

  static String _buildRecordMessage(LogRecord record) {
    final buffer = StringBuffer();
    buffer.writeln(record.message);
    if (record.error != null) {
      buffer.write(
        prettyLogObject(
          record.error!,
          header: switch (record.level) {
            final level when level >= Level.FINE => 'Data',
            _ => 'Error',
          },
        ),
      );
    }
    if (record.error != null && record.stackTrace != null) {
      buffer.write(prettyLogObject(record.stackTrace!, header: 'Stacktrace'));
    }
    return buffer.toString().trim();
  }

  static List<LogString> parse(String value) {
    final logs = <LogString>[];
    final fullRegex = RegExp(
      r'^\s*(?<level>'
      '(${Level.LEVELS.map((e) => e.name).join('|')})'
      r')\s*\|\s*(?<time>'
      r'\d{2}:\d{2}:\d{2}\.\d{3}'
      r')\s*\|\s*(?<loggerName>[^:\n]+?):',
      caseSensitive: false,
      multiLine: true,
    );
    final matches = fullRegex.allMatches(value).toList();
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final time = logStringDateFormat.parse(
        match.namedGroup('time')!.trim(),
      );
      final level = Level.LEVELS.singleWhere(
        (e) => e.name == match.namedGroup('level')!.trim().toUpperCase(),
      );
      final loggerName = match.namedGroup('loggerName')!.trim();
      RegExpMatch? next;
      if (i + 1 < matches.length) {
        next = matches[i + 1];
      }
      final body = value.substring(match.end, next?.start).trim();
      logs.add(
        LogString(time: time, level: level, logger: loggerName, body: body),
      );
    }
    return logs;
  }

  final DateTime time;
  final Level level;
  final String logger;
  final String body;

  @override
  String toString() =>
      '$level | ${logStringDateFormat.format(time)} | $logger: $body';
}

final DateFormat logStringDateFormat = DateFormat('HH:mm:ss.SSS');

extension LogStringRecord on LogRecord {
  String toFullString() => LogString.fromRecord(this).toString();
}

String prettyLogObject(Object data, {String? header, int? chars}) {
  final buffer = StringBuffer();
  String value;

  value = '║  ${data.toString().replaceAll('\n', '\n║  ')}';

  if (chars != null) {
    value = value.split('').take(chars).join();
  }

  final fullHeader = header != null ? ' $header ' : '';
  buffer.writeln('╔$fullHeader${'═' * (90 - fullHeader.length)}╗');
  buffer.writeln('║');
  if (value.isNotEmpty) {
    buffer.writeln(value);
  }
  buffer.writeln('║');
  buffer.writeln('╚${'═' * 90}╝');
  return buffer.toString();
}

extension LogLevelColor on Level? {
  Color get color {
    final level = this;
    if (level == null) {
      return Colors.grey[400]!;
    }
    if (level <= Level.FINER) {
      return Colors.blue[200]!;
    }
    if (level <= Level.FINE) {
      return Colors.blue[400]!;
    }
    if (level <= Level.INFO) {
      return Colors.green[400]!;
    }
    if (level <= Level.WARNING) {
      return Colors.orange[400]!;
    }
    if (level <= Level.SEVERE) {
      return Colors.red[400]!;
    }
    return Colors.red[800]!;
  }
}
