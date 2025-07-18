import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangeSelector extends StatelessWidget {
  final DateTimeRange? initialRange;
  final ValueChanged<DateTimeRange> onChanged;

  const DateRangeSelector({
    super.key,
    this.initialRange,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final range = initialRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    return Row(
      children: [
        Expanded(
          child: _DateButton(
            date: range.start,
            onPressed: () => _selectDate(context, true, range),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('to'),
        ),
        Expanded(
          child: _DateButton(
            date: range.end,
            onPressed: () => _selectDate(context, false, range),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectRange(context, range),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down),
          onSelected: (value) => _handlePresetSelection(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'today',
              child: Text('Today'),
            ),
            const PopupMenuItem(
              value: 'week',
              child: Text('This Week'),
            ),
            const PopupMenuItem(
              value: 'month',
              child: Text('This Month'),
            ),
            const PopupMenuItem(
              value: 'year',
              child: Text('This Year'),
            ),
            const PopupMenuItem(
              value: 'custom',
              child: Text('Custom Range'),
            ),
          ],
        ),
      ],
    );
  }

  void _handlePresetSelection(BuildContext context, String value) {
    final now = DateTime.now();
    DateTimeRange newRange;

    switch (value) {
      case 'today':
        newRange = DateTimeRange(start: now, end: now);
        break;
      case 'week':
        newRange = DateTimeRange(
          start: now.subtract(Duration(days: now.weekday - 1)),
          end: now,
        );
        break;
      case 'month':
        newRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
        break;
      case 'year':
        newRange = DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
        break;
      case 'custom':
        _selectRange(context, initialRange ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now));
        return;
      default:
        return;
    }

    onChanged(newRange);
  }

  Future<void> _selectDate(
    BuildContext context,
    bool isStart,
    DateTimeRange currentRange,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? currentRange.start : currentRange.end,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final newRange = isStart
          ? DateTimeRange(start: picked, end: currentRange.end)
          : DateTimeRange(start: currentRange.start, end: picked);
      onChanged(newRange);
    }
  }

  Future<void> _selectRange(BuildContext context, DateTimeRange currentRange) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: currentRange,
    );

    if (picked != null) {
      onChanged(picked);
    }
  }
}

class _DateButton extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPressed;

  const _DateButton({
    required this.date,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(DateFormat('MMM dd, yyyy').format(date)),
    );
  }
}