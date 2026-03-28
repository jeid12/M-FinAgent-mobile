import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB703), Color(0xFFFF7B00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.black,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Explorer',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      '+250788000001',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const ListTile(
          title: Text('Savings Goal'),
          subtitle: Text('Build emergency fund to 300,000 RWF'),
          leading: Icon(Icons.savings_outlined),
        ),
        const ListTile(
          title: Text('Risk Signal'),
          subtitle: Text('High airtime + transfers this week'),
          leading: Icon(Icons.warning_amber_rounded),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logout action placeholder')),
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}
