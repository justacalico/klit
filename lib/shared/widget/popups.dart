import 'package:flutter/material.dart';

class PopupMenuTile<T> extends PopupMenuItem<T> {
  PopupMenuTile({
    super.key,
    required T value,
    required this.icon,
    required this.title,
  }) : super(
         child: ListMenuTile(leading: Icon(icon), title: Text(title)),
         value: value,
       );

  final IconData icon;
  final String title;
}

class PopupMenuPickerTile<T> extends PopupMenuItem<T> {
  PopupMenuPickerTile({
    super.key,
    required T value,
    required String title,
    Widget? trailing,
    bool selected = false,
  }) : super(
         value: value,
         child: Row(
           children: [
             Expanded(
               child: Padding(
                 padding: const EdgeInsets.symmetric(vertical: 4),
                 child: Text(title),
               ),
             ),
             if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
             if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, size: 18),
            ],
           ],
         ),
       );
}

class ListMenuTile extends StatelessWidget {
  const ListMenuTile({super.key, this.leading, this.title});

  final Widget? leading;
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ?leading,
        if (title != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: title!,
          ),
      ],
    );
  }
}
