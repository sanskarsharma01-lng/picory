import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/group_model.dart';
import '../../providers/language_provider.dart';
import '../../widgets/group_card.dart';
import '../album/album_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _GroupsTab(),
    const AlbumScreen(),
    const ProfileScreen(),
  ];

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
                onTap: () {
                  Navigator.pop(context);
                  _showQrScanner();
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

  void _showQrScanner() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('QR Code Scanner'),
          content: Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('QR Scanner Placeholder'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
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
          title: Text(langProvider.translate('enter_group_code')),
          content: TextField(
            controller: codeController,
            maxLength: 4,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'ABCD',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (codeController.text.length == 4) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Joining group: ${codeController.text}'),
                    ),
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: Provider.of<LanguageProvider>(context).translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.photo_album),
            label: Provider.of<LanguageProvider>(context).translate('album'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: Provider.of<LanguageProvider>(context).translate('profile'),
          ),
        ],
      ),
    );
  }
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final groups = GroupModel.getDummyGroups();

    return Scaffold(
      appBar: AppBar(
        title: Text(langProvider.translate('groups')),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              final homeState =
              context.findAncestorStateOfType<_HomeScreenState>();
              homeState?._showJoinGroupBottomSheet();
            },
            tooltip: langProvider.translate('join_group'),
          ),
        ],
      ),
      body: groups.isEmpty
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
            Text(
              'No groups yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return GroupCard(
            group: groups[index],
            onTap: () {
              Navigator.pushNamed(
                context,
                AppConstants.groupDetailRoute,
                arguments: groups[index],
              );
            },
          );
        },
      ),
    );
  }
}
