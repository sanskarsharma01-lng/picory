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
    // Fetch profile data when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    const String imageBaseUrl = 'https://mandatorily-prettyish-darcel.ngrok-free.dev/storage/';

    if (profileProvider.isLoading) {
      return const ProfileShimmer();
    }

    return SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: profileProvider.faceImage != null 
                ? NetworkImage('$imageBaseUrl${profileProvider.faceImage}')
                : null,
              child: profileProvider.faceImage == null 
                ? const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  )
                : null,
            ),
            const SizedBox(height: 16),
            Text(
              profileProvider.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profileProvider.phoneNumber,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            _buildProfileSection(
              context,
              children: [
                _buildProfileTile(
                  context,
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () {
                    Navigator.pushNamed(context, AppConstants.editProfileRoute);
                  },
                ),
                _buildProfileTile(
                  context,
                  icon: Icons.photo_library_outlined,
                  title: 'My Photos',
                  trailing: const Text('156'),
                  onTap: () {},
                ),
                _buildProfileTile(
                  context,
                  icon: Icons.group_outlined,
                  title: 'My Groups',
                  trailing: const Text('5'),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProfileSection(
              context,
              children: [
                _buildProfileTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                ),
                _buildProfileTile(
                  context,
                  icon: Icons.language,
                  title: 'Language',
                  trailing: DropdownButton<String>(
                    value: langProvider.languageCode,
                    underline: const SizedBox(),
                    items: AppConstants.languages.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        langProvider.changeLanguage(value);
                      }
                    },
                  ),
                ),
                _buildProfileTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProfileSection(
              context,
              children: [
                _buildProfileTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {},
                ),
                _buildProfileTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
                _buildProfileTile(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Terms and Conditions',
                  onTap: () {
                    Navigator.pushNamed(context, AppConstants.termsRoute);
                  },
                ),
                _buildProfileTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProfileSection(
              context,
              children: [
                _buildProfileTile(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  titleColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
  }

  Widget _buildProfileSection(BuildContext context,
      {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProfileTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        Widget? trailing,
        VoidCallback? onTap,
        Color? titleColor,
        Color? iconColor,
      }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppConstants.appName),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Version: 1.0.0'),
              SizedBox(height: 8),
              Text('A photo sharing app for groups'),
              SizedBox(height: 8),
              Text('© 2024 Picory. All rights reserved.'),
            ],
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                
                final success = await Provider.of<ProfileProvider>(context, listen: false).logout();
                
                if (mounted) {
                  Navigator.pop(context); // Remove loading indicator
                  if (success) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppConstants.loginRoute,
                      (route) => false,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}