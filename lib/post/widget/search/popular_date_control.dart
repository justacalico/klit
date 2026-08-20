// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/settings/data/settings.dart';
import 'package:kilt/shared/shared.dart';

class PopularDateInlineBar extends StatelessWidget {
  const PopularDateInlineBar({super.key, required this.controller});

  final HotPostController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final subtle = TextStyle(color: dimTextColor(context));
    final bg = theme.brightness == Brightness.dark
        ? theme.cardColor.withValues(alpha: 0.55)
        : theme.colorScheme.surfaceContainerHigh;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final label = popularDateLabel(controller, l10n);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(l10n.postPopular),
                      const Spacer(),
                      Text(label, style: subtle),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ScaleControl(controller: controller),
                  if (controller.scale != PopularScale.hot) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          tooltip: l10n.commonPrevious,
                          onPressed: controller.prev,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(label, style: theme.textTheme.bodyLarge),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.commonNext,
                          onPressed: controller.canNext ? controller.next : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                        const SizedBox(width: 6),
                        TextButton.icon(
                          onPressed: () => _pickDate(context),
                          icon: const Icon(Icons.date_range),
                          label: Text(l10n.postPickDate),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final initial = controller.referenceDate.isAfter(now)
        ? now
        : controller.referenceDate;
    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2007),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (result == null) return;
    controller.setReferenceDate(result);
  }
}

class _ScaleControl extends StatelessWidget {
  const _ScaleControl({required this.controller});

  final HotPostController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showHot = context.watch<Settings>().popularHotTab.value;
    final segments = <PopularScale, Widget>{
      PopularScale.day: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(l10n.postDay),
      ),
      PopularScale.week: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(l10n.postWeek),
      ),
      PopularScale.month: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(l10n.postMonth),
      ),
      if (showHot)
        PopularScale.hot: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(l10n.postHot),
        ),
    };
    return CupertinoSlidingSegmentedControl<PopularScale>(
      groupValue: segments.keys.contains(controller.scale)
          ? controller.scale
          : PopularScale.day,
      onValueChanged: (value) {
        if (value == null) return;
        controller.setScale(value);
      },
      children: segments,
    );
  }
}

String popularDateLabel(HotPostController controller, AppLocalizations l10n) {
  if (controller.scale == PopularScale.hot) {
    return l10n.postHot;
  }

  final d = DateUtils.dateOnly(controller.referenceDate);
  final today = DateUtils.dateOnly(DateTime.now());

  if (controller.scale == PopularScale.day) {
    if (d == today) return l10n.commonToday;
    if (d == today.subtract(const Duration(days: 1))) return l10n.commonYesterday;
    return DateFormat.yMMMd().format(d);
  }

  if (controller.scale == PopularScale.month) {
    return DateFormat.yMMMM().format(d);
  }

  final start = d.subtract(Duration(days: d.weekday - DateTime.monday));
  var end = start.add(const Duration(days: 6));
  if (end.isAfter(today)) end = today;
  if (start.month == end.month) {
    return '${DateFormat.MMMd().format(start)} – ${DateFormat.d().format(end)}';
  }
  return '${DateFormat.MMMd().format(start)} – ${DateFormat.MMMd().format(end)}';
}
