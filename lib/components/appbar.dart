import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';

enum ActionOptions {
  info,
  settings,
  notes,
  search,
  favorite,
  aashirvachan,
  preface,
}

PreferredSizeWidget buildAppBar(
  BuildContext context, {
  String title = '',
  IconData? titleIcon,
  List<ActionOptions>? actionItems,
  List<Widget>? extraActions,
  PreferredSizeWidget? bottom,
  VoidCallback? onSettingsPressed,
}) {
  return _AdaptiveAppBar(
    title: title,
    titleIcon: titleIcon,
    actionItems: actionItems,
    extraActions: extraActions,
    bottom: bottom,
    onSettingsPressed: onSettingsPressed,
  );
}

class _AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AdaptiveAppBar({
    required this.title,
    this.titleIcon,
    this.actionItems,
    this.extraActions,
    this.bottom,
    this.onSettingsPressed,
  });

  final String title;
  final IconData? titleIcon;
  final List<ActionOptions>? actionItems;
  final List<Widget>? extraActions;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onSettingsPressed;

  static const _iconW = kMinInteractiveDimension;
  static const _titlePad = 8.0;
  static const _titleIconSize = 22.0;
  static const _titleIconGap = 8.0;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resolvedTitle = title.isEmpty ? l10n.sakshatSavita : title;
    final titleStyle = Theme.of(context).textTheme.titleLarge!.copyWith(
      fontSize: 18,
      color: Theme.of(context).colorScheme.onPrimary,
    );
    final showBack = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    final useIconAsLeading = titleIcon != null && !showBack;
    final showTitleIcon = titleIcon != null && !useIconAsLeading;
    return AppBar(
      centerTitle: false,
      titleSpacing: 0,
      elevation: 5,
      automaticallyImplyLeading: !useIconAsLeading,
      leading:
          useIconAsLeading
              ? IgnorePointer(
                child: IconButton(
                  icon: Icon(titleIcon, color: titleStyle.color),
                  tooltip: resolvedTitle,
                  onPressed: () {},
                ),
              )
              : null,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final entries = _collectActions(context);
          final contentW = (constraints.maxWidth - _titlePad).clamp(
            0.0,
            constraints.maxWidth,
          );
          final titleWanted = _measureTitle(context, resolvedTitle, titleStyle);
          final titleIconW =
              showTitleIcon ? _titleIconSize + _titleIconGap : 0.0;
          var visible = List<_BarAction>.from(entries);
          var overflow = <_BarAction>[];

          double actionsWidth() =>
              (visible.length + (overflow.isEmpty ? 0 : 1)) * _iconW;

          bool titleFits() =>
              titleWanted + titleIconW + 8 + actionsWidth() <= contentW + 0.5;

          void hideLastOverflowable() {
            final index = visible.lastIndexWhere((action) => action.overflowable);
            if (index < 0) return;
            overflow.insert(0, visible.removeAt(index));
          }

          while (!titleFits() && visible.any((action) => action.overflowable)) {
            hideLastOverflowable();
          }

          final titleMax = (contentW - actionsWidth()).clamp(0.0, contentW);
          return Row(
            children: [
              const SizedBox(width: _titlePad),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: titleMax),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showTitleIcon) ...[
                      Icon(
                        titleIcon,
                        size: _titleIconSize,
                        color: titleStyle.color,
                      ),
                      const SizedBox(width: _titleIconGap),
                    ],
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: (titleMax - titleIconW).clamp(0.0, titleMax),
                      ),
                      child: Text(
                        resolvedTitle,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ...visible.map((action) => action.widget),
              if (overflow.isNotEmpty) _overflowButton(context, overflow),
            ],
          );
        },
      ),
      bottom: bottom,
    );
  }

  Widget _overflowButton(BuildContext context, List<_BarAction> overflow) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final itemColor = isDark ? colorScheme.onSurface : colorScheme.onPrimary;
    final menuColor =
        isDark ? colorScheme.surfaceContainerHigh : colorScheme.primary;
    return PopupMenuButton<_BarAction>(
      tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
      icon: const Icon(Icons.more_vert),
      color: menuColor,
      onSelected: (action) => action.onPressed?.call(),
      itemBuilder: (context) {
        final itemStyle = Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: itemColor);
        return [
          for (final action in overflow)
            PopupMenuItem(
              value: action,
              enabled: action.onPressed != null,
              child: Row(
                children: [
                  IconTheme(
                    data: IconThemeData(color: itemColor, size: 20),
                    child: action.icon,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      action.tooltip,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: itemStyle,
                    ),
                  ),
                ],
              ),
            ),
        ];
      },
    );
  }

  List<_BarAction> _collectActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = actionItems ?? const <ActionOptions>[];
    final actions = <_BarAction>[];

    void addRoute({
      required bool enabled,
      required IconData icon,
      required String tooltip,
      required String route,
    }) {
      if (!enabled) return;
      actions.add(
        _BarAction.button(
          icon: Icon(icon),
          tooltip: tooltip,
          onPressed: () => Navigator.pushNamed(context, route),
        ),
      );
    }

    addRoute(
      enabled: items.contains(ActionOptions.aashirvachan),
      icon: Icons.volunteer_activism,
      tooltip: l10n.aashirvachan,
      route: '/aashirvachan',
    );
    addRoute(
      enabled: items.contains(ActionOptions.preface),
      icon: Icons.book,
      tooltip: l10n.preface,
      route: '/preface',
    );
    addRoute(
      enabled: items.contains(ActionOptions.info),
      icon: Icons.info,
      tooltip: l10n.information_section,
      route: '/info',
    );
    addRoute(
      enabled: items.contains(ActionOptions.notes),
      icon: Icons.note,
      tooltip: l10n.notes,
      route: '/notes',
    );
    addRoute(
      enabled: items.contains(ActionOptions.search),
      icon: Icons.search,
      tooltip: l10n.search_all_kiranas,
      route: '/search',
    );

    for (final widget in extraActions ?? const <Widget>[]) {
      actions.add(_BarAction.fromWidget(widget));
    }

    if (items.contains(ActionOptions.settings)) {
      actions.add(
        _BarAction.button(
          icon: const Icon(Icons.settings),
          tooltip: l10n.settings,
          onPressed:
              onSettingsPressed ??
              () => Navigator.pushNamed(context, '/settings'),
        ),
      );
    }

    return actions;
  }

  double _measureTitle(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }
}

class _BarAction {
  const _BarAction({
    required this.widget,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.overflowable,
  });

  factory _BarAction.button({
    required Widget icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return _BarAction(
      widget: IconButton(icon: icon, tooltip: tooltip, onPressed: onPressed),
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      overflowable: true,
    );
  }

  factory _BarAction.fromWidget(Widget widget) {
    if (widget is IconButton) {
      return _BarAction(
        widget: widget,
        icon: widget.icon,
        tooltip: widget.tooltip ?? '',
        onPressed: widget.onPressed,
        overflowable: true,
      );
    }
    return _BarAction(
      widget: widget,
      icon: const Icon(Icons.more_horiz),
      tooltip: '',
      onPressed: null,
      overflowable: false,
    );
  }

  final Widget widget;
  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool overflowable;
}
