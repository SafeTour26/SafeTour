import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/emergency_contact.dart';
import '../../../data/repositories/emergency_repository.dart';
import '../../../data/repositories/profile_repository.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final EmergencyRepository _emergencyRepo = EmergencyRepository();
  final ProfileRepository _profileRepo = ProfileRepository();

  String _userId = '';
  String _userName = '';
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;

  // Verified Official Bengaluru Emergency Helplines
  final List<Map<String, dynamic>> _officialHelplines = const [
    {
      'number': '112',
      'title': 'Emergency Response (112)',
      'subtitle': 'Unified Police, Fire & Medical',
      'icon': Icons.local_police_rounded,
      'color': AppColors.error,
    },
    {
      'number': '1091',
      'title': "Women's Helpline (1091)",
      'subtitle': '24x7 Bengaluru City Police',
      'icon': Icons.shield_rounded,
      'color': AppColors.secondary,
    },
    {
      'number': '1090',
      'title': 'Anti-Harassment & Senior (1090)',
      'subtitle': 'City Police Special Cell',
      'icon': Icons.health_and_safety_rounded,
      'color': AppColors.tertiary,
    },
    {
      'number': '108',
      'title': 'Ambulance & Medical (108)',
      'subtitle': 'Karnataka State Health Service',
      'icon': Icons.medical_services_rounded,
      'color': AppColors.primary,
    },
    {
      'number': '1930',
      'title': 'Cyber Crime Helpline (1930)',
      'subtitle': 'Financial fraud & cyber threats',
      'icon': Icons.security_rounded,
      'color': AppColors.onSurfaceVariant,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _userId = await _profileRepo.getOrCreateUserId();
    _userName = await _profileRepo.getUserName();
    final contacts = await _emergencyRepo.getContacts(_userId);

    if (mounted) {
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    }
  }

  Future<void> _callNumber(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar('Could not launch dialer for $cleanNumber');
      }
    } catch (_) {
      _showSnackBar('Unable to open phone dialer');
    }
  }

  Future<void> _sendSms(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleanNumber,
      queryParameters: {
        'body': 'SafeTour Alert: I need assistance in Bengaluru.'
      },
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar('Could not launch SMS app');
      }
    } catch (_) {
      _showSnackBar('Unable to open SMS');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurface)),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAddContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String relationship = 'Family';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.outlineVariant),
              ),
              title:
                  Text('Add Trusted Contact', style: AppTypography.headlineSm),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        style: AppTypography.bodyMd,
                        decoration: const InputDecoration(
                          labelText: 'Contact Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneCtrl,
                        style: AppTypography.bodyMd,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '+91 98765 43210',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (v.trim().length < 8) {
                            return 'Enter valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: relationship,
                        dropdownColor: AppColors.surfaceContainerHigh,
                        style: AppTypography.bodyMd,
                        decoration: const InputDecoration(
                          labelText: 'Relationship',
                          prefixIcon: Icon(Icons.people_outline_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Family', child: Text('Family')),
                          DropdownMenuItem(
                              value: 'Parent', child: Text('Parent')),
                          DropdownMenuItem(
                              value: 'Spouse/Partner',
                              child: Text('Spouse / Partner')),
                          DropdownMenuItem(
                              value: 'Friend', child: Text('Friend')),
                          DropdownMenuItem(
                              value: 'Colleague',
                              child: Text('Colleague / Flatmate')),
                          DropdownMenuItem(
                              value: 'Local Host',
                              child: Text('Local Host / Guide')),
                          DropdownMenuItem(
                              value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => relationship = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(context);
                      final newContact = EmergencyContact(
                        userId: _userId,
                        name: nameCtrl.text.trim(),
                        phoneNumber: phoneCtrl.text.trim(),
                        relationship: relationship,
                      );

                      final created =
                          await _emergencyRepo.addContact(newContact);
                      if (created != null && mounted) {
                        setState(() {
                          _contacts.insert(0, created);
                        });
                        _showSnackBar(
                            'Added ${created.name} to trusted contacts');
                      }
                    }
                  },
                  child: const Text('Save Contact'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteContact(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        title: Text('Remove Contact?', style: AppTypography.headlineSm),
        content: Text(
          'Remove ${contact.name} from your trusted emergency contacts?',
          style: AppTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _emergencyRepo.deleteContact(contact.id!);
              setState(() {
                _contacts.removeWhere((c) =>
                    c.id == contact.id ||
                    (c.name == contact.name &&
                        c.phoneNumber == contact.phoneNumber));
              });
              _showSnackBar('Contact removed');
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _openEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        title: Text('Edit Traveler Profile', style: AppTypography.headlineSm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: AppTypography.bodyMd,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                await _profileRepo.saveUserName(newName);
                if (mounted) setState(() => _userName = newName);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Emergency Contacts',
          style: AppTypography.headlineSm.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded,
                color: AppColors.onSurface),
            tooltip: 'Edit Profile',
            onPressed: _openEditProfileDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerLow,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  // User Status Pill Card
                  _buildUserStatusBanner(),
                  const SizedBox(height: 24),

                  // Section 1: Bengaluru 24/7 Official Helplines
                  Row(
                    children: [
                      const Icon(Icons.local_phone_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Bengaluru 24x7 Helplines',
                        style: AppTypography.titleMd
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._officialHelplines
                      .map((helpline) => _buildHelplineTile(helpline)),

                  const SizedBox(height: 28),

                  // Section 2: Personal Trusted Contacts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Trusted Personal Contacts',
                            style: AppTypography.titleMd
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _openAddContactDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_contacts.isEmpty)
                    _buildEmptyContactsBanner()
                  else
                    ..._contacts
                        .map((contact) => _buildPersonalContactTile(contact)),
                ],
              ),
            ),
    );
  }

  Widget _buildUserStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: AppTypography.headlineSm.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quick 1-tap alerts will notify your trusted contacts with GPS location.',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineTile(Map<String, dynamic> helpline) {
    final String number = helpline['number'];
    final String title = helpline['title'];
    final String subtitle = helpline['subtitle'];
    final IconData icon = helpline['icon'];
    final Color color = helpline['color'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: AppTypography.labelLg.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        trailing: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color == AppColors.error
                ? AppColors.error
                : AppColors.surfaceContainerHigh,
            foregroundColor: color == AppColors.error
                ? AppColors.onError
                : AppColors.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100)),
            elevation: 0,
          ),
          onPressed: () => _callNumber(number),
          icon: const Icon(Icons.call_rounded, size: 16),
          label:
              Text(number, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildPersonalContactTile(EmergencyContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C',
              style: AppTypography.headlineSm.copyWith(
                fontSize: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                contact.name,
                style: AppTypography.labelLg.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (contact.relationship != null &&
                contact.relationship!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  contact.relationship!,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            contact.phoneNumber,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.sms_rounded,
                  color: AppColors.primary, size: 20),
              tooltip: 'Send SMS',
              onPressed: () => _sendSms(contact.phoneNumber),
            ),
            IconButton(
              icon: const Icon(Icons.call_rounded,
                  color: AppColors.secondary, size: 20),
              tooltip: 'Call',
              onPressed: () => _callNumber(contact.phoneNumber),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 20),
              tooltip: 'Remove',
              onPressed: () => _confirmDeleteContact(contact),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyContactsBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.group_add_rounded,
            color: AppColors.onSurfaceVariant,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No Trusted Contacts Yet',
            style: AppTypography.headlineSm.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Add local hosts, family, or flatmates. They will be alerted instantly when you press the SOS button.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openAddContactDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add First Contact'),
          ),
        ],
      ),
    );
  }
}
