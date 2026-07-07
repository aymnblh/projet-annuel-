import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/search_suggestions_service.dart';
import 'dart:async';

/// Autocomplete search widget with suggestions
class SearchAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final Function(String)? onSuggestionSelected;
  final String hintText;

  const SearchAutocomplete({
    super.key,
    required this.controller,
    required this.onSearch,
    this.onSuggestionSelected,
    this.hintText = 'Rechercher...',
  });

  @override
  State<SearchAutocomplete> createState() => _SearchAutocompleteState();
}

class _SearchAutocompleteState extends State<SearchAutocomplete> {
  final SearchSuggestionsService _suggestionsService = SearchSuggestionsService();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  
  OverlayEntry? _overlayEntry;
  List<SearchSuggestion> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged); // FIX: Remove listener to prevent memory leak
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Debounce search to avoid too many requests
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _getSuggestions(widget.controller.text);
    });
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _getSuggestions(widget.controller.text);
    } else {
      // Delay removal to allow tap on suggestion
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  Future<void> _getSuggestions(String query) async {
    setState(() => _isLoading = true);

    try {
      final suggestions = await _suggestionsService.getSuggestions(query);
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });

        if (suggestions.isNotEmpty && _focusNode.hasFocus) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showOverlay() {
    final theme = Theme.of(context);
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 40, // Account for padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60), // Below search bar
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return _buildSuggestionTile(suggestion);
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSuggestionTile(SearchSuggestion suggestion) {
    IconData icon;
    switch (suggestion.icon) {
      case 'history':
        icon = Icons.history;
        break;
      case 'car':
        icon = Icons.directions_car;
        break;
      default:
        icon = Icons.search;
    }

    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 20,
        color: suggestion.type == SuggestionType.recent
            ? Colors.grey[600]
            : Colors.blue[700],
      ),
      title: Text(
        suggestion.text,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: suggestion.subtitle != null
          ? Text(
              suggestion.subtitle!,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: suggestion.type == SuggestionType.recent
          ? Icon(Icons.north_west, size: 16, color: Colors.grey[400])
          : null,
      onTap: () {
        widget.controller.text = suggestion.text;
        _removeOverlay();
        _focusNode.unfocus();
        
        if (widget.onSuggestionSelected != null) {
          widget.onSuggestionSelected!(suggestion.text);
        }
        widget.onSearch(suggestion.text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search, size: 24),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    widget.controller.clear();
                    _removeOverlay();
                  },
                )
              : (_isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.cardColor, // Adapts to Dark Mode (Dark Grey/Black) vs Light Mode (White)
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onSubmitted: (value) {
          _removeOverlay();
          widget.onSearch(value);
        },
      ),
    );
  }
}
