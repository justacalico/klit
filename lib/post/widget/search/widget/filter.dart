import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/post/post.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';
import 'package:flutter/material.dart';

class PostsPageFloatingActionButton extends StatelessWidget {
  const PostsPageFloatingActionButton({super.key, required this.controller});

  final PostController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SearchPromptFloatingActionButton(
      tags: controller.query,
      onSubmit: (value) => controller.query = value,
      filters: [
        PrimaryFilterConfig(
          filter: TagSearchFilterTag(tag: 'tags', name: l10n.commonTags),
          filters: [
            NestedFilterTag(
              tag: 'tags',
              decode: TagMap.new,
              encode: (value) => TagMap.from(value).toString(),
              filters: [
                NumberRangeFilterTag(
                  tag: 'score',
                  name: l10n.commonScore,
                  min: 0,
                  max: 100,
                  division: 10,
                  initial: NumberRange(
                    20,
                    comparison: NumberComparison.greaterThanOrEqual,
                  ),
                  icon: const Icon(Icons.arrow_upward),
                ),
                NumberRangeFilterTag(
                  tag: 'favcount',
                  name: l10n.postFilterFavoriteCount,
                  min: 0,
                  max: 100,
                  division: 10,
                  initial: NumberRange(
                    20,
                    comparison: NumberComparison.greaterThanOrEqual,
                  ),
                  icon: const Icon(Icons.favorite),
                ),
                ChoiceFilterTag(
                  tag: 'order',
                  name: l10n.commonSortBy,
                  icon: const Icon(Icons.sort),
                  options: [
                    ChoiceFilterTagValue(value: null, name: l10n.commonSortDefault),
                    ChoiceFilterTagValue(value: 'score', name: l10n.commonScore),
                    ChoiceFilterTagValue(value: 'favcount', name: l10n.commonSortFavorites),
                    ChoiceFilterTagValue(value: 'rank', name: l10n.commonSortRank),
                    ChoiceFilterTagValue(value: 'random', name: l10n.commonSortRandom),
                  ],
                ),
                ChoiceFilterTag(
                  tag: 'rating',
                  name: l10n.commonRating,
                  icon: const Icon(Icons.question_mark),
                  options: [
                    ChoiceFilterTagValue(value: null, name: l10n.commonRatingAll),
                    ChoiceFilterTagValue(value: 's', name: l10n.commonRatingSafe),
                    ChoiceFilterTagValue(value: 'q', name: l10n.commonRatingQuestionable),
                    ChoiceFilterTagValue(value: 'e', name: l10n.commonRatingExplicit),
                  ],
                ),
                ToggleFilterTag(
                  tag: 'inpool',
                  name: l10n.postFilterPool,
                  enabled: 'true',
                  disabled: 'false',
                  description: l10n.postFilterHasPool,
                ),
                ToggleFilterTag(
                  tag: 'ischild',
                  name: l10n.postFilterChild,
                  enabled: 'true',
                  disabled: 'false',
                  description: l10n.postFilterIsChild,
                ),
                ToggleFilterTag(
                  tag: 'isparent',
                  name: l10n.postParent,
                  enabled: 'true',
                  disabled: 'false',
                  description: l10n.postFilterIsParent,
                ),
                ChoiceFilterTag(
                  tag: 'date',
                  name: l10n.postFilterUploadDate,
                  icon: const Icon(Icons.date_range),
                  options: [
                    ChoiceFilterTagValue(value: null, name: l10n.postFilterDateAll),
                    ChoiceFilterTagValue(value: 'day', name: l10n.postFilterDateLastDay),
                    ChoiceFilterTagValue(value: 'week', name: l10n.postFilterDateLastWeek),
                    ChoiceFilterTagValue(value: 'month', name: l10n.postFilterDateLastMonth),
                    ChoiceFilterTagValue(value: 'year', name: l10n.postFilterDateLastYear),
                  ],
                ),
                ChoiceFilterTag(
                  tag: 'status',
                  name: l10n.postFilterStatus,
                  icon: const Icon(Icons.help),
                  options: [
                    ChoiceFilterTagValue(value: null, name: l10n.commonSortDefault),
                    ChoiceFilterTagValue(value: 'active', name: l10n.postFilterStatusActive),
                    ChoiceFilterTagValue(value: 'pending', name: l10n.postFilterStatusPending),
                    ChoiceFilterTagValue(value: 'deleted', name: l10n.postFilterStatusDeleted),
                    ChoiceFilterTagValue(value: 'flagged', name: l10n.postFilterStatusFlagged),
                    ChoiceFilterTagValue(value: 'any', name: l10n.postFilterStatusAny),
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
