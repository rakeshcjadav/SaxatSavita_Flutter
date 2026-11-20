import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/saved_suvichar.dart';
import 'package:saxatsavita_flutter/pages/quotes_image_generator_page.dart';
import 'package:saxatsavita_flutter/services/saved_suvichar_service.dart';

class SavedSuvicharsPage extends StatefulWidget {
  const SavedSuvicharsPage({super.key});

  @override
  State<SavedSuvicharsPage> createState() => _SavedSuvicharsPageState();
}

class _SavedSuvicharsPageState extends State<SavedSuvicharsPage> {
  final SavedSuvicharService _service = SavedSuvicharService();
  List<SavedSuvichar> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final items = await _service.load();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.error_loading_suvichars(e.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _open(SavedSuvichar item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuotesImageGeneratorPage(quote: null, saved: item),
      ),
    );
    if (mounted) await _load();
  }

  Future<bool> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.delete_suvichar),
            content: Text(l10n.suvichar_delete_confirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.delete_suvichar),
              ),
            ],
          ),
    );
    return confirmed ?? false;
  }

  Future<void> _persistDelete(SavedSuvichar item) async {
    await _service.delete(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.suvichar_deleted)),
    );
  }

  void _removeFromList(SavedSuvichar item) {
    setState(() {
      _items = _items.where((saved) => saved.id != item.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: buildAppBar(context, title: l10n.my_suvichars),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _load,
                child:
                    _items.isEmpty
                        ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Icon(
                              Icons.bookmarks_outlined,
                              size: 56,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.no_saved_suvichars,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Text(
                                l10n.no_saved_suvichars_hint,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/quotes_generator',
                                  );
                                },
                                icon: const Icon(Icons.format_quote),
                                label: Text(l10n.quotes_image_generator),
                              ),
                            ),
                          ],
                        )
                        : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _items.length,
                          separatorBuilder:
                              (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Dismissible(
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => _confirmDelete(),
                              onDismissed: (_) {
                                _removeFromList(item);
                                _persistDelete(item);
                              },
                              background: Container(
                                color: Theme.of(context).colorScheme.error,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: Icon(
                                  Icons.delete,
                                  color: Theme.of(context).colorScheme.onError,
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  item.quote,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${suvicharTemplateName(l10n, item.templateIndex)} · ${_formatUpdated(item.updatedAt)}',
                                ),
                                onTap: () => _open(item),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: l10n.delete_suvichar,
                                  onPressed: () async {
                                    if (await _confirmDelete()) {
                                      _removeFromList(item);
                                      await _persistDelete(item);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
              ),
    );
  }
}

String suvicharTemplateName(AppLocalizations l10n, int index) {
  return switch (index) {
    0 => l10n.template_simple,
    3 => l10n.template_spiritual,
    4 => l10n.template_mandala,
    5 => l10n.template_elegant,
    6 => l10n.template_modern,
    7 => l10n.template_classic,
    8 => l10n.template_profile,
    9 => l10n.template_card,
    10 => l10n.template_social,
    11 => l10n.template_story,
    _ => l10n.template,
  };
}

String _formatUpdated(DateTime dateTime) {
  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
