// SPDX-License-Identifier: AGPL-3.0

import 'package:kilt/client/client.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';
import 'package:kilt/tag/tag.dart';
import 'package:kilt/traits/traits.dart';
import 'package:flutter/material.dart';

class DenyListPage extends StatelessWidget {
  const DenyListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget buildEditTextField(
      BuildContext context, {
      required String title,
      required SubmitString submit,
      String? value,
    }) => Material(
      child: ControlledTextWrapper(
        textController: TextEditingController(text: value),
        submit: submit,
        builder: (context, controller, submit) => TagInput(
          controller: controller,
          decoration: const InputDecoration(suffix: PromptTextFieldSuffix()),
          textInputAction: TextInputAction.done,
          direction: VerticalDirection.up,
          labelText: title,
          submit: submit,
          readOnly: PromptActions.of(context).isLoading,
        ),
      ),
    );

    return PromptActions(
      child: LimitedWidthLayout(
        child: Consumer<Client>(
          builder: (context, client, child) => ValueListenableBuilder(
            valueListenable: client.traits,
            builder: (context, traits, child) {
              List<String> denylist = traits.denylist.toList();
              return AdaptiveScaffold(
                appBar: DefaultAppBar(
                  title: Text(l10n.traitsBlacklist),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DenyListEditor(),
                        ),
                      ),
                    ),
                  ],
                ),
                floatingActionButton: PromptFloatingActionButton(
                  builder: (context) => buildEditTextField(
                    context,
                    title: l10n.traitsAddTag,
                    submit: (value) async {
                      value = value.trim();
                      if (value.isEmpty) return;
                      try {
                        await client.accounts.push(
                          traits: traits.copyWith(
                            denylist: denylist..add(value),
                          ),
                        );
                      } on ClientException {
                        throw ActionControllerException(
                          message: l10n.traitsFailedUpdate,
                        );
                      }
                    },
                  ),
                  icon: const Icon(Icons.add),
                ),
                body: PullToRefresh(
                  onRefresh: () async {
                    await client.accounts.pull(force: true);
                  },
                  child: denylist.isEmpty
                      ? Center(
                          child: IconMessage(
                            icon: const Icon(Icons.check),
                            title: Text(l10n.traitsBlacklistEmpty),
                          ),
                        )
                      : ListView.builder(
                          primary: true,
                          padding: defaultActionListPadding.add(
                            LimitedWidthLayout.of(context).padding,
                          ),
                          itemCount: denylist.length,
                          itemBuilder: (context, index) => DenylistTile(
                            tag: denylist[index],
                            onEdit: () {
                              String tag = denylist[index];
                              PromptActions.of(context).show(
                                context,
                                buildEditTextField(
                                  context,
                                  value: tag,
                                  title: l10n.traitsEditTag,
                                  submit: (value) async {
                                    value = value.trim();
                                    try {
                                      if (value.isEmpty) {
                                        await client.accounts.push(
                                          traits: traits.copyWith(
                                            denylist: List.of(denylist)..remove(tag),
                                          ),
                                        );
                                      } else {
                                        await client.accounts.push(
                                          traits: traits.copyWith(
                                            denylist: List.of(denylist)
                                              ..[denylist.indexOf(tag)] = value,
                                          ),
                                        );
                                      }
                                    } on ClientException {
                                      throw ActionControllerException(
                                        message: l10n.traitsFailedUpdate,
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                            onDelete: () => client.accounts.push(
                              traits: traits.copyWith(
                                denylist: denylist..remove(denylist[index]),
                              ),
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
