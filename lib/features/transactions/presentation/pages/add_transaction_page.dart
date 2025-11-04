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
  final TransactionEntity? existingTransaction;

  const AddTransactionPage({
    super.key,
    required this.transactionType,
    this.existingTransaction,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _transactByController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  XFile? _attachment;
  String? _attachmentUrl;
  String? _attachmentType;
  StreamSubscription? _uploadSubscription;

  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(LoadCategories(widget.transactionType));

    // If editing an existing transaction, populate the form fields
    if (widget.existingTransaction != null) {
      _populateFormWithExistingData();
    }
  }

  void _populateFormWithExistingData() {
    final transaction = widget.existingTransaction!;
    _amountController.text = transaction.amount.toString();
    _noteController.text = transaction.note ?? '';
    _clientIdController.text = transaction.clientId ?? '';
    _contactNoController.text = transaction.contactNo ?? '';
    _transactByController.text = transaction.transactBy ?? '';
    _selectedDate = transaction.date;
    _selectedCategory = transaction.category;
    _attachmentUrl = transaction.attachmentUrl;
    _attachmentType = transaction.attachmentType;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.existingTransaction != null ? 'Edit' : 'Add'} ${widget.transactionType.capitalize()}',
          ),
          backgroundColor: widget.transactionType == 'income'
              ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
          // backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildDatePicker(),
                const SizedBox(height: 16),
                _buildCategoryDropdown(),
                const SizedBox(height: 16),
                _buildTransactByField(),
                const SizedBox(height: 16),
                _buildAmountField(),
                const SizedBox(height: 16),
                if (widget.transactionType == 'income') ...[
                  const SizedBox(height: 16),
                  _buildClientIdField(),
                  const SizedBox(height: 16),
                  _buildContactNoField(),
                  const SizedBox(height: 16),
                ],
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
          final categories = state.categories;
          return TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Category',
              hintText: 'Select a category',
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            controller: TextEditingController(text: _selectedCategory ?? ''),
            validator: (value) => (value == null || value.isEmpty)
                ? 'Please select a category'
                : null,
            onTap: () async {
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;

              final selectedValue = await showMenu<String>(
                context: context,
                position: RelativeRect.fromLTRB(
                  position.dx,
                  position.dy + size.height,
                  position.dx + size.width,
                  position.dy + size.height + 300,
                ),
                constraints: BoxConstraints(
                  minWidth: size.width,
                  maxWidth: size.width,
                  maxHeight: 300,
                ),
                items: [
                  for (var category in categories)
                    PopupMenuItem<String>(
                      value: category,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                ],
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );

              if (selectedValue != null && mounted) {
                setState(() => _selectedCategory = selectedValue);
              }
            },
          );
        }
        return const Text('Failed to load categories');
      },
    );
  }

  Widget _buildTransactByField() {
    return TextFormField(
      controller: _transactByController,
      decoration: const InputDecoration(
        labelText: 'Transact By',
        border: OutlineInputBorder(),
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: ListTile(
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
          if (picked != null && mounted) {
            setState(() => _selectedDate = picked);
          }
        },
      ),
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
            CustomIconButton(
              onPressed: () => _pickAttachment(ImageSource.camera),
              icon: Icons.camera_alt,
            ),
            CustomIconButton(
              onPressed: () => _pickAttachment(null),
              icon: Icons.library_add,
            ),
          ],
        ),
        // Show new attachment preview if a new file is selected
        if (_attachment != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildAttachmentPreview(),
          ),
        // Show existing attachment preview if editing and no new attachment selected
        if (_attachment == null &&
            _attachmentUrl != null &&
            _attachmentUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildExistingAttachmentPreview(),
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
          if (fileSize > 5 * 1024 * 1024) {
            // 5MB limit
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File size must be less than 5MB'),
                ),
              );
            }
            return;
          }
          if (mounted) {
            setState(() {
              _attachment = pickedImage;
              _attachmentUrl =
                  null; // Clear existing attachment URL when new file is picked
            });
          }
        }
      } else {
        final pickedFile = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
          withData: true,
        );

        if (pickedFile != null && pickedFile.files.isNotEmpty) {
          final file = pickedFile.files.first;
          if (file.size > 5 * 1024 * 1024) {
            // 5MB limit
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File size must be less than 5MB'),
                ),
              );
            }
            return;
          }

          if (mounted) {
            setState(() {
              _attachment = XFile(file.path!, name: file.name);
              _attachmentUrl =
                  null; // Clear existing attachment URL when new file is picked
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildAttachmentPreview() {
    final fileName = _attachment!.name.toLowerCase();
    final isImage =
        fileName.endsWith('.jpg') ||
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
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Icon(
                        isPdf
                            ? Icons.picture_as_pdf
                            : isWord
                            ? Icons.description
                            : Icons.insert_drive_file,
                        size: 32,
                        color: isPdf
                            ? Theme.of(context).colorScheme.error
                            : isWord
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
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
                        isImage
                            ? 'Image'
                            : isPdf
                            ? 'PDF Document'
                            : isWord
                            ? 'Word Document'
                            : 'File',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(fileSize / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    if (mounted) {
                      setState(() => _attachment = null);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExistingAttachmentPreview() {
    if (_attachmentUrl == null || _attachmentUrl!.isEmpty) {
      return const SizedBox();
    }

    // // Extract file name from URL (get the last part after '/')
    // final fileName = _attachmentUrl!.split('/').last;
    // final fileNameLower = fileName.toLowerCase();

    // Determine file type from extension
    final isImage =
        _attachmentType == 'jpg' ||
        _attachmentType == 'jpeg' ||
        _attachmentType == 'png' ||
        _attachmentType == 'webp';
    final isPdf = _attachmentType == 'pdf';
    final isWord = _attachmentType == 'doc' || _attachmentType == 'docx';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Preview thumbnail or icon
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  _attachmentUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Show fallback icon if image fails to load
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.image,
                        size: 32,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Icon(
                    isPdf
                        ? Icons.picture_as_pdf
                        : isWord
                        ? Icons.description
                        : Icons.insert_drive_file,
                    size: 32,
                    color: isPdf
                        ? Theme.of(context).colorScheme.error
                        : isWord
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            const SizedBox(width: 12),

            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(
                  //   fileName,
                  //   style: const TextStyle(fontWeight: FontWeight.w500),
                  //   maxLines: 1,
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                  // const SizedBox(height: 4),
                  Text(
                    isImage
                        ? 'Image'
                        : isPdf
                        ? 'PDF Document'
                        : isWord
                        ? 'Word Document'
                        : 'File',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Existing attachment',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Delete button for existing attachment
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              icon: const Icon(Icons.delete_forever, size: 20),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _attachmentUrl = null;
                  });
                }
              },
              tooltip: 'Remove existing attachment',
            ),
          ],
        ),
      ),
    );
  }

  String? _getFileTypeFromUrl(String url) {
    final fileName = url.split('/').last.toLowerCase();
    if (fileName.contains('.')) {
      return fileName.split('.').last;
    }
    return null;
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.transactionType == 'income'
            ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5)
            : Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: widget.transactionType == 'income'
                ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
      child: Text(
        widget.existingTransaction != null
            ? 'Update Transaction'
            : 'Submit Transaction',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(padding: EdgeInsets.all(16)),
              const SizedBox(height: 16),
              Text(
                widget.existingTransaction != null
                    ? 'Updating transaction...'
                    : 'Processing transaction...',
              ),
            ],
          ),
        ),
      );

      try {
        // Upload attachment if exists
        if (_attachment != null) {
          _attachmentUrl = await _uploadAttachment();
          if (_attachmentUrl == null) {
            if (mounted) {
              Navigator.pop(context); // Close loading dialog
            }
            return; // Upload failed
          }
        }

        // Create transaction
        final transaction = TransactionEntity(
          id: widget.existingTransaction?.id, // Keep existing ID when updating
          type: widget.transactionType,
          category: _selectedCategory!,
          date: _selectedDate,
          transactBy: _transactByController.text.isNotEmpty
              ? _transactByController.text
              : null,
          amount: double.parse(_amountController.text),
          clientId: widget.transactionType == 'income'
              ? _clientIdController.text
              : null,
          contactNo: _contactNoController.text.isNotEmpty
              ? _contactNoController.text
              : null,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          attachmentUrl: _attachmentUrl,
          attachmentType:
              _attachment?.name.split('.').last.toLowerCase() ??
              (_attachmentUrl != null
                  ? _getFileTypeFromUrl(_attachmentUrl!)
                  : null),
        );

        // Add or update transaction
        if (mounted) {
          if (widget.existingTransaction != null) {
            // Update existing transaction
            context.read<TransactionBloc>().add(
              UpdateTransaction(
                transaction,
                _selectedDate, // startDate
                _selectedDate, // endDate
              ),
            );
          } else {
            // Add new transaction
            context.read<TransactionBloc>().add(
              AddTransaction(transaction: transaction),
            );
          }

          Navigator.pop(context); // Close loading dialog
          Navigator.pop(context, true); // Close the form
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  Future<String?> _uploadAttachment() async {
    final completer = Completer<String?>();

    _uploadSubscription = context.read<TransactionBloc>().stream.listen((
      state,
    ) {
      if (!mounted) {
        // Widget has been disposed, cancel the operation
        if (!completer.isCompleted) {
          completer.completeError('Widget disposed during upload');
        }
        return;
      }

      if (state is AttachmentUploadSuccess) {
        if (!completer.isCompleted) {
          completer.complete(state.downloadUrl);
        }
      } else if (state is AttachmentUploadFailure) {
        if (!completer.isCompleted) {
          completer.completeError(state.error);
        }
      }
    });

    context.read<TransactionBloc>().add(
      UploadAttachment(widget.transactionType, _attachment!),
    );

    try {
      return await completer.future;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
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
