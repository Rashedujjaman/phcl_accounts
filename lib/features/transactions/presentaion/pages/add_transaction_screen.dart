import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entry.dart';
import 'package:phcl_accounts/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fluttertoast/fluttertoast.dart';


class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _attachment;
  String _transactionType = 'expense';
  final _categoryController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      setState(() {
        _attachment = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final transaction = TransactionEntity(
        type: _transactionType,
        category: _categoryController.text,
        clientId: _clientIdController.text,
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        contactNo: _contactNoController.text,
        description: _descriptionController.text,
      );

      try {
        await context.read<TransactionRepository>().addTransaction(
              transaction,
              _attachment,
            );
        Navigator.pop(context);
      } catch (e) {
        Fluttertoast.showToast(msg: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Form fields for transaction details
              // Date picker, type selector, category, client ID, etc.
              
              if (_attachment != null)
                _attachment!.path.endsWith('.pdf')
                  ? const Icon(Icons.picture_as_pdf, size: 100)
                  : Image.file(_attachment!, height: 100),
              
              ElevatedButton(
                onPressed: _pickAttachment,
                child: const Text('Add Proof'),
              ),
              
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}