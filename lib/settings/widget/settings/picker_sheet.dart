part of '../settings.dart';

Future<void> showPickerSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> values,
  required T current,
  required String Function(T value) labelOf,
  required ValueChanged<T> onSelected,
  Widget Function(T value)? trailingBuilder,
}) async {
  final box = context.findRenderObject()! as RenderBox;
  final overlay =
      Overlay.of(context).context.findRenderObject()! as RenderBox;
  final rect = RelativeRect.fromRect(
    Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero),
          ancestor: overlay),
    ),
    Offset.zero & overlay.size,
  );

  final selected = await showMenu<T>(
    context: context,
    position: rect,
    items: values
        .map((value) => PopupMenuPickerTile<T>(
              value: value,
              title: labelOf(value),
              trailing: trailingBuilder?.call(value),
              selected: current == value,
            ))
        .toList(),
  );

  if (selected != null) {
    HapticFeedback.selectionClick();
    onSelected(selected);
  }
}
