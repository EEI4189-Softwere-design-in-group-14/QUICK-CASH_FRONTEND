
import 'package:flutter/material.dart';

class CollectorBorrowerSearchScreen extends StatefulWidget {
  const CollectorBorrowerSearchScreen({super.key});

  @override
  State<CollectorBorrowerSearchScreen> createState() =>
      _CollectorBorrowerSearchScreenState();
}

class _CollectorBorrowerSearchScreenState
    extends State<CollectorBorrowerSearchScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  static const Color primaryGreen = Color(0xFF087F5B);

  String _query = '';
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchBorrower() {
    final query = _searchController.text.trim();

    FocusScope.of(context).unfocus();

    if (query.length < 2) {
      setState(() {
        _error = 'Enter at least 2 characters to search.';
        _searched = false;
      });
      return;
    }

    setState(() {
      _query = query;
      _error = null;
      _searched = true;
    });
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _query = '';
      _error = null;
      _searched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Borrower Search',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: Color(0xFFE0F5EA),
                    child: Icon(
                      Icons.people_alt_outlined,
                      size: 38,
                      color: primaryGreen,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Find a Borrower',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Search borrowers using their name, '
                      'phone number or borrower code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 28),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Search Borrower',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          maxLength: 80,
                          onSubmitted: (_) => _searchBorrower(),
                          onChanged: (_) {
                            setState(() {
                              _error = null;
                              _searched = false;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Name / Phone / Code',
                            hintText: 'e.g. BRW-000014',
                            prefixIcon: const Icon(
                              Icons.search,
                            ),
                            suffixIcon: IconButton(
                              tooltip: 'Clear search',
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.clear),
                            ),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          onPressed: _searchBorrower,
                          icon: const Icon(Icons.search),
                          label: const Text(
                            'Search Borrower',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (_searched)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_outlined,
                            color: primaryGreen,
                            size: 42,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Search: $_query',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Search API is not connected yet. '
                                'Borrower results will appear here '
                                'after backend integration.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(26),
                      child: Column(
                        children: [
                          Icon(
                            Icons.manage_search,
                            size: 54,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Start Searching',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Enter borrower information above '
                                'to begin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 18),

                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: primaryGreen,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'After API integration, only approved '
                                'borrowers with active accounts '
                                'will appear in search results.',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
