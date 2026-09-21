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

    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      child: Row(
        children: [
          _RankTrophy(rank: rank, compact: compact),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: compact ? 16 : 16,
            backgroundColor:
                isCurrentUser ? colors.primary : colors.surfaceContainerHighest,
            child: Text(
              localizeLeaderboardDigits(context, '$rank'),
              style: TextStyle(
                fontSize: rank >= 100 ? 10 : (rank >= 10 ? 12 : 13),
                fontWeight: FontWeight.w800,
                color:
                    isCurrentUser
                        ? colors.onPrimary
                        : (leaderboardRankColor(rank, colors) ??
                            colors.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                color: isCurrentUser ? colors.primary : colors.onSurface,
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            isCurrentUser
                ? colors.primary.withValues(alpha: 0.08)
                : colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isCurrentUser
                  ? colors.primary.withValues(alpha: 0.22)
                  : colors.outline.withValues(alpha: 0.12),
        ),
      ),
      child: row,
    );
  }
}

class _RankTrophy extends StatelessWidget {
  const _RankTrophy({required this.rank, required this.compact});

  final int rank;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final trophyColor = leaderboardRankColor(rank, colors);
    final size = compact ? 24.0 : 28.0;

    return SizedBox(
      width: compact ? 28 : 32,
      child:
          rank <= 3
              ? Icon(Icons.emoji_events, size: size, color: trophyColor)
              : null,
    );
  }
}

class DailyQuizLeaderboardPreviewCard extends StatelessWidget {
  const DailyQuizLeaderboardPreviewCard({
    super.key,
    required this.snapshot,
    required this.onSeeAll,
    required this.onSignIn,
    this.embedded = false,
  });

  final DailyQuizLeaderboardSnapshot snapshot;
  final VoidCallback onSeeAll;
  final VoidCallback onSignIn;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final data = snapshot;
    final signedIn = data.isAuthenticated;
    final hasEntries = signedIn && data.entries.isNotEmpty;

    final participantLabel =
        hasEntries
            ? localizeLeaderboardDigits(
              context,
              l10n.daily_quiz_leaderboard_participants(data.entries.length),
            )
            : null;

    final header = Row(
      children: [
        if (!embedded)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: colors.primary,
              child: Icon(
                Icons.emoji_events,
                size: 28,
                color: colors.onPrimary,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(Icons.emoji_events, size: 22, color: colors.primary),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.daily_quiz_leaderboard,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                  fontSize: embedded ? 16 : null,
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
        if (embedded && hasEntries)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(l10n.daily_quiz_leaderboard_see_all),
          ),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 12),
        if (!signedIn) ...[
          Text(
            l10n.daily_quiz_leaderboard_sign_in,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: onSignIn, child: Text(l10n.login)),
          ),
        ] else if (data.isEmpty)
          Text(
            l10n.daily_quiz_leaderboard_empty,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          )
        else ...[
          ...data.top5.asMap().entries.map((item) {
            final rank = item.key + 1;
            final entry = item.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DailyQuizLeaderboardTile(
                rank: rank,
                entry: entry,
                isCurrentUser: entry.uid == data.currentUser?.uid,
                compact: true,
              ),
            );
          }),
          if (data.currentUser != null &&
              !data.currentUserInTop5 &&
              data.currentUserRank != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Divider(
                height: 1,
                color: colors.outline.withValues(alpha: 0.22),
              ),
            ),
            DailyQuizLeaderboardTile(
              rank: data.currentUserRank!,
              entry: data.currentUser!,
              isCurrentUser: true,
              compact: true,
            ),
          ],
          if (!embedded) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSeeAll,
                child: Text(l10n.daily_quiz_leaderboard_see_all),
              ),
            ),
          ],
        ],
      ],
    );

    if (embedded) return body;
    return DashboardOutlinedCard(child: body);
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
