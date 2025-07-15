import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:phcl_accounts/core/widgets/custom_icon_button.dart';
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
  String? _attachmentUrl;
  StreamSubscription? _uploadSubscription;

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
              _buildDatePicker(),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildAmountField(),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
        prefixText: '৳ ',
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
          spacing: 16,
            children: [
            CustomIconButton(onPressed: () => _pickAttachment(ImageSource.camera),  icon: Icons.camera_alt),
            CustomIconButton(onPressed: () => _pickAttachment(null),  icon: Icons.library_add ),
            ],
        ),
        if (_attachment != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildAttachmentPreview()
          ),
      ],
    );
  }

Future<void> _pickAttachment(ImageSource? imageSource) async {
  try {
    if (imageSource == ImageSource.camera) {
      final pickedImage = await ImagePicker().pickImage(
        source: imageSource!,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedImage != null) {
        final fileSize = await pickedImage.length();
        if (fileSize > 5 * 1024 * 1024) { // 5MB limit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size must be less than 5MB')),
          );
          return;
        }
        setState(() => _attachment = pickedImage);
      }
    } else {
      final pickedFile = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      
      if (pickedFile != null && pickedFile.files.isNotEmpty) {
        final file = pickedFile.files.first;
        if (file.size > 5 * 1024 * 1024) { // 5MB limit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size must be less than 5MB')),
          );
          return;
        }
        
        setState(() => _attachment = XFile(
          file.path!, 
          name: file.name,
        ));
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error selecting file: ${e.toString()}')),
    );
  }
}

Widget _buildAttachmentPreview() {
  final fileName = _attachment!.name.toLowerCase();
  final isImage = fileName.endsWith('.jpg') || 
                 fileName.endsWith('.jpeg') || 
                 fileName.endsWith('.png');
  final isPdf = fileName.endsWith('.pdf');
  final isWord = fileName.endsWith('.doc') || fileName.endsWith('.docx');

  return FutureBuilder<int>(
    future: _attachment!.length(),
    builder: (context, snapshot) {
      final fileSize = snapshot.hasData ? snapshot.data! : 0;
      
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              if (isImage)
                FutureBuilder<File>(
                  future: Future.value(File(_attachment!.path)),

                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: FileImage(snapshot.data!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Icon(
                      isPdf ? Icons.picture_as_pdf : 
                      isWord ? Icons.description : 
                      Icons.insert_drive_file,
                      size: 32,
                      color: isPdf ? Colors.red : 
                            isWord ? Colors.blue : 
                            Colors.grey,
                    ),
                  ),
                ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _attachment!.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isImage ? 'Image' : 
                      isPdf ? 'PDF Document' : 
                      isWord ? 'Word Document' : 'File',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(fileSize / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _attachment = null),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildSubmitButton() {
  return ElevatedButton(
    onPressed: _submitForm,
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
    ),
    child: const Text('Submit Transaction'),
  );
}

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing transaction...'),
            ],
          ),
        ),
      );

      try {
        // Upload attachment if exists
        if (_attachment != null) {
          _attachmentUrl = await _uploadAttachment();
          if (_attachmentUrl == null) {
            Navigator.pop(context); // Close loading dialog
            return; // Upload failed
          }
        }

        // Create transaction
        final transaction = TransactionEntity(
          type: widget.transactionType,
          category: _selectedCategory!,
          date: _selectedDate,
          amount: double.parse(_amountController.text),
          clientId: widget.transactionType == 'income' ? _clientIdController.text : null,
          contactNo: _contactNoController.text.isNotEmpty ? _contactNoController.text : null,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          attachmentUrl: _attachmentUrl,
          attachmentType: _attachment?.name.split('.').last.toLowerCase(),
        );

        // Add transaction
        context.read<TransactionBloc>().add(AddTransaction(transaction: transaction));
        
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Close the form
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<String?> _uploadAttachment() async {
    final completer = Completer<String?>();
    
    _uploadSubscription = context.read<TransactionBloc>().stream.listen((state) {
      if (state is AttachmentUploadSuccess) {
        completer.complete(state.downloadUrl);
      } else if (state is AttachmentUploadFailure) {
        completer.completeError(state.error);
      }
    });

    context.read<TransactionBloc>().add(UploadAttachment(widget.transactionType, _attachment!,
    ));

    try {
      return await completer.future;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload attachment: $e')),
      );
      return null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _clientIdController.dispose();
    _contactNoController.dispose();
    _uploadSubscription?.cancel();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}