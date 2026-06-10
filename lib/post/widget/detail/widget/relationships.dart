import 'package:kilt/post/post.dart';
import 'package:flutter/material.dart';

class RelationshipDisplay extends StatelessWidget {
  const RelationshipDisplay({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      HiddenWidget(
        show: post.relationships.parentId != null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text('Parent', style: TextStyle(fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.supervisor_account),
              title: Text(post.relationships.parentId.toString()),
              trailing: const Icon(Icons.arrow_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      PostLoadingPage(post.relationships.parentId!),
                ),
              ),
            ),
            const Divider(),
          ],
        ),
      ),
      HiddenWidget(
        show:
            post.relationships.children.isNotEmpty &&
            (post.relationships.hasActiveChildren ?? true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text('Children', style: TextStyle(fontSize: 16)),
            ),
            ...post.relationships.children.map(
              (child) => ListTile(
                leading: const Icon(Icons.supervised_user_circle),
                title: Text(child.toString()),
                trailing: const Icon(Icons.arrow_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PostLoadingPage(child),
                  ),
                ),
              ),
            ),
            const Divider(),
          ],
        ),
      ),
    ],
  );
}
