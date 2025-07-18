import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:phcl_accounts/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:phcl_accounts/features/dashboard/presentation/widgets/date_range_selector.dart';
import 'package:phcl_accounts/features/dashboard/domain/entities/dashboard_data.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    _dateRange = DateTimeRange(start: firstDayOfMonth, end: now);
    _loadDashboardData();
  }

  void _loadDashboardData() {
    context.read<DashboardBloc>().add(
          LoadDashboardData(
            startDate: _dateRange?.start,
            endDate: _dateRange?.end,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DateRangeSelector(
                  initialRange: _dateRange,
                  onChanged: (range) {
                    setState(() => _dateRange = range);
                    _loadDashboardData();
                  },
                ),
                const SizedBox(height: 20),
                if (state is DashboardLoading)
                  const Center(child: CircularProgressIndicator()),
                if (state is DashboardError)
                  Center(child: Text(state.message)),
                if (state is DashboardLoaded) ...[
                  _buildSummaryCards(state.dashboardData),
                  const SizedBox(height: 20),
                  _buildIncomeExpenseChart(state.dashboardData),
                  const SizedBox(height: 20),
                  _buildCategoryDistributionChart(state.dashboardData),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget _buildSummaryCards(DashboardData data) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: _SummaryCard(
  //           title: 'Income',
  //           amount: data.totalIncome,
  //           color: Colors.green,
  //         ),
  //       ),
  //       const SizedBox(width: 10),
  //       Expanded(
  //         child: _SummaryCard(
  //           title: 'Expense',
  //           amount: data.totalExpense,
  //           color: Colors.red,
  //         ),
  //       ),
  //       const SizedBox(width: 10),
  //       Expanded(
  //         child: _SummaryCard(
  //           title: 'Balance',
  //           amount: data.netBalance,
  //           color: data.netBalance >= 0 ? Colors.blue : Colors.orange,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildSummaryCards(DashboardData data) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8.0,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Balance: ',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              Text(
                data.netBalance.toStringAsFixed(2), 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const Divider(
            thickness: 1,
            height: 24,
            color: Colors.grey,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total In (+):',
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
              Text(
                data.totalIncome.toStringAsFixed(2),
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Out (-):',
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              Text(
                data.totalExpense.toStringAsFixed(2),
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ],
          ),
          const Divider(
            thickness: 1,
            height: 24,
            color: Colors.grey,
          ),
          const Text('View Report', style: TextStyle(),)
        ],
        ),
    );
  }

  Widget _buildIncomeExpenseChart(DashboardData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Income vs Expense',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(),
                series: <CartesianSeries>[
                  LineSeries<TransactionChartData, DateTime>(
                    dataSource: data.incomeChartData,
                    xValueMapper: (data, _) => data.date,
                    yValueMapper: (data, _) => data.amount,
                    name: 'Income',
                    color: Colors.green,
                  ),
                  LineSeries<TransactionChartData, DateTime>(
                    dataSource: data.expenseChartData,
                    xValueMapper: (data, _) => data.date,
                    yValueMapper: (data, _) => data.amount,
                    name: 'Expense',
                    color: Colors.red,
                  ),
                ],
                tooltipBehavior: TooltipBehavior(enable: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDistributionChart(DashboardData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense by Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: SfCircularChart(
                series: <CircularSeries>[
                  PieSeries<CategoryChartData, String>(
                    dataSource: data.categoryDistribution,
                    xValueMapper: (data, _) => data.category,
                    yValueMapper: (data, _) => data.amount,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    enableTooltip: true,
                  ),
                ],
                legend: Legend(isVisible: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '৳${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}













// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';



// class DashboardPage extends StatelessWidget {
//   const DashboardPage({super.key});

//     @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<DocumentSnapshot>(  
//       stream: FirebaseFirestore.instance
//           .collection('users')
//           .doc(FirebaseAuth.instance.currentUser?.uid)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Scaffold(body: Center(child: CircularProgressIndicator()));
//         }

//         final userData = snapshot.data!.data() as Map<String, dynamic>;
//         final role = userData['role'] ?? 'user';

//         if (role == 'admin') {
//           return AdminDashboard(userData: userData);
//         } else {
//           return UserDashboard(userData: userData);
//         }
//       },
//     );
//   }
// }


// class AdminDashboard extends StatelessWidget {
//   final Map<String, dynamic> userData;
//   final int netBalance = 0;
//   final int totalIn = 0;
//   final int totalOut = 0;

//   const AdminDashboard({super.key, required this.userData});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('PHCL Account'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(child: Column(          
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16.0),
//               width: double.infinity,
//               decoration: BoxDecoration(
//               color: Colors.blue[100],
//               borderRadius: BorderRadius.circular(8.0),
//               ),
//               child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               spacing: 8.0,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Net Balance: ',
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
//                     ),
//                     Text(
//                       netBalance.toStringAsFixed(2), 
//                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
//                     ),
//                   ],
//                 ),
//                 const Divider(
//                   thickness: 1,
//                   height: 24,
//                   color: Colors.grey,
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Total In (+):',
//                       style: const TextStyle(fontSize: 16, color: Colors.green),
//                     ),
//                     Text(
//                       netBalance.toStringAsFixed(2), 
//                       style: const TextStyle(fontSize: 16, color: Colors.green),
//                     ),
//                   ],
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Total Out (-):',
//                       style: const TextStyle(fontSize: 16, color: Colors.red),
//                     ),
//                     Text(
//                       netBalance.toStringAsFixed(2), 
//                       style: const TextStyle(fontSize: 16, color: Colors.red),
//                     ),
//                   ],
//                 ),
//                 const Divider(
//                   thickness: 1,
//                   height: 24,
//                   color: Colors.grey,
//                 ),
//                 const Text('View Report', style: TextStyle(),)
//               ],
//               ),
//             ),
//           ],)
//         ),
//       )
//     );
//   }
// }



// class UserDashboard extends StatelessWidget {
//   final Map<String, dynamic> userData;

//   const UserDashboard({super.key, required this.userData});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Welcome ${userData['name']}'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text('User Dashboard', style: TextStyle(fontSize: 24)),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pushNamed(context, '/add-transaction');
//               },
//               child: const Text('Add Transaction'),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pushNamed(context, '/my-transactions');
//               },
//               child: const Text('View My Transactions'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }