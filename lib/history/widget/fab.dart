import 'dart:async';

import 'package:kilt/client/client.dart';
import 'package:kilt/history/history.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';

class HistorySearchFab extends StatelessWidget {
  const HistorySearchFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryController>(
      builder: (context, controller, child) => FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: () async {
          final client = context.read<Client>();
          final locale = Localizations.localeOf(context);

          unawaited(_openPicker(context, controller, client, locale));
        },
      ),
    );
  }

  Future<void> _openPicker(
    BuildContext context,
    HistoryController controller,
    Client client,
    Locale locale,
  ) async {
    List<DateTime> days = await client.histories.days();
    if (days.isEmpty) {
      days.add(DateTime.now());
    }

    if (!context.mounted) return;

    final search = HistoryQuery.from(controller.search);
    final result = await showDatePicker(
      context: context,
      initialDate: search.date ?? DateTime.now(),
      firstDate: days.first,
      lastDate: days.last,
      locale: locale,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      selectableDayPredicate: (value) =>
          days.any((e) => DateUtils.isSameDay(value, e)),
    );

    if (!context.mounted) return;
    final scrollController = PrimaryScrollController.of(context);

    if (result != search.date) {
      if (scrollController.hasClients) {
        await scrollController.animateTo(
          0,
          duration: defaultAnimationDuration,
          curve: Curves.easeInOut,
        );
      }

      controller.search = search.copy()..date = result;
    }
  }
}
