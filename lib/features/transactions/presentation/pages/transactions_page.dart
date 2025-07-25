import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    _loadInitialTransactions();
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
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
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
                    final transactions = state.transactions.where((t) {
                      if (state.currentType != null) {
                        return t.type == state.currentType;
                      }
                      return true;
                    }).toList();

                    if (transactions.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TransactionItem(
                            transaction: transactions[index],
                            onTap: () => _showTransactionDetails(
                              context,
                              transactions[index],
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first transaction to get started',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
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
                  color: state.currentType == null ? Theme.of(context).colorScheme.onPrimary : null,
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Income', style: TextStyle(fontSize: 12)),
                selected: state.currentType == 'income',
                onSelected: (_) => _onTypeChanged('income'),
                selectedColor: Theme.of(context).colorScheme.tertiary,
                checkmarkColor: Theme.of(context).colorScheme.onTertiary,
                labelStyle: TextStyle(
                  color: state.currentType == 'income' ? Theme.of(context).colorScheme.onTertiary : null,
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Expense', style: TextStyle(fontSize: 12)),
                selected: state.currentType == 'expense',
                onSelected: (_) => _onTypeChanged('expense'),
                selectedColor: Theme.of(context).colorScheme.error,
                checkmarkColor: Theme.of(context).colorScheme.onError,
                labelStyle: TextStyle(
                  color: state.currentType == 'expense' ? Theme.of(context).colorScheme.onError : null,
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
    // Get the current state before navigation
    final bloc = context.read<TransactionBloc>();
    final currentState = bloc.state;

    // Store the current filter values
    DateTime? startDate;
    DateTime? endDate;
    String? currentType;

    if (currentState is TransactionLoaded) {
      startDate = currentState.currentStartDate;
      endDate = currentState.currentEndDate;
      currentType = currentState.currentType;
    }

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

    // Handle the return result
    if (result == null || result == false) {
      // Always reload with the original filters
      bloc.add(
        LoadTransactions(
          startDate: startDate,
          endDate: endDate,
          type: currentType,
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
}
