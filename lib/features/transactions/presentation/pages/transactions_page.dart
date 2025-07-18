import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';
import 'package:phcl_accounts/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:phcl_accounts/features/transactions/presentation/widgets/date_range_selector.dart';
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
          LoadTransactions(
            startDate: _dateRange?.start,
            endDate: _dateRange?.end,
          ),
        );
  }

  void _onDateRangeChanged(DateTimeRange range) {
    setState(() => _dateRange = range);
    context.read<TransactionBloc>().add(
          LoadTransactions(
            startDate: range.start,
            endDate: range.end,
            type: _selectedType,
          ),
        );
  }

  void _onTypeChanged(String? type) {
    setState(() => _selectedType = type);
    context.read<TransactionBloc>().add(
          LoadTransactions(
            startDate: _dateRange?.start,
            endDate: _dateRange?.end,
            type: type,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Column(
        children: [
          // Date Range Selector
          DateRangeSelector(
            initialRange: _dateRange,
            onChanged: _onDateRangeChanged,
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
                  return Center(child: Text(state.message));
                }
                if (state is TransactionLoaded) {
                  final transactions = state.transactions.where((t){
                    if (state.currentType != null) {
                      return t.type == state.currentType;
                    }
                    return true;
                  }).toList();

                  if (transactions.isEmpty) {
                    return const Center(child: Text('No transactions found'));
                  }
                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      return TransactionItem(
                        transaction: transactions[index],
                        onTap: () => _showTransactionDetails(
                            context, transactions[index]),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'add_income',
            onPressed: () => _navigateToAddTransaction(context, 'income'),
            backgroundColor: Colors.green[100],
            child: const Icon(Icons.add, color: Colors.green),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_expense',
            onPressed: () => _navigateToAddTransaction(context, 'expense'),
            backgroundColor: Colors.red[100],
            child: const Icon(Icons.remove, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChips() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is! TransactionLoaded) return const SizedBox();
        
        return Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: state.currentType == null,
              onSelected: (_) => _onTypeChanged(null)              
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Income'),
              selected: state.currentType == 'income',
              onSelected: (_) => _onTypeChanged('income')
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Expense'),
              selected: state.currentType == 'expense',
              onSelected: (_) => _onTypeChanged('expense')
            ),
          ],
        )
        );
      },
    );
  }

Future<void> _navigateToAddTransaction(BuildContext context, String type) async {
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
    bloc.add(LoadTransactions(
      startDate: startDate,
      endDate: endDate,
      type: currentType,
    ));
  }
}

  void _showTransactionDetails(BuildContext context, TransactionEntity transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TransactionDetailsSheet(transaction: transaction),
    );
  }
}