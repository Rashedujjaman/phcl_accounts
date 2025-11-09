/// Transaction Management Page - Core financial transaction interface
///
/// This file implements the primary transaction management interface for the
/// PHCL Accounts application, providing comprehensive CRUD operations,
/// advanced filtering, and real-time search capabilities.
///
/// **Key Components:**
/// - [TransactionsPage]: Main stateful widget providing transaction management
/// - [_TransactionsPageState]: State management for UI interactions and data
///
/// **Architecture Patterns:**
/// - BLoC Pattern: Uses TransactionBloc for state management
/// - Clean Architecture: Separates domain entities from presentation logic
/// - Material Design 3: Implements latest design system guidelines
///
/// **Dependencies:**
/// - flutter_bloc: State management with BLoC pattern
/// - intl: Date formatting and internationalization
/// - Custom widgets: TransactionItem, DateRangeSelector, etc.
///
/// **File Structure:**
/// ```
/// TransactionsPage (StatefulWidget)
/// └── _TransactionsPageState (State)
///     ├── Lifecycle Methods (initState, dispose, build)
///     ├── Data Methods (load, filter, search, refresh)
///     ├── Event Handlers (date change, type change, search)
///     ├── UI Builders (search bar, list, chips, floating buttons)
///     ├── Navigation Methods (add, edit transaction)
///     └── Action Methods (show details, delete, confirm)
/// ```
///
/// **Usage:**
/// ```dart
/// // Navigate to transactions page
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const TransactionsPage()),
/// );
/// ```
///
/// @author PHCL Development Team
/// @version 1.0.0
/// @since 2024
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:phcl_accounts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';
import 'package:phcl_accounts/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:phcl_accounts/core/widgets/date_range_selector.dart';
import 'package:phcl_accounts/features/transactions/presentation/widgets/transaction_details_sheet.dart';
import 'package:phcl_accounts/features/transactions/presentation/widgets/transaction_item.dart';
import 'package:phcl_accounts/features/transactions/presentation/pages/add_transaction_page.dart';
import 'package:phcl_accounts/core/services/connectivity_service.dart';

/// A comprehensive transactions management page that provides full CRUD operations,
/// advanced filtering, and real-time search capabilities for financial transactions.
///
/// **Features:**
/// - **Transaction Listing**: Displays paginated transactions with detailed information
/// - **Real-time Search**: Multi-field search across categories, amounts, client details, etc.
/// - **Advanced Filtering**: Filter by date range, transaction type (income/expense)
/// - **Role-based Access**: Different UI elements based on user permissions (admin/user/guest)
/// - **Interactive Operations**: View details, edit, delete transactions with confirmation dialogs
/// - **Responsive Design**: Adaptive layout with Material Design 3 theming
///
/// **Architecture:**
/// - Uses BLoC pattern for state management with [TransactionBloc] and [AuthBloc]
/// - Implements clean architecture with domain entities and presentation logic separation
/// - Follows Flutter best practices with proper lifecycle management
///
/// **User Roles:**
/// - **Admin**: Full CRUD operations, can add/edit/delete any transaction
/// - **User**: Can view and add transactions, limited editing permissions
/// - **Guest**: View-only access to transaction list
///
/// **Search Capabilities:**
/// - Searches across: category, amount, client ID, contact number, notes, transacted by
/// - Real-time filtering with debounced input for performance
/// - Animated search bar with clear functionality
/// - Result count display and contextual empty states
class TransactionsPage extends StatefulWidget {
  /// Creates a new transactions page widget.
  ///
  /// This page serves as the main hub for transaction management,
  /// providing comprehensive filtering, search, and CRUD operations.
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

/// State class for [TransactionsPage] that manages transaction filtering,
/// search functionality, and user interactions.
///
/// This class handles:
/// - Date range filtering for transaction queries
/// - Transaction type filtering (income/expense/all)
/// - Real-time search with multi-field capabilities
/// - UI state management for search bar visibility
/// - Navigation to transaction details and editing flows
class _TransactionsPageState extends State<TransactionsPage> {
  /// Selected date range for filtering transactions.
  /// Defaults to current month on initialization.
  DateTimeRange? _dateRange;

  /// Currently selected transaction type filter.
  /// Can be 'income', 'expense', or null (for all types).
  String? _selectedType;

  /// Controller for the search input field.
  /// Manages search text and provides text change listeners.
  final TextEditingController _searchController = TextEditingController();

  /// Current search query string used for filtering transactions.
  /// Updated in real-time as user types in search field.
  String _searchQuery = '';

  /// Controls the visibility state of the animated search bar.
  /// When true, search bar slides down with animation.
  bool _isSearchVisible = false;

  // Check connectivity
  bool _isOnline = false;

  /// Initializes the widget state and sets up initial data loading.
  ///
  /// - Loads transactions for the current month by default
  /// - Registers search controller listener for real-time search
  /// - Sets up initial UI state
  @override
  void initState() {
    super.initState();
    _loadInitialTransactions();
    _searchController.addListener(_onSearchChanged);
    ConnectivityService().checkConnection().then((status) {
      if (mounted) {
        setState(() {
          _isOnline = status;
        });
      }
    });
  }

  /// Cleans up resources when widget is disposed.
  ///
  /// - Removes search controller listener to prevent memory leaks
  /// - Disposes text controller properly
  /// - Ensures proper cleanup of state management
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Loads initial transactions for the current month.
  ///
  /// Sets up the default date range from the first day of the current month
  /// to today and triggers the initial transaction loading through the BLoC.
  /// This ensures users see relevant recent data when the page first loads.
  void _loadInitialTransactions() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    _dateRange = DateTimeRange(start: firstDayOfMonth, end: now);
    context.read<TransactionBloc>().add(
      LoadTransactions(startDate: _dateRange?.start, endDate: _dateRange?.end),
    );
  }

  /// Handles date range filter changes and reloads transactions.
  ///
  /// Called when user selects a new date range from the date picker.
  /// Updates the internal date range state and triggers a new transaction
  /// query with the selected range and current type filter.
  ///
  /// Parameters:
  /// - [range]: The new date range selected by the user
  void _onDateRangeChanged(DateTimeRange range) {
    if (mounted) {
      setState(() => _dateRange = range);
      context.read<TransactionBloc>().add(
        LoadTransactions(
          startDate: range.start,
          endDate: range.end,
          type: _selectedType,
        ),
      );
    }
  }

  /// Handles transaction type filter changes and reloads data.
  ///
  /// Called when user selects a different transaction type filter
  /// (All, Income, Expense). Updates the internal type state and
  /// triggers a new transaction query with current date range.
  ///
  /// Parameters:
  /// - [type]: The selected transaction type ('income', 'expense', or null for all)
  void _onTypeChanged(String? type) {
    if (mounted) {
      setState(() => _selectedType = type);
      context.read<TransactionBloc>().add(
        LoadTransactions(
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
          type: type,
        ),
      );
    }
  }

  /// Handles search input changes and updates filter query.
  ///
  /// Called whenever the search text field content changes.
  /// Converts input to lowercase for case-insensitive searching
  /// and triggers UI update to filter displayed transactions.
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  /// Toggles the search bar visibility with animation.
  ///
  /// Shows/hides the animated search bar and manages search state.
  /// When hiding search, clears the search query and controller
  /// to reset the transaction list to unfiltered state.
  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  /// Filters transactions based on the current search query.
  ///
  /// Performs multi-field search across transaction properties:
  /// - **Category**: Transaction category/type
  /// - **Amount**: Transaction amount (converted to string)
  /// - **Client ID**: Client identification number
  /// - **Contact Number**: Client contact information
  /// - **Note**: Transaction description/notes
  /// - **Transact By**: User who created the transaction
  ///
  /// The search is case-insensitive and matches partial strings.
  /// Returns the original list if search query is empty.
  ///
  /// Parameters:
  /// - [transactions]: The list of transactions to filter
  ///
  /// Returns:
  /// - Filtered list of transactions matching the search criteria
  List<TransactionEntity> _filterTransactions(
    List<TransactionEntity> transactions,
  ) {
    if (_searchQuery.isEmpty) {
      return transactions;
    }

    return transactions.where((transaction) {
      final searchFields = [
        transaction.category.toLowerCase(),
        transaction.amount.toString(),
        transaction.clientId?.toLowerCase() ?? '',
        transaction.contactNo?.toLowerCase() ?? '',
        transaction.note?.toLowerCase() ?? '',
        transaction.transactBy?.toLowerCase() ?? '',
        DateFormat('MMM dd, yyyy').format(transaction.date).toLowerCase(),
      ];

      return searchFields.any((field) => field.contains(_searchQuery));
    }).toList();
  }

  /// Builds the main UI for the transactions page.
  ///
  /// Creates a comprehensive interface with:
  /// - **AppBar**: Title, search toggle, and navigation
  /// - **Date Range Selector**: Interactive date filtering with presets
  /// - **Search Bar**: Animated multi-field search functionality
  /// - **Type Filter Chips**: Quick filtering by transaction type
  /// - **Transaction List**: Paginated list with role-based actions
  /// - **Floating Action Buttons**: Quick actions for adding transactions
  /// - **Pull-to-Refresh**: Gesture-based data refreshing
  ///
  /// The UI adapts based on user permissions and current state
  /// (loading, error, empty, search results, etc.).
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshTransactions,
        child: Column(
          children: [
            // Enhanced Date Range Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DateRangeSelector(
                initialRange: _dateRange,
                onChanged: _onDateRangeChanged,
                presetLabels: const [
                  'This Week',
                  'This Month',
                  'Last 3 Months',
                  'This Year',
                ],
              ),
            ),

            // Transaction Type Filter
            _buildTypeFilterChips(),

            // Transaction Search Bar
            _buildSearchBar(),

            // Transaction List
            Expanded(
              child: BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  if (state is TransactionLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is TransactionError) {
                    return _buildErrorState(state.message);
                  }
                  if (state is TransactionLoaded) {
                    // First apply type filter
                    var transactions = state.transactions.where((t) {
                      if (state.currentType != null) {
                        return t.type == state.currentType;
                      }
                      return true;
                    }).toList();

                    // Then apply search filter
                    transactions = _filterTransactions(transactions);

                    if (transactions.isEmpty) {
                      if (_isOnline == false) {
                        return _buildNoInternetState();
                      }
                      return _buildEmptyState();
                    }

                    // Show search results count if searching
                    if (_searchQuery.isNotEmpty) {
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${transactions.length} result(s) for "${_searchController.text}"',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: _buildTransactionList(transactions)),
                        ],
                      );
                    }
                    return _buildTransactionList(transactions);
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Only show floating action buttons for authenticated users who are not guests
          if (state is AuthAuthenticated &&
              (state.user.role == 'admin' || state.user.role == 'user')) {
            return _buildFloatingActionButtons();
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Builds the floating action buttons for quick transaction creation.
  ///
  /// Creates a vertical column of action buttons:
  /// - **Income Button**: Green-themed button with '+' icon for adding income
  /// - **Expense Button**: Red-themed button with '-' icon for adding expenses
  ///
  /// Each button navigates to the add transaction page with the appropriate
  /// transaction type pre-selected. Uses unique hero tags to prevent
  /// animation conflicts between multiple floating action buttons.
  ///
  /// Returns:
  /// - Column widget containing the stacked floating action buttons
  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'add_income',
          onPressed: () => _navigateToAddTransaction(context, 'income'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          child: Icon(Icons.add),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'add_expense',
          onPressed: () => _navigateToAddTransaction(context, 'expense'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          child: Icon(Icons.remove),
        ),
      ],
    );
  }

  /// Builds the empty state widget with context-aware messaging.
  ///
  /// Displays different content based on whether the user is actively searching
  /// or viewing an empty transaction list:
  ///
  /// **Search Mode**: Shows "No results found" with search-off icon and
  /// suggestions to adjust search terms, plus a clear search button
  ///
  /// **Default Mode**: Shows "No transactions found" with receipt icon and
  /// encouragement to add the first transaction
  ///
  /// The widget provides visual feedback and actionable next steps to guide
  /// user behavior in both scenarios.
  ///
  /// Returns:
  /// - Centered column with icon, message, and optional action button
  Widget _buildEmptyState() {
    final bool isSearching = _searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.receipt_long,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No results found' : 'No transactions found',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try adjusting your search terms'
                : 'Add your first transaction to get started',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (isSearching) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the no internet state widget with context-aware messaging.
  ///
  /// Displays different content based on whether the user is actively searching
  /// or viewing an empty transaction list:
  ///
  /// The widget provides visual feedback and actionable next steps to guide
  /// user behavior in both scenarios.
  ///
  /// Returns:
  /// - Centered column with icon, message, and optional action button
  Widget _buildNoInternetState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No internet connection',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your internet connection and try again.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the error state widget with user-friendly messaging.
  ///
  /// Displays an error screen when transaction loading fails:
  /// - **Error Icon**: Red error outline icon for visual clarity
  /// - **Error Title**: Generic "Something went wrong" message
  /// - **Error Details**: Specific error message passed as parameter
  ///
  /// This provides users with clear feedback when network requests fail,
  /// database errors occur, or other exceptions happen during data loading.
  ///
  /// Parameters:
  /// - [message]: Specific error message to display to the user
  ///
  /// Returns:
  /// - Centered column with error icon and descriptive text
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshTransactions,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshTransactions() async {
    context.read<TransactionBloc>().add(
      LoadTransactions(
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        type: _selectedType,
      ),
    );
  }

  /// Builds the animated search bar widget with comprehensive search functionality.
  ///
  /// Creates a collapsible search interface that:
  /// - **Animates**: Smooth slide-down animation when toggled (300ms duration)
  /// - **Auto-focuses**: Automatically focuses when expanded for immediate typing
  /// - **Multi-action**: Clear button when text exists, close button when empty
  /// - **Real-time**: Updates search results as user types with no delay
  /// - **Styled**: Material Design 3 theming with proper contrast and borders
  ///
  /// **Search Capabilities**:
  /// - Searches across 6+ transaction fields simultaneously
  /// - Case-insensitive partial string matching
  /// - Descriptive placeholder text explaining searchable fields
  ///
  /// **Interaction**:
  /// - Toggle visibility with `_toggleSearch()` method
  /// - Clear search with dedicated clear button
  /// - Close search bar resets all search state
  ///
  /// Returns:
  /// - AnimatedContainer with TextField or SizedBox based on visibility
  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isSearchVisible ? 60 : 0,
      child: _isSearchVisible
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
              ),
              child: TextField(
                controller: _searchController,
                // autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search By (category, amount, client, note...)',
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _toggleSearch,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            )
          : const SizedBox(),
    );
  }

  /// Builds the transaction list widget
  /// Builds the scrollable transaction list with role-based interactions.
  ///
  /// Creates a performant ListView that:
  /// - **Renders**: Transaction items with consistent spacing and design
  /// - **Scrolls**: Always scrollable physics for pull-to-refresh compatibility
  /// - **Adapts**: Role-based UI showing different actions per user permission
  /// - **Interacts**: Tap for details, edit/delete for admins only
  ///
  /// **Role-based Features**:
  /// - **Admin Users**: Full CRUD access with edit and delete buttons
  /// - **Regular Users**: View-only access with detail navigation
  /// - **Guest Users**: Limited view access (handled by parent widgets)
  ///
  /// Each transaction item uses `TransactionItem` widget for consistent
  /// presentation and handles authentication state through nested BlocBuilder
  /// to ensure real-time permission updates.
  ///
  /// Parameters:
  /// - [transactions]: List of filtered/searched transactions to display
  ///
  /// Returns:
  /// - ListView.builder with dynamic content based on user permissions
  Widget _buildTransactionList(List<TransactionEntity> transactions) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final isAdmin =
                  authState is AuthAuthenticated &&
                  authState.user.role == 'admin';

              return TransactionItem(
                transaction: transactions[index],
                onTap: () =>
                    _showTransactionDetails(context, transactions[index]),
                onDelete: isAdmin
                    ? () =>
                          _showDeleteConfirmDialog(context, transactions[index])
                    : null,
                onEdit: isAdmin
                    ? () => _editTransaction(context, transactions[index])
                    : null,
                showEditButton: isAdmin,
              );
            },
          ),
        );
      },
    );
  }

  /// Builds the transaction type filter chips for quick filtering.
  ///
  /// Creates a horizontal row of selectable filter chips:
  /// - **All**: Shows all transactions (default state)
  /// - **Income**: Filters to show only income transactions
  /// - **Expense**: Filters to show only expense transactions
  ///
  /// **Visual Design**:
  /// - Material Design 3 filter chips with proper theming
  /// - Selected state with primary color and checkmark
  /// - Compact sizing with 12px font for space efficiency
  /// - Proper spacing and padding for touch targets
  ///
  /// **Functionality**:
  /// - Integrates with BLoC state to show current selection
  /// - Updates transaction query when selection changes
  /// - Only shows when transactions are loaded (proper state handling)
  ///
  /// Each chip triggers `_onTypeChanged()` method which updates both
  /// local state and triggers new transaction loading through BLoC.
  ///
  /// Returns:
  /// - Row of FilterChip widgets or SizedBox if not in loaded state
  Widget _buildTypeFilterChips() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is! TransactionLoaded) return const SizedBox();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All', style: TextStyle(fontSize: 12)),
                selected: state.currentType == null,
                onSelected: (_) => _onTypeChanged(null),
                selectedColor: Theme.of(context).colorScheme.primary,
                checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                labelStyle: TextStyle(
                  color: state.currentType == null
                      ? Theme.of(context).colorScheme.onPrimary
                      : null,
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Income', style: TextStyle(fontSize: 12)),
                selected: state.currentType == 'income',
                onSelected: (_) => _onTypeChanged('income'),
                selectedColor: Theme.of(context).colorScheme.tertiary,
                checkmarkColor: Theme.of(context).colorScheme.onTertiary,
                labelStyle: TextStyle(
                  color: state.currentType == 'income'
                      ? Theme.of(context).colorScheme.onTertiary
                      : null,
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Expense', style: TextStyle(fontSize: 12)),
                selected: state.currentType == 'expense',
                onSelected: (_) => _onTypeChanged('expense'),
                selectedColor: Theme.of(context).colorScheme.error,
                checkmarkColor: Theme.of(context).colorScheme.onError,
                labelStyle: TextStyle(
                  color: state.currentType == 'expense'
                      ? Theme.of(context).colorScheme.onError
                      : null,
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              const Spacer(),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                icon: Icon(
                  _isSearchVisible ? Icons.search_off : Icons.search,
                  // color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: _toggleSearch,
                tooltip: _isSearchVisible
                    ? 'Hide search'
                    : 'Search transactions',
              ),
            ],
          ),
        );
      },
    );
  }

  /// Navigates to the add transaction page with pre-selected type.
  ///
  /// Opens the transaction creation flow with the specified transaction type:
  /// - **BLoC Sharing**: Passes current TransactionBloc instance to maintain state
  /// - **Type Pre-selection**: Sets income or expense type before navigation
  /// - **Result Handling**: Processes return result to refresh data if needed
  /// - **State Management**: Preserves current filters and search state
  ///
  /// **Navigation Flow**:
  /// 1. Captures current BLoC instance for state sharing
  /// 2. Pushes AddTransactionPage with BlocProvider.value
  /// 3. Waits for navigation result (boolean success indicator)
  /// 4. Reloads transactions if new transaction was added
  /// 5. Maintains current date range and type filters
  ///
  /// **Lifecycle Safety**:
  /// - Checks widget mount state before handling result
  /// - Prevents memory leaks from async operations
  ///
  /// Parameters:
  /// - [context]: Build context for navigation
  /// - [type]: Transaction type ('income' or 'expense') to pre-select
  Future<void> _navigateToAddTransaction(
    BuildContext context,
    String type,
  ) async {
    // Get the bloc instance to share state between pages
    final bloc = context.read<TransactionBloc>();

    // Navigate to add transaction page with shared BLoC instance
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: bloc,
          child: AddTransactionPage(transactionType: type),
        ),
      ),
    );

    // Check if widget is still mounted
    if (!mounted) return;

    // Handle the return result - always reload with current widget state filters
    if (result == null || result == false) {
      // Use the current widget state variables to preserve filters
      bloc.add(
        LoadTransactions(
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
          type: _selectedType,
        ),
      );
    }
  }

  /// Shows transaction details in a modal bottom sheet.
  ///
  /// Displays comprehensive transaction information in a scrollable
  /// bottom sheet overlay that slides up from the bottom of the screen.
  /// Uses `TransactionDetailsSheet` widget for consistent presentation.
  ///
  /// **Features**:
  /// - Scrollable content for long transaction details
  /// - Modal overlay with backdrop dismiss
  /// - Material Design bottom sheet styling
  /// - Full transaction data display
  ///
  /// Parameters:
  /// - [context]: Build context for navigation
  /// - [transaction]: Transaction entity to display details for
  void _showTransactionDetails(
    BuildContext context,
    TransactionEntity transaction,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TransactionDetailsSheet(transaction: transaction),
    );
  }

  /// Shows confirmation dialog before deleting a transaction.
  ///
  /// Displays a Material Design alert dialog asking the user to confirm
  /// the delete action. This prevents accidental deletion of transactions
  /// and provides a clear UI pattern for destructive actions.
  ///
  /// **Dialog Content**:
  /// - Warning title and descriptive message
  /// - Cancel and Delete action buttons
  /// - Proper button styling (Cancel: text, Delete: filled with error color)
  /// - Dismissible with backdrop tap or back button
  ///
  /// Only proceeds with deletion if user confirms by pressing "Delete".
  ///
  /// Parameters:
  /// - [context]: Build context for dialog display
  /// - [transaction]: Transaction entity to potentially delete
  void _showDeleteConfirmDialog(
    BuildContext context,
    TransactionEntity transaction,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: Text(
            'Are you sure you want to delete this ${transaction.type} transaction of ৳${NumberFormat().format(transaction.amount)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTransaction(transaction);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  /// Deletes a transaction and handles the deletion process.
  ///
  /// Performs the actual transaction deletion after user confirmation:
  /// - **Validates**: Ensures transaction has a valid ID before proceeding
  /// - **Deletes**: Sends delete event to TransactionBloc for processing
  /// - **Feedback**: Shows error snackbar if transaction ID is missing
  /// - **Updates**: Triggers UI refresh through BLoC state management
  ///
  /// **Error Handling**:
  /// - Validates transaction ID presence before deletion attempt
  /// - Shows user-friendly error message if ID is null/missing
  /// - Uses theme-appropriate error colors for visual consistency
  ///
  /// The actual deletion is handled by the BLoC layer, which manages
  /// the repository call, error handling, and state updates.
  ///
  /// Parameters:
  /// - [transaction]: Transaction entity to delete (must have valid ID)
  void _deleteTransaction(TransactionEntity transaction) {
    final transactionId = transaction.id;
    if (transactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Transaction ID is missing'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    context.read<TransactionBloc>().add(
      DeleteTransaction(
        transactionId,
        _dateRange?.start,
        _dateRange?.end,
        _selectedType,
      ),
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaction deleted successfully'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// Navigates to transaction editing flow using the add transaction page.
  ///
  /// Opens the transaction editing interface by reusing AddTransactionPage
  /// with the existing transaction data pre-populated:
  /// - **Edit Mode**: Passes existing transaction to populate form fields
  /// - **Type Consistency**: Maintains transaction type (income/expense)
  /// - **BLoC Sharing**: Uses same TransactionBloc instance for state consistency
  /// - **Result Processing**: Handles edit completion and refreshes data
  ///
  /// **Edit Flow**:
  /// 1. Captures current BLoC instance for state sharing
  /// 2. Navigates to AddTransactionPage in edit mode
  /// 3. Pre-populates form with existing transaction data
  /// 4. Processes edit result and refreshes transaction list
  /// 5. Maintains current filters and search state
  ///
  /// **Admin Access**: This method is only callable by admin users,
  /// as controlled by the UI that provides the edit action.
  ///
  /// Parameters:
  /// - [context]: Build context for navigation
  /// - [transaction]: Existing transaction entity to edit
  Future<void> _editTransaction(
    BuildContext context,
    TransactionEntity transaction,
  ) async {
    // Get the bloc instance to maintain state consistency
    final bloc = context.read<TransactionBloc>();

    // Navigate to edit mode using AddTransactionPage with existing data
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: bloc,
          child: AddTransactionPage(
            transactionType: transaction.type,
            existingTransaction: transaction,
          ),
        ),
      ),
    );

    // Check if widget is still mounted
    if (!mounted) return;

    // Handle the return result - always reload with current widget state filters
    if (result == null || result == false) {
      // Use the current widget state variables to preserve filters
      bloc.add(
        LoadTransactions(
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
          type: _selectedType,
        ),
      );
    }
  }
}
