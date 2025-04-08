import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_scheduler/constants/app_colors.dart';
import 'package:study_scheduler/constants/app_constants.dart';
import 'package:study_scheduler/ui/screens/home/home_screen.dart' hide SizedBox;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _numPages = 3;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Study Scheduler',
      description: 'Organize your study time, keep track of your activities, and never miss a class again.',
      image: 'assets/images/onboarding_1.png',
      backgroundColor: AppColors.primary.withAlpha(0.1 as int),
    ),
    OnboardingPage(
      title: 'Create Your Schedule',
      description: 'Create custom schedules for different subjects or courses. Add activities with reminders.',
      image: 'assets/images/onboarding_2.png',
      backgroundColor: AppColors.success.withAlpha(0.1 as int),
    ),
    OnboardingPage(
      title: 'Access Study Materials',
      description: 'Find and access study materials right from the app. Prepare for your classes better.',
      image: 'assets/images/onboarding_3.png',
      backgroundColor: AppColors.info.withAlpha(0.1 as int),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _numPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefFirstLaunch, false);
    
    // Navigate to home screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _numPages,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _buildPage(page);
            },
          ),
          
          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _completeOnboarding,
              child: const Text('Skip'),
            ),
          ),
          
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicator
                  Row(
                    children: List.generate(_numPages, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? AppColors.primary
                              : Colors.grey.withAlpha(0.5 as int),
                        ),
                      );
                    }),
                  ),
                  
                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _currentPage == _numPages - 1 ? 'Get Started' : 'Next',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      color: page.backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // Placeholder for image
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(0.7 as int),
              borderRadius: BorderRadius.circular(20),
            ),
            child: page.image != null
                ? Image.asset(
                    page.image!,
                    fit: BoxFit.contain,
                  )
                : Center(
                    child: Icon(
                      _getIconForPage(_currentPage),
                      size: 120,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  page.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  page.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  IconData _getIconForPage(int page) {
    switch (page) {
      case 0:
        return Icons.schedule;
      case 1:
        return Icons.calendar_today;
      case 2:
        return Icons.library_books;
      default:
        return Icons.info;
    }
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String? image;
  final Color backgroundColor;

  OnboardingPage({
    required this.title,
    required this.description,
    this.image,
    this.backgroundColor = Colors.white,
  });
}