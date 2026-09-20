import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/daily_quiz_leaderboard_model.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

String localizeLeaderboardDigits(BuildContext context, String input) {
  if (Localizations.localeOf(context).languageCode != 'gu') return input;
  return Utils.toGujaratiNumerals(input);
}

String leaderboardDisplayName(
  BuildContext context,
  DailyQuizLeaderboardEntry entry, {
  required bool isCurrentUser,
}) {
  final l10n = AppLocalizations.of(context)!;
  if (isCurrentUser) return l10n.daily_quiz_leaderboard_you;
  if (entry.displayName.isEmpty) return l10n.daily_quiz_leaderboard_anonymous;
  return entry.displayName;
}

Color? leaderboardRankColor(int rank, ColorScheme colors) {
  return switch (rank) {
    1 => const Color(0xFFC9A227),
    2 => const Color(0xFF8A8D91),
    3 => const Color(0xFFB87333),
    _ => colors.onSurfaceVariant,
  };
}

class DailyQuizLeaderboardTile extends StatelessWidget {
  const DailyQuizLeaderboardTile({
    super.key,
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
    this.compact = false,
  });

  final int rank;
  final DailyQuizLeaderboardEntry entry;
  final bool isCurrentUser;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final name = leaderboardDisplayName(
      context,
      entry,
      isCurrentUser: isCurrentUser,
    );
    final points = localizeLeaderboardDigits(
      context,
      l10n.quiz_points_count(entry.pointsAwarded),
    );
    final rankLabel = localizeLeaderboardDigits(context, '$rank');

    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 12,
        vertical: compact ? 8 : 10,
      ),
      child: Row(
        children: [
          SizedBox(
            width: compact ? 28 : 32,
            child: Text(
              rankLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: leaderboardRankColor(rank, colors),
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  isCurrentUser
                      ? colors.primary
                      : colors.surfaceContainerHighest,
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isCurrentUser ? colors.onPrimary : colors.primary,
                ),
              ),
            ),
          ],
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            points,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (!compact || !isCurrentUser) return row;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: row,
    );
  }
}

class DailyQuizLeaderboardPreviewCard extends StatelessWidget {
  const DailyQuizLeaderboardPreviewCard({
    super.key,
    required this.snapshot,
    required this.onSeeAll,
    required this.onSignIn,
  });

  final DailyQuizLeaderboardSnapshot snapshot;
  final VoidCallback onSeeAll;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final data = snapshot;
    final signedIn = data.isAuthenticated;

    final participantLabel =
        signedIn && data.entries.isNotEmpty
            ? localizeLeaderboardDigits(
              context,
              l10n.daily_quiz_leaderboard_participants(data.entries.length),
            )
            : null;

    return DashboardOutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.surfaceContainerHighest,
                child: Icon(Icons.emoji_events_outlined, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.daily_quiz_leaderboard,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                    if (participantLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        participantLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!signedIn)
            Text(
              l10n.daily_quiz_leaderboard_sign_in,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            )
          else if (data.isEmpty)
            Text(
              l10n.daily_quiz_leaderboard_empty,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            )
          else ...[
            ...data.top5.asMap().entries.expand((item) {
              final rank = item.key + 1;
              final entry = item.value;
              final isLast = rank == data.top5.length;
              return [
                DailyQuizLeaderboardTile(
                  rank: rank,
                  entry: entry,
                  isCurrentUser: entry.uid == data.currentUser?.uid,
                  compact: true,
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: colors.outline.withValues(alpha: 0.18),
                  ),
              ];
            }),
            if (data.currentUser != null &&
                !data.currentUserInTop5 &&
                data.currentUserRank != null) ...[
              Divider(
                height: 16,
                color: colors.outline.withValues(alpha: 0.28),
              ),
              DailyQuizLeaderboardTile(
                rank: data.currentUserRank!,
                entry: data.currentUser!,
                isCurrentUser: true,
                compact: true,
              ),
            ],
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: signedIn ? onSeeAll : onSignIn,
              child: Text(
                signedIn ? l10n.daily_quiz_leaderboard_see_all : l10n.login,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared dashboard card chrome: light surface, visible outline, elevation 4.
class DashboardOutlinedCard extends StatelessWidget {
  const DashboardOutlinedCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20.0),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(onTap: onTap, child: content);
    }
    return Card(
      elevation: 4,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.32)),
      ),
      child: content,
    );
  }
}
