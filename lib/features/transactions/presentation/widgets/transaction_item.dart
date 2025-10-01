import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phcl_accounts/features/transactions/domain/entities/transaction_entity.dart';

class TransactionItem extends StatefulWidget {
  final TransactionEntity transaction;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool showEditButton;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.onTap,
    this.onDelete,
    this.onEdit,
    this.showEditButton = false,
  });

  @override
  State<TransactionItem> createState() => _TransactionItemState();
}

class _TransactionItemState extends State<TransactionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late double _maxSlideDistance;
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = widget.transaction.type == 'income';
    final color = isIncome
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;
    final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;

    // Calculate action buttons count and width
    int actionCount = 0;
    if (widget.onDelete != null) actionCount++;
    if (widget.onEdit != null && widget.showEditButton) actionCount++;

    // If no swipe actions are available, return the simple card with gesture detection for onTap
    if (actionCount == 0) {
      return GestureDetector(
        onTap: widget.onTap,
        child: _buildTransactionCard(theme, color, icon),
      );
    }

    // Calculate max slide distance (half of screen width, but limited)
    _maxSlideDistance = MediaQuery.of(context).size.width * 0.4;
    final actionButtonWidth = _maxSlideDistance / actionCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Background action buttons
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: _maxSlideDistance,
              child: Row(
                children: _buildActionButtons(theme, actionButtonWidth),
              ),
            ),
            // Main transaction card with gesture detection
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                final slideOffset = _slideAnimation.value * _maxSlideDistance;
                return Transform.translate(
                  offset: Offset(-slideOffset, 0),
                  child: GestureDetector(
                    onPanStart: (details) {
                      _isSliding = true;
                    },
                    onPanUpdate: (details) {
                      if (_isSliding) {
                        // Only allow left swipe (negative delta)
                        if (details.delta.dx < 0) {
                          final newValue =
                              (_controller.value -
                                      details.delta.dx / _maxSlideDistance)
                                  .clamp(0.0, 1.0);
                          _controller.value = newValue;
                        } else if (details.delta.dx > 0 &&
                            _controller.value > 0) {
                          // Allow right swipe to close
                          final newValue =
                              (_controller.value -
                                      details.delta.dx / _maxSlideDistance)
                                  .clamp(0.0, 1.0);
                          _controller.value = newValue;
                        }
                      }
                    },
                    onPanEnd: (details) {
                      _isSliding = false;
                      // Snap to open or closed based on velocity and position
                      if (details.velocity.pixelsPerSecond.dx < -500 ||
                          _controller.value > 0.5) {
                        _controller.forward();
                      } else {
                        _controller.reverse();
                      }
                    },
                    onTap: () {
                      if (_controller.value > 0) {
                        // If swiped, close the actions
                        _controller.reverse();
                      } else {
                        // Normal tap behavior
                        widget.onTap();
                      }
                    },
                    child: _buildTransactionCard(theme, color, icon),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(ThemeData theme, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.all(0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surfaceContainer,
        ),
        child: ListTile(
          tileColor: theme.colorScheme.surfaceContainer,
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color),
          ),
          title: Text(
            widget.transaction.category,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            DateFormat('MMM dd, yyyy').format(widget.transaction.date),
            style: TextStyle(fontSize: 12),
          ),
          trailing: Text(
            NumberFormat.currency(
              symbol: '৳ ',
            ).format(widget.transaction.amount),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(ThemeData theme, double buttonWidth) {
    List<Widget> actions = [];

    if (widget.onEdit != null && widget.showEditButton) {
      actions.add(
        Container(
          width: buttonWidth,
          color: theme.colorScheme.primary,
          child: InkWell(
            onTap: () {
              _controller.reverse();
              widget.onEdit!();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, color: theme.colorScheme.onPrimary, size: 24),
                const SizedBox(height: 4),
                Text(
                  'Edit',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.onDelete != null) {
      actions.add(
        Container(
          width: buttonWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            color: theme.colorScheme.error,
          ),
          child: InkWell(
            onTap: () {
              _controller.reverse();
              widget.onDelete!();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete, color: theme.colorScheme.onError, size: 24),
                const SizedBox(height: 4),
                Text(
                  'Delete',
                  style: TextStyle(
                    color: theme.colorScheme.onError,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return actions;
  }
}
