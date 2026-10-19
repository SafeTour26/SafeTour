import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/emergency_contact.dart';
import '../../../data/repositories/emergency_repository.dart';
import '../../../data/repositories/profile_repository.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final EmergencyRepository _emergencyRepo = EmergencyRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  final TextEditingController _searchController = TextEditingController();

  String _userId = '';
  List<EmergencyContact> _allContacts = [];
  List<EmergencyContact> _filteredContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _userId = await _profileRepo.getOrCreateUserId();
    final contacts = await _emergencyRepo.getContacts(_userId);

    if (mounted) {
      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    final clean = query.trim().toLowerCase();
    setState(() {
      if (clean.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        _filteredContacts = _allContacts.where((c) {
          return c.name.toLowerCase().contains(clean) ||
              c.phoneNumber.toLowerCase().contains(clean) ||
              c.contactEmail.toLowerCase().contains(clean);
        }).toList();
      }
    });
  }

  Future<void> _callNumber(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar('Could not launch phone dialer for $cleanNumber');
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
        'body': 'SafeTour Alert: Hello, checking in from Bengaluru.'
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

  void _openAddFriendDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.outlineVariant),
          ),
          title: Text('Add Friend to Circle', style: AppTypography.headlineSm),
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
                      labelText: 'Friend Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter name'
                        : null,
                  ),
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: emailCtrl,
                    style: AppTypography.bodyMd,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address (Optional)',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.onSecondary,
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext);
                  final newContact = EmergencyContact(
                    userId: _userId,
                    name: nameCtrl.text.trim(),
                    phoneNumber: phoneCtrl.text.trim(),
                    contactEmail: emailCtrl.text.trim(),
                  );

                  final created = await _emergencyRepo.addContact(newContact);
                  if (created != null && mounted) {
                    setState(() {
                      _allContacts.insert(0, created);
                      _filteredContacts = _allContacts;
                    });
                    _showSnackBar('Added ${created.name} to Trusted Circle');
                  }
                }
              },
              child: const Text('Add Friend'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteContact(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        title: Text('Remove Friend?', style: AppTypography.headlineSm),
        content: Text(
          'Remove ${contact.name} from your trusted safety circle?',
          style: AppTypography.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (contact.id != null) {
                await _emergencyRepo.deleteContact(contact.id!);
              }
              setState(() {
                _allContacts.removeWhere((c) =>
                    c.id == contact.id ||
                    (c.name == contact.name &&
                        c.phoneNumber == contact.phoneNumber));
                _filteredContacts = _allContacts;
              });
              _showSnackBar('Contact removed');
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceContainerLow,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                  children: [
                    // Header Area with SafeTour Brand
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.security_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Friends',
                          style: AppTypography.headlineMd.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title & Subtitle
                    Text(
                      'Friends & Trusted Circle',
                      style: AppTypography.headlineMd.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connect with trusted travel companions to share routes and stay coordinated on journeys.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search Friends Pill Input
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurface,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Search friends by name, phone or email...',
                                hintStyle: AppTypography.bodySm.copyWith(
                                  color: AppColors.outline,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                color: AppColors.onSurfaceVariant,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Heading: All Friends (N Contacts)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.groups_rounded,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'All Friends',
                              style: AppTypography.titleMd.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_filteredContacts.length} Contacts',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Contact Cards List (No relationship tag per user request)
                    if (_filteredContacts.isEmpty)
                      _buildEmptyState()
                    else
                      ..._filteredContacts
                          .map((contact) => _buildFriendCard(contact)),
                  ],
                ),
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: ElevatedButton.icon(
          onPressed: _openAddFriendDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.onSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            elevation: 8,
            shadowColor: AppColors.secondary.withValues(alpha: 0.4),
          ),
          icon: const Icon(Icons.person_add_rounded, size: 20),
          label: const Text(
            '+ Add Friend',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCard(EmergencyContact contact) {
    final initial =
        contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'F';
    final subtitleParts = <String>[];
    if (contact.phoneNumber.isNotEmpty) subtitleParts.add(contact.phoneNumber);
    if (contact.contactEmail.isNotEmpty) {
      subtitleParts.add(contact.contactEmail);
    }
    final subtitleText = subtitleParts.isNotEmpty
        ? subtitleParts.join(' • ')
        : 'Emergency safety contact';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Circular Avatar with Initials
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name & Details (Relationship tag removed per user request)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitleText,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.outline,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 3-Dots Action Popup Menu
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
            color: AppColors.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.outlineVariant),
            ),
            onSelected: (action) {
              if (action == 'call') {
                _callNumber(contact.phoneNumber);
              } else if (action == 'sms') {
                _sendSms(contact.phoneNumber);
              } else if (action == 'delete') {
                _confirmDeleteContact(contact);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'call',
                child: Row(
                  children: [
                    Icon(Icons.call_rounded,
                        color: AppColors.secondary, size: 18),
                    SizedBox(width: 10),
                    Text('Call Contact'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sms',
                child: Row(
                  children: [
                    Icon(Icons.sms_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 10),
                    Text('Send Message'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 18),
                    SizedBox(width: 10),
                    Text('Remove Friend'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
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
            Icons.person_search_rounded,
            color: AppColors.outline,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            'No Friends in Circle',
            style: AppTypography.headlineSm.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            'Add travel companions or emergency contacts. They will be alerted if you ever trigger SOS.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
