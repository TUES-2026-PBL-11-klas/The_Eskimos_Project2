import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/geocode_result.dart';
import '../../data/repositories/geocoding_repository.dart';

class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.repo,
    required this.onPicked,
    this.initialText,
    this.label = 'To:',
    this.decoration,
  });

  final GeocodingRepository repo;
  final ValueChanged<GeocodeResult> onPicked;
  final String? initialText;
  final String label;
  final InputDecoration? decoration;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<GeocodeResult> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    if (q.trim().length < 2) {
      if (mounted) {
        setState(() {
          _results = const [];
          _error = null;
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.repo.search(q);
      if (mounted) setState(() => _results = r);
    } catch (e, st) {
      debugPrint('SearchField geocode failed for "$q": $e\n$st');
      if (mounted) {
        setState(() {
          _results = const [];
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchPressed() {
    _debounce?.cancel();
    FocusScope.of(context).unfocus();
    _runSearch(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          decoration: (widget.decoration ??
                  InputDecoration(
                    labelText: widget.label,
                    border: const OutlineInputBorder(),
                  ))
              .copyWith(
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Search',
                    onPressed: _onSearchPressed,
                  ),
          ),
          onChanged: _onChanged,
        ),
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Search failed: $_error',
              style: TextStyle(color: Colors.red.shade900, fontSize: 12),
            ),
          ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = _results[i];
                return ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(r.label),
                  onTap: () {
                    _controller.text = r.label;
                    setState(() => _results = const []);
                    widget.onPicked(r);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
