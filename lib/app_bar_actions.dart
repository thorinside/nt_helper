import 'package:flutter/material.dart';

class AppBarAction {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onPressed;

  AppBarAction({
    required this.icon,
    this.tooltip,
    required this.onPressed
  });
}

// Helper method to build the AppBar actions
List<Widget> buildAppBarActions(
    List<AppBarAction> allActions, {
      int maxVisibleIcons = 4,
    }) {
  // If we have <= maxVisibleIcons, just return them as IconButtons
  if (allActions.length <= maxVisibleIcons) {
    return allActions
        .map((a) => IconButton(
      icon: Icon(a.icon),
      tooltip: a.tooltip,
      onPressed: a.onPressed,
    ))
        .toList();
  }

  // Otherwise, show the first maxVisibleIcons as IconButtons...
  final visible = allActions.take(maxVisibleIcons).map((a) {
    return IconButton(
      icon: Icon(a.icon),
      tooltip: a.tooltip,
      onPressed: a.onPressed,
    );
  }).toList();

  // ...and put the rest into an overflow popup menu.
  final overflowItems = allActions.skip(maxVisibleIcons).toList();

  visible.add(
    PopupMenuButton<AppBarAction>(
      tooltip: 'More',
      icon: const Icon(Icons.more_vert),
      onSelected: (selectedAction) => selectedAction.onPressed(),
      itemBuilder: (context) {
        return overflowItems.map((action) {
          return PopupMenuItem<AppBarAction>(
            value: action,
            child: Row(
              children: [
                Icon(action.icon, color: Colors.black54),
                const SizedBox(width: 8),
                Text(action.tooltip ?? ''),
              ],
            ),
          );
        }).toList();
      },
    ) as IconButton,
  );

  return visible;
}