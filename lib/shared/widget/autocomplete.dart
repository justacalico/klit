// SPDX-License-Identifier: AGPL-3.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:kilt/l10n/gen/app_localizations.dart';
import 'package:kilt/shared/shared.dart';

// TODO: This was built with narrow assumptions that we now pay for.
// The autocomplete should be more configurable, with better defaults.
// Cutout should be applied externally, etc.
class AutocompleteTextField<T> extends StatelessWidget {
  const AutocompleteTextField({
    super.key,
    required this.onSelected,
    required this.suggestionsCallback,
    required this.itemBuilder,
    this.submit,
    this.controller,
    this.direction,
    this.readOnly = false,
    this.autofocus = true,
    this.private = false,
    this.labelText,
    this.decoration,
    this.textInputAction,
    this.focusNode,
    this.inputFormatters,
    this.maxLines = 1,
    this.cutoutForFab = true,
  });

  final SubmitString? submit;
  final TextEditingController? controller;
  final VerticalDirection? direction;
  final bool readOnly;
  final String? labelText;
  final InputDecoration? decoration;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final ValueSetter<T> onSelected;
  final Widget Function(BuildContext context, T value) itemBuilder;
  final FutureOr<List<T>?> Function(String search) suggestionsCallback;
  final bool autofocus;
  final bool private;
  final bool cutoutForFab;

  @override
  Widget build(BuildContext context) {
    final hasFab = Scaffold.maybeOf(context)?.hasFloatingActionButton ?? false;
    return TypeAheadField<T>(
      controller: controller,
      focusNode: focusNode,
      direction: direction,
      hideOnEmpty: true,
      hideOnSelect: false,
      builder: (context, controller, focusNode) => TextField(
        controller: controller,
        autofocus: autofocus,
        focusNode: focusNode,
        inputFormatters: inputFormatters,
        decoration:
            decoration?.copyWith(labelText: labelText) ??
            InputDecoration(labelText: labelText),
        onSubmitted: submit,
        textInputAction: textInputAction ?? TextInputAction.search,
        readOnly: readOnly,
        enableIMEPersonalizedLearning: !private,
        maxLines: maxLines,
      ),
      decorationBuilder: (context, child) {
        final Widget result = Card(
          margin: EdgeInsets.zero,
          color: Theme.of(context).colorScheme.surface,
          child: child,
        );

        if (cutoutForFab && hasFab) {
          return ClipPath.shape(
            shape: const AutocompleteCutout(),
            child: result,
          );
        }
        return result;
      },
      loadingBuilder: (context) => const ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [SizedCircularProgressIndicator(size: 24)],
        ),
      ),
      errorBuilder: (context, error) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconMessage(
            icon: const Icon(Icons.error),
            title: Text(AppLocalizations.of(context).commonFailedLoadSuggestions),
          ),
        ],
      ),
      onSelected: onSelected,
      itemBuilder: itemBuilder,
      suggestionsCallback: suggestionsCallback,
    );
  }
}

/// A [ShapeBorder] that cuts out a half circle at the top right corner.
///
/// This is used to make space for a [FloatingActionButton].
/// This is a crude implementation and does not respect different [FloatingActionButton] positions or sizes.
class AutocompleteCutout extends ShapeBorder {
  const AutocompleteCutout();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    const shape = CircularNotchedRectangle();

    final size = rect.size;
    const double edgeDistance = 16;
    const double padding = 2;
    const double offset = 4;
    const double width = 56;
    const radius = width / 2;

    return shape
        .getOuterPath(
          rect,
          Rect.fromCircle(
            center: Offset(size.width - radius - edgeDistance, 0),
            radius: radius + padding,
          ),
        )
        .transform(
          (Matrix4.diagonal3Values(
            1,
            -1,
            1,
          )..translateByDouble(0, -size.height - offset, 0, 0)).storage,
        );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
