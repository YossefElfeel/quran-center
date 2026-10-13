import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import 'app_modal_sheet.dart';
import 'app_text_field.dart';

Future<T?> showAppSearchPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T) label,
}) => showAppModalSheet<T>(
  context: context,
  title: title,
  builder: (_) => _SearchPicker<T>(items: items, label: label),
);

class _SearchPicker<T> extends StatefulWidget {
  const _SearchPicker({required this.items, required this.label});
  final List<T> items;
  final String Function(T) label;
  @override
  State<_SearchPicker<T>> createState() => _SearchPickerState<T>();
}

class _SearchPickerState<T> extends State<_SearchPicker<T>> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final List<T> matches = widget.items
        .where(
          (T item) =>
              widget.label(item).toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    final AppL10n l = AppL10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppTextField(
          label: l.commonSearch,
          prefixIcon: Icons.search,
          onChanged: (String v) => setState(() => _query = v),
        ),
        if (matches.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l.commonNoResultsTryAnotherName),
          ),
        SizedBox(
          height: MediaQuery.sizeOf(context).height * .4,
          child: ListView.builder(
            itemCount: matches.length,
            itemBuilder: (BuildContext context, int i) => ListTile(
              title: Text(widget.label(matches[i])),
              onTap: () => Navigator.of(context).pop(matches[i]),
            ),
          ),
        ),
      ],
    );
  }
}

Future<T?> showAppServerSearchPicker<T>({
  required BuildContext context,
  required String title,
  required Future<List<T>> Function(String) search,
  required String Function(T) label,
  String? searchLabel,
}) => showAppModalSheet<T>(
  context: context,
  title: title,
  builder: (_) => _ServerSearchPicker<T>(
    search: search,
    label: label,
    searchLabel: searchLabel ?? AppL10n.of(context).commonSearchByName,
  ),
);

class _ServerSearchPicker<T> extends StatefulWidget {
  const _ServerSearchPicker({
    required this.search,
    required this.label,
    required this.searchLabel,
  });
  final Future<List<T>> Function(String) search;
  final String Function(T) label;
  final String searchLabel;
  @override
  State<_ServerSearchPicker<T>> createState() => _ServerSearchPickerState<T>();
}

class _ServerSearchPickerState<T> extends State<_ServerSearchPicker<T>> {
  Timer? _debounce;
  int _generation = 0;
  bool _loading = true;
  String _query = '';
  String? _error;
  List<T> _items = <T>[];
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final int generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.search(_query);
      if (mounted && generation == _generation) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _error = AppL10n.of(context).commonResultsLoadError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppTextField(
          label: widget.searchLabel,
          prefixIcon: Icons.search,
          onChanged: (v) {
            _query = v;
            _generation++;
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), _load);
          },
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) TextButton(onPressed: _load, child: Text(_error!)),
        if (!_loading && _error == null && _items.isEmpty)
          Text(l.commonNoResultsTryAnotherName),
        if (_items.length >= 50) Text(l.commonRefineSearchHint),
        SizedBox(
          height: MediaQuery.sizeOf(context).height * .4,
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(widget.label(_items[i])),
              onTap: _loading
                  ? null
                  : () => Navigator.of(context).pop(_items[i]),
            ),
          ),
        ),
      ],
    );
  }
}
