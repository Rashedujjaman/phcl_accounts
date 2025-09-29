import 'package:flutter/material.dart';

class SearchAndFilterWidget extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedRoleFilter;
  final Function(String) onSearchChanged;
  final Function(String) onRoleFilterChanged;
  final VoidCallback? onClearSearch;

  const SearchAndFilterWidget({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.selectedRoleFilter,
    required this.onSearchChanged,
    required this.onRoleFilterChanged,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),
          // Role Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, 'all', 'All Users'),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'admin', 'Admins'),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'user', 'Users'),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'viewer', 'Viewers'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    final isSelected = selectedRoleFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onRoleFilterChanged(value),
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: theme.colorScheme.onPrimary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
