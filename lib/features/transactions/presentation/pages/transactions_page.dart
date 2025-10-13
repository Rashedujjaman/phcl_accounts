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

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  DateTimeRange? _dateRange;
  String? _selectedType;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _loadInitialTransactions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialTransactions() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    _dateRange = DateTimeRange(start: firstDayOfMonth, end: now);
    context.read<TransactionBloc>().add(
      LoadTransactions(startDate: _dateRange?.start, endDate: _dateRange?.end),
    );
  }

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

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  /// Filters transactions based on search query
  /// Searches across: category, amount, clientId, contactNo, note, transactBy fields
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

  /// Builds the search bar widget with animation and search functionality
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

  Future<void> _navigateToAddTransaction(
    BuildContext context,
    String type,
  ) async {
    // Get the bloc instance
    final bloc = context.read<TransactionBloc>();

    // Navigate to add transaction page
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

  Future<void> _editTransaction(
    BuildContext context,
    TransactionEntity transaction,
  ) async {
    // Get the bloc instance
    final bloc = context.read<TransactionBloc>();

    // Navigate to edit transaction page using AddTransactionPage with existing transaction
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
