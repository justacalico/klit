import 'package:flutter/cupertino.dart';

import '../../presentation/desktop/pages/desktop_favorites_page.dart';
import '../../presentation/pages/post/post_detail_page.dart';

/// Unified favorites page - uses desktop layout for both.
class UiFavoritesPage extends StatelessWidget {
  final void Function(PostDetailArguments) onPostTap;

  const UiFavoritesPage({super.key, required this.onPostTap});

  @override
  Widget build(BuildContext context) {
    return DesktopFavoritesPage(onPostTap: onPostTap);
  }
}
