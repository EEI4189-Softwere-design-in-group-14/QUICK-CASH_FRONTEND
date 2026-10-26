
import 'package:flutter/material.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  static const Color primary = Color(0xFF087A3E);
  static const Color background = Color(0xFFF5FAF6);

  int selectedIndex = 0;

  void showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature - Coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text(
          'QuickCash Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => showComingSoon('Notifications'),
          ),
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: primary),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Welcome back, Manager!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Here is your loan management overview.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 22),

            // Dashboard statistics
            Row(
              children: [
                Expanded(
                  child: statisticCard(
                    'Total Borrowers',
                    '125',
                    Icons.people_outline,
                    const Color(0xFF087A3E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: statisticCard(
                    'Pending Loans',
                    '18',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: statisticCard(
                    'Active Loans',
                    '86',
                    Icons.account_balance_wallet_outlined,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: statisticCard(
                    'Total Disbursed',
                    'Rs. 2.5M',
                    Icons.payments_outlined,
                    primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            sectionTitle('Quick Actions'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: actionCard(
                    'Borrower Approvals',
                    Icons.person_add_alt_1,
                        () => showComingSoon('Borrower Approvals'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: actionCard(
                    'Loan Approvals',
                    Icons.fact_check_outlined,
                        () => showComingSoon('Loan Approvals'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: actionCard(
                    'Disbursements',
                    Icons.account_balance,
                        () => showComingSoon('Disbursements'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: actionCard(
                    'Reports',
                    Icons.bar_chart,
                        () => showComingSoon('Reports'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            sectionTitle('Recent Activities'),
            const SizedBox(height: 12),
            activityTile(
              'New Borrower Registered',
              'A new borrower is awaiting approval',
              Icons.person_add_outlined,
            ),
            activityTile(
              'Loan Application Submitted',
              'A new loan request has been received',
              Icons.description_outlined,
            ),
            activityTile(
              'Payment Received',
              'A loan installment was recorded',
              Icons.check_circle_outline,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            setState(() => selectedIndex = 0);
          } else {
            showComingSoon(
              ['Dashboard', 'Borrowers', 'Loans', 'Profile'][index],
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Borrowers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Loans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget statisticCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget actionCard(
      String title,
      IconData icon,
      VoidCallback onTap,
      ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 10,
          ),
          child: Column(
            children: [
              Icon(icon, color: primary, size: 30),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget activityTile(
      String title,
      String subtitle,
      IconData icon,
      ) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE3F3E8),
          child: Icon(icon, color: primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
      ),
    );
  }
}
