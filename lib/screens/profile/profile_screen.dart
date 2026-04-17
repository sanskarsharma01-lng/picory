import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/shimmer_loading.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const String imageBaseUrl = 'https://mandatorily-prettyish-darcel.ngrok-free.dev/storage/';

    if (profileProvider.isLoading) {
      return const ProfileShimmer();
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF5E6CE4),
            elevation: 0,
            leading: const SizedBox.shrink(),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF5E6CE4), Color(0xFF818CF8)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -40,
                    left: -40,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: const Color(0xFFE5E7EB),
                              backgroundImage: profileProvider.faceImage != null 
                                ? NetworkImage('$imageBaseUrl${profileProvider.faceImage}')
                                : null,
                              child: profileProvider.faceImage == null 
                                ? const Icon(Icons.person_rounded, size: 60, color: Color(0xFF9CA3AF))
                                : null,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, AppConstants.editProfileRoute),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 18, color: Color(0xFF5E6CE4)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profileProvider.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          profileProvider.phoneNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
              ),
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Account Settings', isDark),
                      _buildMenuSection([
                        _buildMenuTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Edit Profile',
                          color: const Color(0xFF3B82F6),
                          isDark: isDark,
                          onTap: () => Navigator.pushNamed(context, AppConstants.editProfileRoute),
                        ),
                        _buildMenuTile(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          color: const Color(0xFFF59E0B),
                          isDark: isDark,
                          trailing: _buildSwitch(true, (v) {}),
                        ),
                        _buildMenuTile(
                          icon: themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          title: 'Theme Mode',
                          color: const Color(0xFF8B5CF6),
                          isDark: isDark,
                          trailing: _buildSwitch(themeProvider.isDarkMode, (v) => themeProvider.toggleTheme()),
                        ),
                        _buildMenuTile(
                          icon: Icons.language_rounded,
                          title: 'App Language',
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                          trailing: _buildLanguageDropdown(langProvider, isDark),
                        ),
                      ], isDark),
                      const SizedBox(height: 24),
                      _buildLabel('General', isDark),
                      _buildMenuSection([
                        _buildMenuTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          color: const Color(0xFF6366F1),
                          isDark: isDark,
                          onTap: () {},
                        ),
                        _buildMenuTile(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          color: const Color(0xFF6B7280),
                          isDark: isDark,
                          onTap: () => Navigator.pushNamed(context, AppConstants.termsRoute),
                        ),
                        _buildMenuTile(
                          icon: Icons.info_outline_rounded,
                          title: 'About Picory',
                          color: const Color(0xFFEC4899),
                          isDark: isDark,
                          onTap: () => _showAboutDialog(context),
                        ),
                      ], isDark),
                      const SizedBox(height: 40),
                      _buildLogoutButton(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuSection(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF374151),
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.chevron_right_rounded,
        color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
      ),
    );
  }

  Widget _buildSwitch(bool value, Function(bool) onChanged) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF5E6CE4),
    );
  }

  Widget _buildLanguageDropdown(LanguageProvider langProvider, bool isDark) {
    return DropdownButton<String>(
      value: langProvider.languageCode,
      underline: const SizedBox(),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
      items: AppConstants.languages.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(
            entry.value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF374151),
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) langProvider.changeLanguage(value);
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          'Log Out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('About Picory', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            Text('Picory is a smart photo sharing platform designed for group events and seamless memories management.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF5E6CE4), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out from Picory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await Provider.of<ProfileProvider>(context, listen: false).logout();
              if (success && mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppConstants.loginRoute, (route) => false);
              }
            },
            child: const Text('Log Out', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
