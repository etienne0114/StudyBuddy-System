import 'package:flutter/material.dart' hide SizedBox;
import 'package:flutter/material.dart' as material show SizedBox;
import 'package:study_scheduler/constants/app_colors.dart';
import 'package:study_scheduler/services/auth_service.dart';
import 'package:study_scheduler/ui/screens/auth/login_screen.dart';

// Custom SizedBox to avoid ambiguous imports
class SizedBox extends material.SizedBox {
  const SizedBox({Key? key, double? width, double? height, Widget? child})
      : super(key: key, width: width, height: height, child: child);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _authService.isAuthenticated;
    final userData = _authService.userData;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withAlpha(0.2 as int),
                      child: Text(
                        isLoggedIn && userData != null && userData['name'] != null
                            ? userData['name'].substring(0, 1).toUpperCase()
                            : 'G',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // User name
                    Text(
                      isLoggedIn && userData != null && userData['name'] != null
                          ? userData['name']
                          : 'Guest User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // User email
                    Text(
                      isLoggedIn && userData != null && userData['email'] != null
                          ? userData['email']
                          : 'Not logged in',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Edit profile button
                    if (isLoggedIn)
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to edit profile screen
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: AppColors.primary,
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Sign In'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // App settings
            const Text(
              'App Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Settings list
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Dark mode
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Switch to dark theme'),
                    secondary: const Icon(Icons.dark_mode),
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                        // Apply theme change
                      });
                    },
                  ),
                  const Divider(),
                  
                  // Notifications
                  SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Enable activity reminders'),
                    secondary: const Icon(Icons.notifications),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                        // Toggle notifications
                      });
                    },
                  ),
                  const Divider(),
                  
                  // Language selector
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Language'),
                    subtitle: const Text('English'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Show language picker
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // App Info
            const Text(
              'App Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showAboutDialog();
                    },
                  ),
                  const Divider(),
                  
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to help screen
                    },
                  ),
                  const Divider(),
                  
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Show privacy policy
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Sign out button
            if (isLoggedIn)
              _CustomButton(
                label: 'Sign Out',
                icon: Icons.logout,
                onPressed: _signOut,
                isLoading: _isLoading,
                color: Colors.red,
              ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signOut();
      
      if (!mounted) return;
      
      // Navigate back to login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Study Scheduler',
        applicationVersion: 'v1.0.0',
        applicationIcon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(0.2 as int),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.calendar_today,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        children: const [
          SizedBox(height: 16),
          Text(
            'Study Scheduler is a comprehensive app designed to help students and teachers organize their study schedules with timely reminders and access to study materials.',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 16),
          Text(
            '© 2025 Study Scheduler Team. All rights reserved.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;
  final IconData? icon;

  const _CustomButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon ?? Icons.check),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}