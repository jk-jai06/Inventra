import 'package:flutter/material.dart';

/// Centered loading indicator with optional label.
class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Fullscreen loading overlay (use with Stack).
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: AppLoadingWidget(label: message),
    );
  }
}
