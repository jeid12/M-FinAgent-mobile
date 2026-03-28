import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'ui/screens/chat_screen.dart';
import 'ui/screens/feed_screen.dart';
import 'ui/screens/profile_screen.dart';

class FinAgentApp extends StatefulWidget {
  const FinAgentApp({super.key, this.appState});

  final AppState? appState;

  @override
  State<FinAgentApp> createState() => _FinAgentAppState();
}

class _FinAgentAppState extends State<FinAgentApp> {
  late final AppState _state;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _state = widget.appState ?? AppState();
    _state.initialize();
    _state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    if (widget.appState == null) {
      _state.dispose();
    }
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      FeedScreen(state: _state),
      ChatScreen(state: _state),
      const ProfileScreen(),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'M-FinAgent',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003049)),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        fontFamily: 'monospace',
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'M-FinAgent',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: Column(
          children: [
            _StatusBanner(state: _state),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: pages[_index],
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Feed'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final backendOnline = state.backendOnline;
    final smsLabel = state.smsPermissionLabel;

    final color = backendOnline ? const Color(0xFFDDF5E7) : const Color(0xFFFDE7E7);
    final textColor = backendOnline ? const Color(0xFF0B6B36) : const Color(0xFF8A1C1C);
    final backendLabel = backendOnline ? 'Online' : 'Offline';

    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Text(
        'Backend: $backendLabel   |   SMS Permission: $smsLabel',
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
