import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangeSelector extends StatefulWidget {
  final DateTimeRange? initialRange;
  final ValueChanged<DateTimeRange> onChanged;
  final List<String>? presetLabels;

  const DateRangeSelector({
    super.key,
    this.initialRange,
    required this.onChanged,
    this.presetLabels,
  });

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  late DateTimeRange _currentRange;
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentRange = widget.initialRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
  }

  @override
  Widget build(BuildContext context) {
    final presets = widget.presetLabels ?? _defaultPresets;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom date range selector
        _CustomRangeSelector(
          range: _currentRange,
          onStartDatePressed: () => _selectDate(true),
            onEndDatePressed: () => _selectDate(false),
            onRangePressed: _selectRange,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Preset buttons
              ...presets.map((label) {
                return _PresetButton(
                    label: label,
                    onPressed: () => _handlePresetSelection(label, now),
                    selected: _selectedPreset == label,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _handlePresetSelection(String label, DateTime now) {
    setState(() => _selectedPreset = label);
    
    DateTimeRange newRange;
    
    switch (label) {
      case 'Today':
        newRange = DateTimeRange(start: now, end: now);
        break;
      case 'This Week':
        newRange = DateTimeRange(
          start: now.subtract(Duration(days: now.weekday - 1)),
          end: now,
        );
        break;
      case 'This Month':
        newRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
        break;
      case 'Last 3 Months':
        newRange = DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: now,
        );
        break;
      case 'Last 6 Months':
        newRange = DateTimeRange(
          start: DateTime(now.year, now.month - 5, 1),
          end: now,
        );
        break;
      case 'This Year':
        newRange = DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
        break;
      default:
        return;
    }

    _updateRange(newRange);
    setState(() => _selectedPreset = label);
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _currentRange.start : _currentRange.end,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      final newRange = isStart
          ? DateTimeRange(start: picked, end: _currentRange.end)
          : DateTimeRange(start: _currentRange.start, end: DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999));
      _updateRange(newRange);
    }
  }

  Future<void> _selectRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _currentRange,
    );

    if (picked != null && mounted) {
      final adjustedRange = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59, 999),
      );
      _updateRange(adjustedRange);
    }
  }

  void _updateRange(DateTimeRange newRange) {
    setState(() {
      _currentRange = newRange;
      _selectedPreset = null; // Clear preset selection when using custom range
    });
    widget.onChanged(newRange);
  }

  static const _defaultPresets = [
    // 'Today',
    'This Week',
    'This Month',
    // 'Last 3 Months',
    'Last 6 Months',
    'This Year',
  ];
}

class _PresetButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _PresetButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onPressed(),
        labelStyle: TextStyle(
          fontSize: 12,
          color: selected 
              ? Theme.of(context).colorScheme.onPrimary 
              : Theme.of(context).textTheme.bodyMedium?.color,
        ),
        selectedColor: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        showCheckmark: false,
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

class _CustomRangeSelector extends StatelessWidget {
  final DateTimeRange range;
  final VoidCallback onStartDatePressed;
  final VoidCallback onEndDatePressed;
  final VoidCallback onRangePressed;

  const _CustomRangeSelector({
    required this.range,
    required this.onStartDatePressed,
    required this.onEndDatePressed,
    required this.onRangePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 18),
            onPressed: onRangePressed,
            tooltip: 'Select date range',
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          const VerticalDivider(width: 1),
          TextButton(
            onPressed: onStartDatePressed,
            child: Text(
              DateFormat('MMM d, y').format(range.start),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const Text('to', style: TextStyle(fontSize: 12)),
          TextButton(
            onPressed: onEndDatePressed,
            child: Text(
              DateFormat('MMM d, y').format(range.end),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}