import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';
import 'package:phcl_accounts/features/transactions/presentation/bloc/transaction_bloc.dart';

class AddTransactionPage extends StatefulWidget {
  final String transactionType;

  const AddTransactionPage({super.key, required this.transactionType});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _contactNoController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  XFile? _attachment;

  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(LoadCategories(widget.transactionType));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${widget.transactionType.capitalize()}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              if (widget.transactionType == 'income') ...[
                const SizedBox(height: 16),
                _buildClientIdField(),
                const SizedBox(height: 16),
                _buildContactNoField(),
              ],
              const SizedBox(height: 16),
              _buildNoteField(),
              const SizedBox(height: 16),
              _buildAttachmentPicker(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return const CircularProgressIndicator();
        }
        if (state is CategoryLoaded) {
          return DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: state.categories
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
            validator: (value) =>
                value == null ? 'Please select a category' : null,
          );
        }
        return const Text('Failed to load categories');
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'Amount',
        prefixText: '₹ ',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter amount';
        if (double.tryParse(value) == null) return 'Invalid amount';
        return null;
      },
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: const Text('Date'),
      subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
    );
  }

  Widget _buildClientIdField() {
    return TextFormField(
      controller: _clientIdController,
      decoration: const InputDecoration(
        labelText: 'Client ID',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter client ID';
        return null;
      },
    );
  }

  Widget _buildContactNoField() {
    return TextFormField(
      controller: _contactNoController,
      decoration: const InputDecoration(
        labelText: 'Contact No',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: const InputDecoration(
        labelText: 'Note (Optional)',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Widget _buildAttachmentPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attachment (Optional)'),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _pickAttachment(ImageSource.gallery),
              child: const Text('Gallery'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _pickAttachment(ImageSource.camera),
              child: const Text('Camera'),
            ),
          ],
        ),
        if (_attachment != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_attachment!.name),
          ),
      ],
    );
  }

  Future<void> _pickAttachment(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      setState(() => _attachment = picked);
    }
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitForm,
      child: const Text('Submit Transaction'),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final transaction = TransactionEntity(
        type: widget.transactionType,
        category: _selectedCategory!,
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        clientId: widget.transactionType == 'income' ? _clientIdController.text : null,
        contactNo: _contactNoController.text.isNotEmpty ? _contactNoController.text : null,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        // TODO: Handle attachment upload
      );

      context.read<TransactionBloc>().add(AddTransaction(transaction: transaction));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _clientIdController.dispose();
    _contactNoController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}