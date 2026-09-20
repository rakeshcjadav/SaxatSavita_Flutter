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

    return Material(
      color:
          isCurrentUser
              ? colors.primaryContainer.withValues(alpha: 0.65)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 8 : 10,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                rankLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: leaderboardRankColor(rank, colors),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: compact ? 14 : 16,
              backgroundColor:
                  isCurrentUser
                      ? colors.primary
                      : colors.surfaceContainerHighest,
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  color: isCurrentUser ? colors.onPrimary : colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              points,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.daily_quiz_leaderboard,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (signedIn && data.entries.isNotEmpty)
                    Text(
                      localizeLeaderboardDigits(
                        context,
                        l10n.daily_quiz_leaderboard_participants(
                          data.entries.length,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (!signedIn)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.daily_quiz_leaderboard_sign_in,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else if (data.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.daily_quiz_leaderboard_empty,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else ...[
                ...data.top5.asMap().entries.map((item) {
                  final rank = item.key + 1;
                  final entry = item.value;
                  return DailyQuizLeaderboardTile(
                    rank: rank,
                    entry: entry,
                    isCurrentUser: entry.uid == data.currentUser?.uid,
                    compact: true,
                  );
                }),
                if (data.currentUser != null &&
                    !data.currentUserInTop5 &&
                    data.currentUserRank != null) ...[
                  const Divider(height: 16),
                  DailyQuizLeaderboardTile(
                    rank: data.currentUserRank!,
                    entry: data.currentUser!,
                    isCurrentUser: true,
                    compact: true,
                  ),
                ],
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: signedIn ? onSeeAll : onSignIn,
                  child: Text(
                    signedIn ? l10n.daily_quiz_leaderboard_see_all : l10n.login,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
