import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'stream_provider.dart';
import 'stream_chat_provider.dart';
import 'stream_combined_provider.dart';

/// Utility class for setting up streaming providers
/// This makes it easy to add streaming functionality to any part of the app
class StreamProviderSetup {
  /// Add all streaming providers to the widget tree
  /// Use this in your main app or specific screens
  static Widget withStreamingProviders({
    required Widget child,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StreamProvider>(
          create: (context) => StreamProvider(),
        ),
        ChangeNotifierProvider<StreamChatProvider>(
          create: (context) => StreamChatProvider(),
        ),
        ChangeNotifierProvider<StreamCombinedProvider>(
          create: (context) => StreamCombinedProvider(
            streamProvider: context.read<StreamProvider>(),
            chatProvider: context.read<StreamChatProvider>(),
          ),
        ),
      ],
      child: child,
    );
  }

  /// Get the combined stream provider from context
  static StreamCombinedProvider streamCombined(BuildContext context) {
    return context.read<StreamCombinedProvider>();
  }

  /// Get the individual stream provider from context
  static StreamProvider streamProvider(BuildContext context) {
    return context.read<StreamProvider>();
  }

  /// Get the chat provider from context
  static StreamChatProvider chatProvider(BuildContext context) {
    return context.read<StreamChatProvider>();
  }

  /// Watch the combined stream provider for changes
  static StreamCombinedProvider watchStreamCombined(BuildContext context) {
    return context.watch<StreamCombinedProvider>();
  }

  /// Watch the individual stream provider for changes
  static StreamProvider watchStreamProvider(BuildContext context) {
    return context.watch<StreamProvider>();
  }

  /// Watch the chat provider for changes
  static StreamChatProvider watchChatProvider(BuildContext context) {
    return context.watch<StreamChatProvider>();
  }

  /// A convenience widget that provides streaming functionality
  /// to its descendants with proper error handling
  static class StreamProviderWrapper extends StatelessWidget {
    final Widget child;
    final Function(Object)? onError;

    const StreamProviderWrapper({
      super.key,
      required this.child,
      this.onError,
    });

    @override
    Widget build(BuildContext context) {
      return withStreamingProviders(
        child: Consumer<StreamCombinedProvider>(
          builder: (context, provider, _) {
            // Handle errors
            if (provider.error != null && onError != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onError!(provider.error!);
              });
            }

            return child;
          },
        ),
      );
    }
  }

  /// A builder widget that provides streaming state to its callback
  static class StreamBuilder extends StatelessWidget {
    final Widget Function(
      BuildContext context,
      StreamCombinedProvider provider,
    ) builder;
    final Widget? loadingChild;
    final Widget Function(Object error)? errorBuilder;

    const StreamBuilder({
      super.key,
      required this.builder,
      this.loadingChild,
      this.errorBuilder,
    });

    @override
    Widget build(BuildContext context) {
      return Consumer<StreamCombinedProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && loadingChild != null) {
            return loadingChild!;
          }

          if (provider.error != null && errorBuilder != null) {
            return errorBuilder!(provider.error!);
          }

          return builder(context, provider);
        },
      );
    }
  }

  /// A selector widget that rebuilds only when the selected value changes
  static class StreamSelector<T> extends StatelessWidget {
    final T Function(StreamCombinedProvider provider) selector;
    final Widget Function(BuildContext context, T value) builder;

    const StreamSelector({
      super.key,
      required this.selector,
      required this.builder,
    });

    @override
    Widget build(BuildContext context) {
      return Consumer<StreamCombinedProvider>(
        builder: (context, provider, _) {
          final value = selector(provider);
          return builder(context, value);
        },
      );
    }
  }
}

/// Extension methods for easy access to streaming providers
extension StreamProviderContext on BuildContext {
  /// Get the combined stream provider
  StreamCombinedProvider get streamCombined => StreamProviderSetup.streamCombined(this);

  /// Get the individual stream provider
  StreamProvider get streamProvider => StreamProviderSetup.streamProvider(this);

  /// Get the chat provider
  StreamChatProvider get chatProvider => StreamProviderSetup.chatProvider(this);

  /// Watch the combined stream provider
  StreamCombinedProvider get watchStreamCombined => StreamProviderSetup.watchStreamCombined(this);

  /// Watch the individual stream provider
  StreamProvider get watchStreamProvider => StreamProviderSetup.watchStreamProvider(this);

  /// Watch the chat provider
  StreamChatProvider get watchChatProvider => StreamProviderSetup.watchChatProvider(this);
}

/// Pre-built widgets for common streaming UI patterns
class StreamUIWidgets {
  /// A loading indicator for streaming content
  static Widget streamingLoader({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }

  /// An error widget for streaming errors
  static Widget streamingError({
    required Object error,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(Get.context!).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(Get.context!).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
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

  /// An empty state widget for streaming content
  static Widget streamingEmpty({
    required String title,
    required String subtitle,
    IconData? icon,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.live_tv_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(Get.context!).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(Get.context!).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Helper class to get context in static methods
class Get {
  static BuildContext? _context;
  
  static void setContext(BuildContext context) {
    _context = context;
  }
  
  static BuildContext? get context => _context;
}
