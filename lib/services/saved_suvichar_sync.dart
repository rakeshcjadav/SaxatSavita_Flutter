import 'package:saxatsavita_flutter/models/saved_suvichar.dart';

class SuvicharSyncPlan {
  final List<SavedSuvichar> merged;
  final List<SavedSuvichar> toUpload;
  final List<String> tombstonesToRetry;

  const SuvicharSyncPlan({
    required this.merged,
    required this.toUpload,
    required this.tombstonesToRetry,
  });
}

/// Last-write-wins merge. Tombstoned ids are dropped and are not revived
/// from either side. [toUpload] is the local rows that are missing remotely
/// or newer than the remote copy.
SuvicharSyncPlan planSuvicharSync({
  required List<SavedSuvichar> local,
  required List<SavedSuvichar> remote,
  required Set<String> tombstones,
}) {
  final remoteById = <String, SavedSuvichar>{
    for (final item in remote)
      if (!tombstones.contains(item.id)) item.id: item,
  };
  final mergedById = Map<String, SavedSuvichar>.from(remoteById);
  final toUpload = <SavedSuvichar>[];

  for (final item in local) {
    if (tombstones.contains(item.id)) continue;
    final remoteItem = remoteById[item.id];
    if (remoteItem == null || item.updatedAt.isAfter(remoteItem.updatedAt)) {
      mergedById[item.id] = item;
      toUpload.add(item);
    }
  }

  final merged =
      mergedById.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final remoteIds = remote.map((item) => item.id).toSet();
  final tombstonesToRetry =
      tombstones.where(remoteIds.contains).toList()..sort();

  return SuvicharSyncPlan(
    merged: merged,
    toUpload: toUpload,
    tombstonesToRetry: tombstonesToRetry,
  );
}
