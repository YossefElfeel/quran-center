import 'package:flutter/material.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';
import 'app_button.dart';

/// A failed next page keeps the already loaded rows visible and retryable.
class AppPagedList<T> extends StatefulWidget {
  const AppPagedList({
    required this.items,
    required this.loadPage,
    required this.itemBuilder,
    this.padding,
    this.pageSize = 50,
    this.shrinkWrap = false,
    super.key,
  });
  final List<T> items;
  final Future<List<T>> Function(int offset) loadPage;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final int pageSize;
  final bool shrinkWrap;
  @override
  State<AppPagedList<T>> createState() => _AppPagedListState<T>();
}

class _AppPagedListState<T> extends State<AppPagedList<T>> {
  final List<T> _extra = <T>[];
  bool _busy = false;
  bool _exhausted = false;
  String? _error;
  int _generation = 0;
  @override
  void didUpdateWidget(covariant AppPagedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.items, widget.items)) {
      _generation++;
      _extra.clear();
      _busy = false;
      _exhausted = false;
      _error = null;
    }
  }

  Future<void> _more() async {
    if (_busy) return;
    final generation = _generation;
    final offset = widget.items.length + _extra.length;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final next = await widget.loadPage(offset);
      if (mounted && generation == _generation) {
        setState(() {
          _extra.addAll(next);
          _exhausted = next.length < widget.pageSize;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _error = AppL10n.of(context).commonLoadMoreError);
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = <T>[...widget.items, ..._extra];
    final more = widget.items.length >= widget.pageSize && !_exhausted;
    return ListView.builder(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: widget.padding,
      itemCount: all.length + (more ? 1 : 0),
      itemBuilder: (context, i) => i < all.length
          ? widget.itemBuilder(context, all[i], i)
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  AppButton(
                    label: AppL10n.of(context).commonShowMore,
                    isLoading: _busy,
                    onPressed: _more,
                  ),
                ],
              ),
            ),
    );
  }
}
