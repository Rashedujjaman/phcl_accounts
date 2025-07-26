import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phcl_accounts/core/theme/theme_provider.dart';

/// Theme picker dialog for advanced theme selection
class ThemePickerDialog extends StatelessWidget {
  const ThemePickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeOption(
                title: 'System Default',
                subtitle: 'Follow system settings',
                icon: Icons.settings,
                themeMode: ThemeMode.system,
                currentMode: themeProvider.themeMode,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.system);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              _ThemeOption(
                title: 'Light Theme',
                subtitle: 'Bright and clean appearance',
                icon: Icons.light_mode,
                themeMode: ThemeMode.light,
                currentMode: themeProvider.themeMode,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.light);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 8),
              _ThemeOption(
                title: 'Dark Theme',
                subtitle: 'Easy on the eyes',
                icon: Icons.dark_mode,
                themeMode: ThemeMode.dark,
                currentMode: themeProvider.themeMode,
                onTap: () {
                  themeProvider.setThemeMode(ThemeMode.dark);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeMode themeMode;
  final ThemeMode currentMode;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.themeMode,
    required this.currentMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = themeMode == currentMode;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected 
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Show theme picker dialog
void showThemePicker(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const ThemePickerDialog(),
  );
}
