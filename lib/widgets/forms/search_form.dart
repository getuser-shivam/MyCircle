import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/media_provider.dart';

class SearchForm extends StatefulWidget {
  final Function(String)? onSearch;
  final String? initialValue;
  final bool autofocus;
  final InputDecoration? decoration;

  const SearchForm({
    super.key,
    this.onSearch,
    this.initialValue,
    this.autofocus = false,
    this.decoration,
  });

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    mediaProvider.setSearchQuery(query);
    widget.onSearch?.call(query);
  }

  void _onSubmitted(String query) {
    _onSearchChanged(query);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        return TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          onChanged: _onSearchChanged,
          onSubmitted: _onSubmitted,
          decoration: widget.decoration ?? InputDecoration(
            hintText: 'Search media...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: mediaProvider.searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
        );
      },
    );
  }
}
