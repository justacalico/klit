import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart' as intl_dates;
import 'package:intl/intl.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';

/// Primitive default date formatting.
/// Has no translation support.
abstract final class DateFormatting {
  static Future<void> ensureInitialized() =>
      intl_dates.initializeDateFormatting();

  static String dateTime(DateTime dateTime) =>
      DateFormat('yyyy/M/d ', Platform.localeName).add_jm().format(dateTime);
  static String date(DateTime date) =>
      DateFormat('yyyy/M/d').format(date);
  static String time(DateTime time) =>
      DateFormat.jm(Platform.localeName).format(time);

  static String named(DateTime date, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    DateTime today = DateUtils.dateOnly(DateTime.now());
    if (today.isAtSameMomentAs(DateUtils.dateOnly(date))) {
      return l10n?.commonToday ?? 'Today';
    }
    if (today
        .subtract(const Duration(days: 1))
        .isAtSameMomentAs(DateUtils.dateOnly(date))) {
      return l10n?.commonYesterday ?? 'Yesterday';
    }
    if (today.subtract(const Duration(days: 7)).isBefore(date)) {
      return DateFormat.EEEE().format(date);
    }
    return DateFormatting.date(date);
  }
}
