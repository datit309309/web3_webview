import 'package:flutter/material.dart';

class LoadingHelper {
  static OverlayEntry? _overlay;

  static void show(BuildContext context, [String? message]) {
    if (_overlay != null) return;

    // Dismiss keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    _overlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black26,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  static void hide() {
    _overlay?.remove();
    _overlay = null;
  }
}

extension FutureWithLoading<T> on Future<T> {
  Future<T> withLoading(BuildContext context, [String? message]) {
    LoadingHelper.show(context, message);
    return then((value) {
      Future.delayed(const Duration(milliseconds: 1000), LoadingHelper.hide);
      return value;
    }).catchError((error) {
      Future.delayed(const Duration(milliseconds: 1000), LoadingHelper.hide);
      throw error;
    });
  }
}
