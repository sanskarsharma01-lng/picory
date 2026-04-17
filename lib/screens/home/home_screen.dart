import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/group_model.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/group_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../album/album_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static _HomeScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_HomeScreenState>();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<_GroupsTabState> _groupsTabKey = GlobalKey<_GroupsTabState>();

  void setTabIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _joinGroup(String groupCode) async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final token = profileProvider.token;

    try {
      final response = await http.post(
        Uri.parse('https://mandatorily-prettyish-darcel.ngrok-free.dev/api/user/group/join'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'barcode': groupCode}),
      );

      if (response.body.trim().startsWith('<!DOCTYPE html>')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Server Error: Received HTML instead of JSON. Please try again later.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (mounted) {
        if (response.statusCode == 200 && responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Joined group successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _groupsTabKey.currentState?.fetchGroups();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Failed to join group'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showJoinGroupOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Join a Group',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share moments with your close ones',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              _buildOptionTile(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan QR Code',
                subtitle: 'Join instantly using your camera',
                color: const Color(0xFF5E6CE4),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppConstants.qrScannerRoute).then((code) {
                    if (code != null && code is String) {
                      _joinGroup(code);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildOptionTile(
                icon: Icons.keyboard_rounded,
                title: 'Enter Group Code',
                subtitle: 'Manually type the 6-digit code',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(context);
                  _showCodeInputDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFF3F4F6), width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ),
    );
  }

  void _showCodeInputDialog() {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter Code',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Type the unique group code below',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    letterSpacing: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5E6CE4),
                  ),
                  decoration: InputDecoration(
                    hintText: '______',
                    hintStyle: TextStyle(
                      color: const Color(0xFFD1D5DB),
                      fontSize: 32,
                      letterSpacing: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  onChanged: (value) {
                    if (value.length == 6) {
                      _joinGroup(value.toUpperCase());
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (codeController.text.length == 6) {
                            _joinGroup(codeController.text.toUpperCase());
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E6CE4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Join Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _GroupsTab(
            key: _groupsTabKey,
            onJoinGroup: _showJoinGroupOptions,
          ),
          const AlbumScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    const double horizontalPadding = 24;
    final barWidth = screenWidth - (horizontalPadding * 2);
    final itemWidth = barWidth / 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 32),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5E6CE4).withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              left: (itemWidth * _currentIndex) + (itemWidth / 2) - 35,
              child: Container(
                width: 70,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF5E6CE4).withValues(alpha: 0.15),
                      const Color(0xFF5E6CE4).withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            Row(
              children: [
                _buildNavItem(0, Icons.grid_view_rounded, Icons.grid_view_outlined, 'Home'),
                _buildNavItem(1, Icons.collections_rounded, Icons.collections_outlined, 'Album'),
                _buildNavItem(2, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 400),
              scale: isSelected ? 1.2 : 1.0,
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? const Color(0xFF5E6CE4) : const Color(0xFF9CA3AF),
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isSelected ? 4 : 0,
              width: isSelected ? 4 : 0,
              decoration: const BoxDecoration(
                color: Color(0xFF5E6CE4),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupsTab extends StatefulWidget {
  final VoidCallback onJoinGroup;

  const _GroupsTab({
    super.key,
    required this.onJoinGroup,
  });

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
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (response.body.trim().startsWith('<!DOCTYPE html>')) {
          setState(() {
            _error = 'Server Error: Received HTML instead of JSON. Please check your ngrok tunnel or server status.';
            _isLoading = false;
          });
          return;
        }

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
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 80,
          title: const Text(
            'Groups',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
              letterSpacing: -1.2,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: GestureDetector(
                  onTap: widget.onJoinGroup,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5E6CE4), Color(0xFF818CF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5E6CE4).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Join',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: GroupListShimmer(),
            ),
          )
        else if (_error.isNotEmpty)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _error,
                      style: const TextStyle(
                        color: Color(0xFF1F2937), 
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _error = '';
                        });
                        fetchGroups();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_groups.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.group_add_rounded,
                          size: 80,
                          color: Color(0xFFD1D5DB),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Start Your Journey',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Create memories together by joining a group with your friends and family.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: widget.onJoinGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E6CE4),
                          foregroundColor: Colors.white,
                          elevation: 12,
                          shadowColor: const Color(0xFF5E6CE4).withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Join a Group',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: GroupCard(
                        group: _groups[index],
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppConstants.groupDetailRoute,
                            arguments: _groups[index],
                          );
                        },
                      ),
                    );
                  },
                  childCount: _groups.length,
                ),
              ),
            ),
      ],
    );
  }
}
