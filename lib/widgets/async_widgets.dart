import 'package:flutter/material.dart';

/// A button that shows loading state while an async operation is in progress
class AsyncButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final Widget child;
  final Widget? loadingChild;
  final ButtonStyle? style;
  final bool enabled;

  const AsyncButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loadingChild,
    this.style,
    this.enabled = true,
  });

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading || !widget.enabled) return;

    setState(() => _isLoading = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: (widget.enabled && !_isLoading) ? _handlePress : null,
      style: widget.style,
      child: _isLoading
          ? widget.loadingChild ??
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
          : widget.child,
    );
  }
}

/// A filled async button variant
class AsyncFilledButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final Widget child;
  final Widget? loadingChild;
  final ButtonStyle? style;
  final bool enabled;

  const AsyncFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loadingChild,
    this.style,
    this.enabled = true,
  });

  @override
  State<AsyncFilledButton> createState() => _AsyncFilledButtonState();
}

class _AsyncFilledButtonState extends State<AsyncFilledButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading || !widget.enabled) return;

    setState(() => _isLoading = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: (widget.enabled && !_isLoading) ? _handlePress : null,
      style: widget.style,
      child: _isLoading
          ? widget.loadingChild ??
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
          : widget.child,
    );
  }
}

/// A widget that shows loading, error, or content states
class AsyncContent extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final Widget child;
  final VoidCallback? onRetry;
  final Widget? loadingWidget;

  const AsyncContent({
    super.key,
    required this.isLoading,
    required this.child,
    this.error,
    this.onRetry,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ??
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...'),
              ],
            ),
          );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return child;
  }
}

/// Overlay loading indicator for full-screen loading
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(message!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
