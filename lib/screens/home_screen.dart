
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'login_screen.dart';

import 'collector_dashboard_section.dart';
import 'manager_dashboard_section.dart';
import 'borrower_dashboard_section.dart';

class HomeScreen extends StatefulWidget {
  final UserSession session;

  const HomeScreen({
    super.key,
    required this.session,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<dynamic> _dashboard;

  String? get _dashboardPath => switch (widget.session.role) {
    'MANAGER' || 'OWNER' => '/manager/dashboard',
    'BORROWER' => '/borrower/dashboard',
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    _dashboard = _fetchDashboard();
  }

  Future<dynamic> _fetchDashboard() async {
    if (_dashboardPath == null) return null;

    final api = ApiClient();

    try {
      return await api.request(
        'GET',
        _dashboardPath!,
        token: widget.session.token,
      );
    } finally {
      api.close();
    }
  }

  void _refresh() {
    setState(() {
      _dashboard = _fetchDashboard();
    });
  }

  Future<void> _refreshDashboard() async {
    _refresh();

    try {
      await _dashboard;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.session.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QuickCash',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Hello, ${widget.session.name}',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(
              '$role • ${widget.session.email}',
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 25),

            if (role == 'COLLECTOR')
              CollectorDashboardSection(
                token: widget.session.token,
              )
            else if (_dashboardPath == null)
              const Text('Unsupported account role.')
            else
              FutureBuilder<dynamic>(
                future: _dashboard,
                builder: (context, snapshot) {
                  if (snapshot.connectionState !=
                      ConnectionState.done) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(35),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dashboard could not be loaded',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('${snapshot.error}'),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _refresh,
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data;

                  if (data is! Map<String, dynamic>) {
                    return const Text(
                      'Unexpected dashboard response',
                    );
                  }

                  if (role == 'BORROWER') {
                    return BorrowerDashboardSection(
                      token: widget.session.token,
                      data: data,
                      onRefresh: _refresh,
                    );
                  }

                  return ManagerDashboardSection(
                    canReconcile: role == 'MANAGER',
                    token: widget.session.token,
                    data: data,
                    onRefresh: _refresh,

                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
