import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klit/post/post.dart';
import 'package:klit/shared/shared.dart';

class PopularDateButton extends StatelessWidget {
  const PopularDateButton({super.key, required this.controller});

  final HotPostController controller;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: () => _open(context),
      child: const Icon(Icons.calendar_month),
    );
  }

  Future<void> _open(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (context) => _PopularDateSheet(controller: controller),
    );
  }
}

class _PopularDateSheet extends StatelessWidget {
  const _PopularDateSheet({required this.controller});

  final HotPostController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium;
    final subtle = TextStyle(color: dimTextColor(context));
    final w = MediaQuery.sizeOf(context).width;
    final clearBottomNav = w < 900;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final label = popularDateLabel(controller);
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                clearBottomNav ? 110 : 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Popular', style: titleStyle),
                      ),
                      Text(label, style: subtle),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ScaleControl(controller: controller),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous',
                        onPressed: controller.prev,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(label, style: theme.textTheme.bodyLarge),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next',
                        onPressed: controller.canNext ? controller.next : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _pickDate(context),
                      icon: const Icon(Icons.date_range),
                      label: const Text('Pick date'),
                    ),
                  ),
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
      firstDate: DateTime(2007, 1, 1),
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
    return CupertinoSlidingSegmentedControl<PopularScale>(
      groupValue: controller.scale,
      onValueChanged: (value) {
        if (value == null) return;
        controller.setScale(value);
      },
      children: const {
        PopularScale.day: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text('Day'),
        ),
        PopularScale.week: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text('Week'),
        ),
        PopularScale.month: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text('Month'),
        ),
      },
    );
  }
}

String popularDateLabel(HotPostController controller) {
  final d = DateUtils.dateOnly(controller.referenceDate);
  final today = DateUtils.dateOnly(DateTime.now());

  if (controller.scale == PopularScale.day) {
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
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

