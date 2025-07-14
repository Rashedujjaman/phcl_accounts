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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
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
        ],
      ),
    );
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
          : DateTimeRange(start: currentRange.start, end: DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999));
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
      final adjustedRange = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999),
      );
      onChanged(adjustedRange);
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