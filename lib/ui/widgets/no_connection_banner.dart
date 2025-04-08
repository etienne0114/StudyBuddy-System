import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_scheduler/services/connectivity_service.dart';

class NoConnectionBanner extends StatefulWidget {
  const NoConnectionBanner({Key? key}) : super(key: key);

  @override
  State<NoConnectionBanner> createState() => _NoConnectionBannerState();
}

class _NoConnectionBannerState extends State<NoConnectionBanner> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    
    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Height animation
    _heightAnimation = Tween<double>(begin: 0, end: 40.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );
    
    // Listen to connectivity changes
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    connectivityService.statusStream.listen(_onConnectivityChanged);
    
    // Check initial connection status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      connectivityService.checkConnectivity().then((isConnected) {
        _onConnectivityChanged(
          isConnected ? ConnectivityStatus.wifi : ConnectivityStatus.none
        );
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onConnectivityChanged(ConnectivityStatus status) {
    final isConnected = status == ConnectivityStatus.wifi || 
                        status == ConnectivityStatus.mobile;
    
    if (!isConnected && !_isVisible) {
      // Show banner when connection is lost
      setState(() {
        _isVisible = true;
      });
      _animationController.forward();
    } else if (isConnected && _isVisible) {
      // Hide banner when connection is restored
      _animationController.reverse().then((_) {
        setState(() {
          _isVisible = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          height: _heightAnimation.value,
          width: double.infinity,
          color: Colors.red.shade700,
          child: _isVisible
              ? const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.signal_wifi_off,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'No Internet Connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}