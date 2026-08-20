// SPDX-License-Identifier: AGPL-3.0

import 'package:flutter/material.dart';
import 'package:kilt/logs/logs.dart';
import 'package:kilt/shared/shared.dart';
import 'package:recase/recase.dart';

class LogStringCard extends StatelessWidget {
  const LogStringCard({super.key, required this.item, this.expanded = false});

  final LogString item;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final long = '${item.logger}: ${item.body}';
    final short = long.ellipse(100).split('\n').first;
    return LogRecordExpandable(
      key: ValueKey(item),
      color: item.level.color,
      title: Text(
        '${item.level.name.pascalCase} | ${logStringDateFormat.format(item.time)}',
      ),
      content: Text(short),
      fullContent: short != long ? LogStringBody(item: item) : null,
      expanded: expanded,
    );
  }
}

class LogStringBody extends StatelessWidget {
  const LogStringBody({super.key, required this.item});

  final LogString item;

  @override
  Widget build(BuildContext context) {
    var value = '${item.logger}: ${item.body}';
    value = value.replaceAllMapped(RegExp(r'\r\n'), (_) => '\n');
    final sectionRegex = RegExp(
      r'╔(?<title>[^═╗\n]*)(═*╗)?\n(?<content>(║.*?\n)*)(╚═*╝)',
    );
    final matches = sectionRegex.allMatches(value).toList();
    if (matches.isEmpty) {
      return Text(value.ellipse(500).split('\n').take(10).join('\n'));
    }
    var processed = 0;
    final spans = <InlineSpan>[];
    for (final match in matches) {
      spans.add(TextSpan(text: value.substring(processed, match.start)));
      processed = match.end;
      final title = match.namedGroup('title')!.trim();
      var content = match
          .namedGroup('content')!
          .trim()
          .split('\n')
          .map((e) => e.substring(1).trim())
          .join('\n');
      final short = content.ellipse(100);
      content = content.ellipse(1000).split('\n').take(10).join('\n');
      spans.add(
        WidgetSpan(
          child: LogRecordExpandable(
            key: ValueKey(Object.hash(item, content)),
            color: item.level.color,
            title: Text(title),
            content: Text(short.trim().isNotEmpty ? short : 'No content'),
            fullContent: short != content ? Text(content) : null,
          ),
        ),
      );
    }
    spans.add(TextSpan(text: value.substring(processed)));

    return Text.rich(TextSpan(children: spans));
  }
}
