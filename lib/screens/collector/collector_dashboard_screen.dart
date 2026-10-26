import 'package:flutter/material.dart';

/// Collector-facing dashboard UI for QuickCash.
///
/// The borrower and collection values below are sample UI data. Replace them
/// with API-backed values when the collector endpoints are available.
class CollectorDashboardScreen extends StatefulWidget {
  const CollectorDashboardScreen({super.key});

  @override
  State<CollectorDashboardScreen> createState() =>
      _CollectorDashboardScreenState();
}

class _CollectorDashboardScreenState extends State<CollectorDashboardScreen> {
  static const Color primary = Color(0xFF087A3E);
  static const Color pageBackground = Color(0xFFF5FAF6);

  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  final List<_BorrowerItem> _borrowers = const [
    _BorrowerItem(
      name: 'Nimal Perera',
      loanId: 'QC-LOAN-1024',
      installment: 'Rs. 5,000',
      status: 'Due today',
      statusColor: Color(0xFFE58A00),
      initials: 'NP',
    ),
    _BorrowerItem(
      name: 'Sanduni Fernando',
      loanId: 'QC-LOAN-1018',
      installment: 'Rs. 3,500',
      status: 'Overdue',
      statusColor: Color(0xFFD64545),
      initials: 'SF',
    ),
    _BorrowerItem(
      name: 'Kasun Silva',
      loanId: 'QC-LOAN-1009',
      installment: 'Rs. 4,000',
      status: 'Upcoming',
      statusColor: Color(0xFF2878C8),
      initials: 'KS',
    ),
  ];

  List<_BorrowerItem> get _filteredBorrowers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _borrowers;
    return _borrowers
        .where((borrower) =>
            borrower.name.toLowerCase().contains(query) ||
            borrower.loanId.toLowerCase().contains(query))
        .toList();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be available soon.')),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QuickCash',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Field Collector',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _showComingSoon('Notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_outline, color: primary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            const Text(
              'Good day, Collector!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF17231C),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Here is your collection summary for today.',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _buildCollectionBanner(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: 'Assigned',
                    value: '24',
                    caption: 'Borrowers',
                    icon: Icons.people_alt_outlined,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    title: 'Collected',
                    value: 'Rs. 18,500',
                    caption: 'Today',
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF2878C8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    title: 'Due today',
                    value: '8',
                    caption: 'Installments',
                    icon: Icons.event_available_outlined,
                    color: const Color(0xFFE58A00),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    title: 'Overdue',
                    value: '3',
                    caption: 'Installments',
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFD64545),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionHeader(
              title: 'Quick actions',
              actionLabel: 'View all',
              onAction: () => _showComingSoon('All collector actions'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _quickAction(
                    icon: Icons.person_search_outlined,
                    label: 'Find borrower',
                    onTap: () => _showComingSoon('Find borrower'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickAction(
                    icon: Icons.add_card_outlined,
                    label: 'Record payment',
                    onTap: () => _showComingSoon('Record payment'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickAction(
                    icon: Icons.receipt_long_outlined,
                    label: 'Receipts',
                    onTap: () => _showComingSoon('Receipts'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionHeader(
              title: 'Assigned borrowers',
              actionLabel: 'See all',
              onAction: () => _showComingSoon('All assigned borrowers'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name or loan ID',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_filteredBorrowers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No borrowers match your search.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else
              ..._filteredBorrowers.map(_borrowerCard),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4EC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dashboard figures and borrower details are sample data '
                      'until the collector API is connected.',
                      style: TextStyle(
                        color: Color(0xFF315541),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
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
            const destinations = [
              'Dashboard',
              'Borrowers',
              'Collections',
              'Profile',
            ];
            _showComingSoon(destinations[index]);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Borrowers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'Collections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF087A3E), Color(0xFF19A56A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's collection target",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 8),
                Text(
                  'Rs. 30,000',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Rs. 18,500 collected so far',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String caption,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: value.length > 8 ? 17 : 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, color: primary, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _borrowerCard(_BorrowerItem borrower) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE8EEE9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE5F3E9),
          child: Text(
            borrower.initials,
            style: const TextStyle(
              color: primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          borrower.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(borrower.loanId),
              const SizedBox(height: 4),
              Text(
                'Installment: ${borrower.installment}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: borrower.statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                borrower.status,
                style: TextStyle(
                  color: borrower.statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
        onTap: () => _showComingSoon('Borrower details'),
      ),
    );
  }
}

class _BorrowerItem {
  const _BorrowerItem({
    required this.name,
    required this.loanId,
    required this.installment,
    required this.status,
    required this.statusColor,
    required this.initials,
  });

  final String name;
  final String loanId;
  final String installment;
  final String status;
  final Color statusColor;
  final String initials;
}
