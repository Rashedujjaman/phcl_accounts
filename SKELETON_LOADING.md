# Skeleton Loading System

This project uses a modern skeleton loading system with shimmer effects to provide a better user experience during data loading.

## Core Components

### Base Skeleton Widgets (`core/widgets/skeleton_widgets.dart`)

#### `SkeletonWidget`
Base skeleton widget with shimmer effect.
```dart
SkeletonWidget(
  width: 100,
  height: 20,
  borderRadius: BorderRadius.circular(8),
)
```

#### `SkeletonText`
For text placeholders with multiple lines support.
```dart
SkeletonText(
  width: 150,
  height: 16,
  lines: 2,
  spacing: 8,
)
```

#### `SkeletonCircle`
For circular elements like avatars or icons.
```dart
SkeletonCircle(size: 64)
```

#### `SkeletonCard`
Container for skeleton content with proper styling.
```dart
SkeletonCard(
  width: double.infinity,
  height: 120,
  child: YourSkeletonContent(),
)
```

## Dashboard Skeletons (`features/dashboard/presentation/widgets/dashboard_skeleton.dart`)

### Available Dashboard Skeletons:
- `SkeletonNetRevenueCard` - Main revenue card
- `SkeletonIncomeExpenseCard` - Income/expense cards
- `SkeletonFinancialOverviewCard` - Financial overview card
- `SkeletonChart` - Chart placeholders
- `SkeletonPieChart` - Pie chart placeholders
- `SkeletonDisplayModeIndicator` - Display mode indicator
- `SkeletonDateRangeSelector` - Date range selector
- `SkeletonDashboardSummary` - Complete dashboard summary

### Usage Example:
```dart
// In loading state
if (state is Loading) {
  return const SkeletonDashboardSummary();
}
```

## General App Skeletons (`core/widgets/app_skeletons.dart`)

### Available Skeletons:
- `SkeletonListItem` - For list items with optional leading/trailing
- `SkeletonTransactionItem` - Specific for transaction lists
- `SkeletonUserProfile` - User profile information
- `SkeletonFormField` - Form input fields
- `SkeletonButton` - Button placeholders
- `SkeletonNavigationTabs` - Navigation tab bars
- `SkeletonGridItem` - Grid item placeholders

### Usage Examples:

#### List with skeletons:
```dart
ListView.builder(
  itemCount: 5, // Show 5 skeleton items
  itemBuilder: (context, index) => const SkeletonTransactionItem(),
)
```

#### Form with skeletons:
```dart
Column(
  children: [
    const SkeletonFormField(hasLabel: true),
    const SizedBox(height: 16),
    const SkeletonFormField(hasLabel: true),
    const SizedBox(height: 24),
    const SkeletonButton(width: 200),
  ],
)
```

#### Grid with skeletons:
```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
  ),
  itemCount: 6,
  itemBuilder: (context, index) => const SkeletonGridItem(),
)
```

## Creating Custom Skeletons

### Step 1: Create the skeleton widget
```dart
class SkeletonMyComponent extends StatelessWidget {
  const SkeletonMyComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      height: 100,
      child: Row(
        children: [
          const SkeletonCircle(size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonText(height: 16),
                const SizedBox(height: 8),
                SkeletonText(width: 80, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Step 2: Use in your widget
```dart
Widget build(BuildContext context) {
  return BlocBuilder<MyBloc, MyState>(
    builder: (context, state) {
      if (state is MyLoadingState) {
        return ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) => const SkeletonMyComponent(),
        );
      }
      
      if (state is MyLoadedState) {
        return ListView.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) => MyActualComponent(state.items[index]),
        );
      }
      
      return const SizedBox();
    },
  );
}
```

## Best Practices

1. **Match the actual content structure** - Skeleton should closely resemble the real content layout
2. **Use appropriate sizes** - Keep skeleton sizes close to actual content
3. **Consistent spacing** - Maintain the same spacing as real content
4. **Limit skeleton count** - Show 3-5 skeleton items for lists to avoid performance issues
5. **Theme awareness** - Skeletons automatically adapt to light/dark themes

## Theme Customization

Skeletons automatically use theme-appropriate colors:
- **Light theme**: Grey[300] base, Grey[100] highlight
- **Dark theme**: Grey[800] base, Grey[700] highlight

You can customize colors by passing `baseColor` and `highlightColor` to `SkeletonWidget`:

```dart
SkeletonWidget(
  width: 100,
  height: 20,
  baseColor: Colors.blue[100],
  highlightColor: Colors.blue[50],
)
```
