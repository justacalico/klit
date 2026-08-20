// SPDX-License-Identifier: AGPL-3.0

import 'package:intl/intl.dart';
import 'package:kilt/shared/shared.dart';
import 'package:path/path.dart';

final DateFormat logFileDateFormat = DateFormat('yyyy-MM-dd-HH-mm-ss-SSS');

class LogFileInfo {
  LogFileInfo({required this.path, required this.date, required this.type});

  factory LogFileInfo.parse(String path) {
    var raw = basenameWithoutExtension(path);
    String? type = extension(raw);
    if (type.isNotEmpty) {
      type = type.substring(1);
      raw = basenameWithoutExtension(raw);
    } else {
      type = null;
    }
    final date = logFileDateFormat.parse(raw);
    return LogFileInfo(path: path, date: date, type: type);
  }

  final String path;
  final DateTime date;
  final String? type;

  @override
  String toString() =>
      '${DateFormatting.dateTime(date)} ${type != null ? ' ($type)' : ''}';
}
