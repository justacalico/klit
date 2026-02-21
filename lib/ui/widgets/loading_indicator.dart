import 'package:flutter/cupertino.dart';

/// Cupertino-style loading indicator
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.size = 20, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CupertinoActivityIndicator(radius: size / 2, color: color),
      ),
    );
  }
}

/// Full page loading indicator
class FullPageLoading extends StatelessWidget {
  const FullPageLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 16),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Infinite scroll loading indicator
class InfiniteScrollLoading extends StatelessWidget {
  const InfiniteScrollLoading({super.key, required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const CupertinoActivityIndicator(),
    );
  }
}
