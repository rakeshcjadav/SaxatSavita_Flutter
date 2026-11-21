import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/inbox_notification.dart';
import 'package:saxatsavita_flutter/services/notification_inbox_service.dart';
import 'package:saxatsavita_flutter/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    unawaited(NotificationService().syncInboxFromActive());
  }

  Future<void> _clear(InboxNotification item) async {
    await NotificationInboxService().remove(item.id);
    await NotificationService().dismissDisplayed(
      id: item.systemId,
      tag: item.tag,
    );
  }

  String _when(BuildContext context, DateTime time) {
    final local = time.toLocal();
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) return DateFormat.jm(locale).format(local);
    return DateFormat.MMMd(locale).add_jm().format(local);
  }

  bool _opensOnTap(String? payload) {
    return NotificationService().inboxNotificationOpens(payload);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: buildAppBar(context, title: l10n.notifications),
      body: ValueListenableBuilder<int>(
        valueListenable: NotificationInboxService().revision,
        builder: (context, _, _) {
          final items = NotificationInboxService().items;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.notifications_empty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final item = items[index];
              final opens = _opensOnTap(item.payload);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  onTap:
                      opens
                          ? () =>
                              NotificationService().openFromInbox(item.payload)
                          : null,
                  title: Text(
                    item.title.isEmpty ? item.body : item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.title.isNotEmpty && item.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.body),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        _when(context, item.receivedAt),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    tooltip: l10n.clear,
                    icon: const Icon(Icons.close),
                    onPressed: () => _clear(item),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
