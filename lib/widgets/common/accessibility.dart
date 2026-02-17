import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccessibilityHelper {
  static void announceForAccessibility(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  static Widget makeAccessible({
    required Widget child,
    required String semanticLabel,
    String? semanticHint,
    bool? isButton,
    bool? isTextField,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: isButton ?? false,
      textField: isTextField ?? false,
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }

  static Widget accessibleButton({
    required Widget child,
    required String label,
    String? hint,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      onTap: onPressed,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }

  static Widget accessibleImage({
    required Widget child,
    required String semanticLabel,
    String? semanticHint,
    VoidCallback? onTap,
  }) {
    return Semantics(
      image: true,
      label: semanticLabel,
      hint: semanticHint,
      onTap: onTap,
      child: ExcludeSemantics(
        child: child,
      ),
    );
  }

  static void handleAccessibilityAction(BuildContext context, String action) {
    announceForAccessibility(context, action);
    HapticFeedback.lightImpact();
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, FlutterErrorDetails)? errorBuilder;
  final void Function(FlutterErrorDetails)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        _error = details;
      });
      widget.onError?.call(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ??
          _DefaultErrorWidget(error: _error!);
    }
    return widget.child;
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final FlutterErrorDetails error;

  const _DefaultErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We encountered an unexpected error. Please try again.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Copy error details
                        Clipboard.setData(ClipboardData(text: error.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error details copied')),
                        );
                      },
                      child: const Text('Copy Details'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          // Reset error state
                        });
                      },
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SafeAsyncBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final T? initialData;

  const SafeAsyncBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      initialData: initialData,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ??
              _DefaultErrorWidget(
                error: FlutterErrorDetails(
                  exception: snapshot.error!,
                  stack: snapshot.stackTrace,
                ),
              );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder?.call(context) ??
              const Center(
                child: CircularProgressIndicator(),
              );
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data!);
        }

        return loadingBuilder?.call(context) ??
            const Center(
              child: CircularProgressIndicator(),
            );
      },
    );
  }
}

class ErrorHandler {
  static void logError(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('Error: $message');
    if (error != null) {
      debugPrint('Exception: $error');
    }
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  static void handleError(
    BuildContext context,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    VoidCallback? onRetry,
  }) {
    logError(message, error: error, stackTrace: stackTrace);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  static Future<bool> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    String? details,
    VoidCallback? onRetry,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (details != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  details,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          ),
          if (onRetry != null)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
    return result ?? false;
  }
}

class AccessibilitySettings {
  static const double defaultFontScale = 1.0;
  static const double maxFontScale = 2.0;
  static const double minFontScale = 0.8;

  static bool isHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  static double getFontScale(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor.clamp(minFontScale, maxFontScale);
  }

  static bool reduceMotion(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  static TextStyle getAccessibleTextStyle(
    BuildContext context,
    TextStyle textStyle,
  ) {
    final fontScale = getFontScale(context);
    return textStyle.copyWith(
      fontSize: (textStyle.fontSize ?? 14) * fontScale,
    );
  }
}

class FocusManager {
  static final Map<String, FocusNode> _focusNodes = {};

  static FocusNode getFocusNode(String key) {
    return _focusNodes.putIfAbsent(key, () => FocusNode());
  }

  static void disposeFocusNode(String key) {
    _focusNodes[key]?.dispose();
    _focusNodes.remove(key);
  }

  static void disposeAll() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
  }

  static void requestFocus(String key) {
    _focusNodes[key]?.requestFocus();
  }

  static void unfocus(String key) {
    _focusNodes[key]?.unfocus();
  }
}
