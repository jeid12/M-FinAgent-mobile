import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'state/app_state.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/screens/chat_screen.dart';
import 'ui/screens/feed_screen.dart';
import 'ui/screens/profile_screen.dart';

class FinAgentApp extends StatefulWidget {
  const FinAgentApp({super.key, this.appState, this.autoInitialize = true});

  final AppState? appState;
  final bool autoInitialize;

  @override
  State<FinAgentApp> createState() => _FinAgentAppState();
}

class _FinAgentAppState extends State<FinAgentApp> {
  late final AppState _state;
  int _index = 0;
  bool _showingSmsDisclosure = false;

  @override
  void initState() {
    super.initState();
    _state = widget.appState ?? AppState();
    if (widget.autoInitialize) {
      _state.initialize();
    }
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

    if (_state.isAuthenticated && _state.smsDisclosureRequired && !_showingSmsDisclosure) {
      _showingSmsDisclosure = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSmsDisclosureDialog();
      });
    }

    setState(() {});
  }

  Future<void> _showSmsDisclosureDialog() async {
    if (!mounted) return;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Allow SMS Access for Automatic Finance Tracking'),
          content: const Text(
            'MFinAgent uses SMS access to detect your mobile-money and bank transaction messages and automatically build your spending feed, balances, and financial insights. We only use relevant financial SMS content for this app experience. You can turn this off anytime in Android settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (accepted == true) {
      await _state.acceptSmsDisclosureAndStart();
    } else {
      _state.dismissSmsDisclosureForNow();
    }
    _showingSmsDisclosure = false;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      FeedScreen(state: _state),
      ChatScreen(state: _state),
      ProfileScreen(state: _state),
    ];

    final isAuthenticated = _state.isAuthenticated;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'M-FinAgent',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF033B5A),
          secondary: Color(0xFFF77F00),
          surface: Color(0xFFF2F6F9),
        ),
        textTheme: GoogleFonts.soraTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF2F6F9),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 12,
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF033B5A), Color(0xFF0A5D7F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Image.asset('assets/logo.png'),
              ),
              const SizedBox(width: 10),
              const Text(
                'M-FinAgent',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        extendBodyBehindAppBar: false,
        body: Stack(
          children: [
            const _AtmosphereBackground(),
            SafeArea(
              child: isAuthenticated
                  ? Column(
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            child: pages[_index],
                          ),
                        ),
                      ],
                    )
                  : AuthScreen(state: _state),
            ),
          ],
        ),
        bottomNavigationBar: isAuthenticated
            ? Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: NavigationBar(
                    backgroundColor: Colors.white.withValues(alpha: 0.88),
                    selectedIndex: _index,
                    indicatorColor: const Color(0x332A9D8F),
                    onDestinationSelected: (value) => setState(() => _index = value),
                    destinations: const [
                      NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Feed'),
                      NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
                      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _AtmosphereBackground extends StatelessWidget {
  const _AtmosphereBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FCFF), Color(0xFFEAF2F8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1A0A5D7F),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x14F77F00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
