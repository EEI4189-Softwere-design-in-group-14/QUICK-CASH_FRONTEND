import 'package:flutter/material.dart';

class BorrowerDashboardScreen extends StatefulWidget {
  const BorrowerDashboardScreen({super.key});

  @override
  State<BorrowerDashboardScreen> createState() =>
      _BorrowerDashboardScreenState();
}

class _BorrowerDashboardScreenState extends State<BorrowerDashboardScreen> {
  static const Color primary = Color(0xFF168B62);
  static const Color background = Color(0xFFF5FAF7);

  int _selectedIndex = 0;

  // Demo values for the UI. Replace with API data when borrower endpoints
  // are available.
  final String _borrowerName = 'Borrower';
  final String _activeLoan = 'Rs. 50,000';
  final String _nextPayment = 'Rs. 5,000';

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be available soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'QuickCash',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _showComingSoon('Notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person_outline, color: primary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Welcome back,',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 3),
            Text(
              '$_borrowerName!',
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Color(0xFF18372B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Here is your loan overview.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            _buildLoanHighlight(),
            const SizedBox(height: 22),
            _sectionTitle('My Overview'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'Active Loan',
                    value: _activeLoan,
                    icon: Icons.account_balance_wallet_outlined,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    title: 'Next Payment',
                    value: _nextPayment,
                    icon: Icons.payments_outlined,
                    color: const Color(0xFFDE8B20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('Quick Actions'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    title: 'Apply for Loan',
                    icon: Icons.add_card_rounded,
                    onTap: () => _showComingSoon('Loan application'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionCard(
                    title: 'Payment History',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => _showComingSoon('Payment history'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    title: 'My Guarantors',
                    icon: Icons.people_outline_rounded,
                    onTap: () => _showComingSoon('Guarantor details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionCard(
                    title: 'My Profile',
                    icon: Icons.person_outline_rounded,
                    onTap: () => _showComingSoon('Profile'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('Recent Activity'),
            const SizedBox(height: 10),
            _activityTile(
              icon: Icons.check_circle_outline,
              iconColor: primary,
              title: 'Account dashboard',
              subtitle: 'Your borrower dashboard is ready to use.',
              trailing: 'Today',
            ),
            _activityTile(
              icon: Icons.event_available_outlined,
              iconColor: Colors.orange,
              title: 'Next repayment',
              subtitle: 'Keep track of your upcoming installment.',
              trailing: 'Upcoming',
            ),
            const SizedBox(height: 12),
            const Text(
              'Demo information is displayed until live borrower data is connected.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index != 0) {
            _showComingSoon(
              const ['Home', 'My Loans', 'Payments', 'Profile'][index],
            );
            setState(() => _selectedIndex = 0);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'My Loans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildLoanHighlight() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF168B62), Color(0xFF0B6548)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white70),
              SizedBox(width: 8),
              Text(
                'CURRENT LOAN BALANCE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Rs. 35,000',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white30),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Loan status',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(height: 5),
                    Text('Active',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _showComingSoon('Loan details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('View details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: Color(0xFF18372B),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F0EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(height: 13),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: const BoxConstraints(minHeight: 105),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE8F0EB)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: primary, size: 29),
              const SizedBox(height: 9),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8F0EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: Text(
          trailing,
          style: const TextStyle(fontSize: 10, color: Colors.black45),
        ),
      ),
    );
  }
}
