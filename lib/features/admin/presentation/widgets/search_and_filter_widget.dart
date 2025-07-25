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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
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
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 16),
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
    final isSelected = selectedRoleFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onRoleFilterChanged(value),
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
