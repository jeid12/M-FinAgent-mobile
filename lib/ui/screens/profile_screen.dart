import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../models/user_profile.dart';
import '../../state/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _goalAmountCtrl = TextEditingController();

  DateTime? _goalTargetDate;
  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _syncFromProfile(widget.state.profile);
    widget.state.addListener(_onStateChanged);
    if (widget.state.profile == null) {
      widget.state.refreshProfile();
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _ageCtrl.dispose();
    _genderCtrl.dispose();
    _professionCtrl.dispose();
    _bioCtrl.dispose();
    _goalAmountCtrl.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;
    _syncFromProfile(widget.state.profile, onlyIfEmpty: true);
    setState(() {});
  }

  void _syncFromProfile(UserProfile? profile, {bool onlyIfEmpty = false}) {
    if (profile == null) return;

    if (!onlyIfEmpty || _nameCtrl.text.isEmpty) _nameCtrl.text = profile.fullName ?? '';
    if (!onlyIfEmpty || _phoneCtrl.text.isEmpty) _phoneCtrl.text = profile.phoneNumber ?? '';
    if (!onlyIfEmpty || _emailCtrl.text.isEmpty) _emailCtrl.text = profile.email ?? '';
    if (!onlyIfEmpty || _ageCtrl.text.isEmpty) _ageCtrl.text = profile.age?.toString() ?? '';
    if (!onlyIfEmpty || _genderCtrl.text.isEmpty) _genderCtrl.text = profile.gender ?? '';
    if (!onlyIfEmpty || _professionCtrl.text.isEmpty) {
      _professionCtrl.text = profile.profession ?? '';
    }
    if (!onlyIfEmpty || _bioCtrl.text.isEmpty) _bioCtrl.text = profile.bio ?? '';
    if (!onlyIfEmpty || _goalAmountCtrl.text.isEmpty) {
      _goalAmountCtrl.text = profile.goalAmountRwf?.toStringAsFixed(0) ?? '';
    }
    _goalTargetDate = profile.goalTargetDate ?? _goalTargetDate;
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _uploadingImage = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;
      await widget.state.uploadProfileImage(file.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _pickGoalDate() async {
    final initial = _goalTargetDate ?? DateTime.now().add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _goalTargetDate = picked);
    }
  }

  Future<void> _saveProfile() async {
    final current = widget.state.profile;
    if (current == null) return;

    final age = int.tryParse(_ageCtrl.text.trim());
    final goalAmount = double.tryParse(_goalAmountCtrl.text.trim().replaceAll(',', ''));
    final updated = current.copyWith(
      fullName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      age: age,
      gender: _genderCtrl.text.trim().isEmpty ? null : _genderCtrl.text.trim(),
      profession: _professionCtrl.text.trim().isEmpty ? null : _professionCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      goalAmountRwf: goalAmount,
      goalTargetDate: _goalTargetDate,
    );

    setState(() => _saving = true);
    try {
      await widget.state.saveProfile(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.state.profile;
    final userLabel = profile?.displayName ?? widget.state.activeIdentityLabel;
    final avatarUrl = profile?.profileImageUrl;
    final goalDateLabel = _goalTargetDate == null
        ? 'Choose target date'
        : DateFormat('yyyy-MM-dd').format(_goalTargetDate!);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF013A63), Color(0xFF0D5F83), Color(0xFF2A9D8F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x2A0A4D6A), blurRadius: 20, offset: Offset(0, 10)),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0x1FFFFFFF),
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Text(
                            userLabel.isNotEmpty ? userLabel[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: _uploadingImage ? null : _pickAndUploadImage,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _uploadingImage
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.photo_camera_rounded, size: 16, color: Color(0xFF0D5F83)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Financial Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userLabel,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile?.goalAmountRwf == null
                          ? 'Set your first money target below'
                          : 'Goal: ${profile!.goalAmountRwf!.toStringAsFixed(0)} RWF by ${profile.goalTargetDate?.toIso8601String().split('T').first ?? 'date not set'}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ProfileMetricCard(
                label: 'Weekly Net',
                value: '${widget.state.summary.netFlow.toStringAsFixed(0)} RWF',
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ProfileMetricCard(
                label: 'Top Spend',
                value: widget.state.summary.byCategory.isEmpty
                    ? 'N/A'
                    : widget.state.summary.byCategory.entries
                        .reduce((a, b) => a.value >= b.value ? a : b)
                        .key,
                icon: Icons.insights_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD9E6EF)),
          ),
          child: Column(
            children: [
              _InputField(label: 'Full Name', controller: _nameCtrl),
              _InputField(
                label: 'Phone Number',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                readOnly: true,
              ),
              _InputField(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
              _InputField(label: 'Age', controller: _ageCtrl, keyboardType: TextInputType.number),
              _InputField(label: 'Gender', controller: _genderCtrl),
              _InputField(label: 'Profession', controller: _professionCtrl),
              _InputField(label: 'Bio', controller: _bioCtrl, maxLines: 3),
              _InputField(
                label: 'Goal Amount (RWF)',
                controller: _goalAmountCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_rounded),
                title: const Text('Goal Target Date'),
                subtitle: Text(goalDateLabel),
                trailing: TextButton(
                  onPressed: _pickGoalDate,
                  child: const Text('Pick'),
                ),
              ),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: _saving || widget.state.profileLoading ? null : _saveProfile,
                icon: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving...' : 'Save Profile & Goal'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF8D1E1E),
            side: const BorderSide(color: Color(0xFFCC7777)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          onPressed: () async {
            await widget.state.logout();
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF7FAFD),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD9E6EF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD9E6EF)),
          ),
        ),
      ),
    );
  }
}

class _ProfileMetricCard extends StatelessWidget {
  const _ProfileMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E6EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Color(0xFF0A5D7F)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF4C5D6B))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
