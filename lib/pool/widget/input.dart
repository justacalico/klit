// SPDX-License-Identifier: AGPL-3.0

import 'package:cached_network_image/cached_network_image.dart';
import 'package:kilt/app/app.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/history/history.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/pool/data/controller.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PoolsPageFloatingActionButton extends StatelessWidget {
  const PoolsPageFloatingActionButton({super.key, required this.controller});

  final PoolController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SearchPromptFloatingActionButton(
      tags: controller.query,
      onSubmit: (value) => controller.query = value,
      filters: [
        WrapperFilterConfig(
          wrapper: (value) => 'search[$value]',
          unwrapper: (value) => value.substring(7, value.length - 1),
          filters: [
            PrimaryFilterConfig(
              filter: PoolNameFilterTag(tag: 'name_matches'),
              filters: [
                TextFilterTag(
                  tag: 'description_matches',
                  name: l10n.commonDescription,
                  icon: Icon(Icons.description),
                ),
                TextFilterTag(
                  tag: 'creator_name',
                  name: l10n.poolCreator,
                  icon: Icon(Icons.person),
                ),
                ToggleFilterTag(
                  tag: 'is_active',
                  name: l10n.commonActive,
                  enabled: 'true',
                  disabled: 'false',
                  description: l10n.poolIsActive,
                ),
                ChoiceFilterTag(
                  tag: 'category',
                  name: l10n.poolCategory,
                  icon: Icon(Icons.category),
                  options: [
                    ChoiceFilterTagValue(value: null, name: l10n.commonSortDefault),
                    ChoiceFilterTagValue(value: 'series', name: l10n.poolCategorySeries),
                    ChoiceFilterTagValue(
                      value: 'collection',
                      name: l10n.poolCategoryCollection,
                    ),
                  ],
                ),
                ChoiceFilterTag(
                  tag: 'order',
                  name: l10n.commonSortBy,
                  icon: Icon(Icons.sort),
                  options: [
                    ChoiceFilterTagValue(value: null, name: l10n.commonSortDefault),
                    ChoiceFilterTagValue(value: 'name', name: l10n.commonName),
                    ChoiceFilterTagValue(value: 'created_at', name: l10n.commonSortCreated),
                    ChoiceFilterTagValue(value: 'updated_at', name: l10n.commonSortUpdated),
                    ChoiceFilterTagValue(
                      value: 'post_count',
                      name: l10n.commonSortPostCount,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _PoolSearchResult {
  const _PoolSearchResult({
    required this.time,
    required this.name,
    this.thumbnail,
    this.link,
  });

  final DateTime time;
  final String name;
  final String? thumbnail;
  final String? link;
}

class PoolNameFilterTag extends BuilderFilterTag {
  PoolNameFilterTag({required super.tag, super.name})
    : super(builder: (context, state) => PoolNameFilter(state: state));
}

class PoolNameFilter extends StatelessWidget {
  const PoolNameFilter({super.key, required this.state});

  final FilterTagState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    FilterTagThemeData theme = FilterTagTheme.of(context);
    return SubTextValue(
      value: state.value,
      onChanged: state.onChanged,
      builder: (context, controller) =>
          AutocompleteTextField<_PoolSearchResult>(
            direction: VerticalDirection.up,
            submit: (value) => state.onSubmit?.call(value),
            controller: controller,
            labelText: l10n.poolPoolTitleField,
            decoration: theme.decoration,
            focusNode: theme.focusNode,
            onSelected: (value) {
              if (value.link != null) {
                Navigator.of(context).pop();
                const E621LinkParser().open(context, value.link!);
              } else {
                controller.text = '${value.name} ';
                controller.setFocusToEnd();
              }
            },
            suggestionsCallback: (value) async {
              value = value.trim();
              final client = context.read<Client>();
              return (await client.histories.page(
                    page: 1,
                    query: HistoryQuery(
                      date: DateTime.now(),
                      link: r'/pools/.*',
                      title:
                          r'.*' +
                          RegExp.escape(value.replaceAll(' ', '_')) +
                          r'.*',
                    ),
                    limit: 4,
                  ))
                  .where((e) => e.title != null)
                  .map(
                    (e) => _PoolSearchResult(
                      time: e.visitedAt,
                      name: e.title!.replaceAll('_', ' '),
                      thumbnail: e.thumbnails.isNotEmpty
                          ? e.thumbnails.first
                          : null,
                      link: e.link,
                    ),
                  )
                  .toList();
            },
            itemBuilder: (context, value) => ListTile(
              title: Text(value.name),
              leading: value.thumbnail != null
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(4),
                        ),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: CachedNetworkImage(
                            imageUrl: value.thumbnail!,
                            errorWidget: defaultErrorBuilder,
                            fit: BoxFit.cover,
                            cacheManager: context.read<BaseCacheManager>(),
                          ),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        value.link != null
                            ? Icons.open_in_new
                            : Icons.lightbulb_outline,
                      ),
                    ),
            ),
          ),
    );
  }
}
