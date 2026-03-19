import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/group_model.dart';
import '../../providers/language_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/group_card.dart';
import '../album/album_screen.dart';
import '../profile/profile_screen.dart';
import '../group/qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  final GlobalKey<_GroupsTabState> _groupsTabKey = GlobalKey<_GroupsTabState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup(String barcode) async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final token = profileProvider.token;

    try {
      final response = await http.post(
        Uri.parse('https://mandatorily-prettyish-darcel.ngrok-free.dev/api/user/group/join'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'barcode': barcode}),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (mounted) {
        if (response.statusCode == 200 && responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['data']['message'] ?? 'Joined successfully')),
          );
          // Refresh group list
          _groupsTabKey.currentState?.fetchGroups();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Failed to join group')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showJoinGroupBottomSheet() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                langProvider.translate('join_group'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: Text(langProvider.translate('join_via_qr')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final String? code = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QrScannerScreen()),
                  );
                  if (code != null) {
                    _joinGroup(code);
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.code),
                title: Text(langProvider.translate('join_via_code')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCodeInput();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showCodeInput() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Group Code'),
          content: TextField(
            controller: codeController,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Enter 6-digit Code',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (codeController.text.length == 6) {
                  Navigator.pop(context);
                  _joinGroup(codeController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a 6-digit code')),
                  );
                }
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(_currentIndex == 0
            ? AppConstants.appName
            : _currentIndex == 1
                ? langProvider.translate('album')
                : langProvider.translate('profile')),
        actions: [
          if (_currentIndex == 0)
            TextButton.icon(
              onPressed: _showJoinGroupBottomSheet,
              icon: const Icon(Icons.add),
              label: Text(langProvider.translate('join_group')),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _GroupsTab(key: _groupsTabKey),
          const AlbumScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: langProvider.translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.photo_album),
            label: langProvider.translate('album'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: langProvider.translate('profile'),
          ),
        ],
      ),
    );
  }
}

class _GroupsTab extends StatefulWidget {
  const _GroupsTab({super.key});

  @override
  State<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<_GroupsTab> {
  List<GroupModel> _groups = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final token = profileProvider.token;

    try {
      final response = await http.get(
        Uri.parse('https://mandatorily-prettyish-darcel.ngrok-free.dev/api/user/groups'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> groupsData = responseData['data'];
          setState(() {
            _groups = groupsData.map((g) => GroupModel.fromMap(g)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = responseData['message'] ?? 'Failed to load groups';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load groups: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = '';
                });
                fetchGroups();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _groups.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_off,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No groups yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: fetchGroups,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                return GroupCard(
                  group: _groups[index],
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppConstants.groupDetailRoute,
                      arguments: _groups[index],
                    );
                  },
                );
              },
            ),
          );
  }
}
