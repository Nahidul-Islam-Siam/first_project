import 'package:flutter/material.dart';

import 'package:first_project/features/admin/services/admin_role_service.dart';
import 'package:first_project/features/announcements/models/announcement_item.dart';
import 'package:first_project/features/announcements/services/announcement_service.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AnnouncementService _announcementService = AnnouncementService.instance;

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openEditor({AnnouncementItem? existing}) async {
    final titleBnController = TextEditingController(text: existing?.titleBn);
    final messageBnController = TextEditingController(
      text: existing?.messageBn,
    );
    final titleEnController = TextEditingController(text: existing?.titleEn);
    final messageEnController = TextEditingController(
      text: existing?.messageEn,
    );
    final posterUrlController = TextEditingController(
      text: existing?.posterUrl,
    );

    var active = existing?.active ?? true;
    var showModal = existing?.showModal ?? true;
    var sendPush = existing?.sendPush ?? false;
    var startAt = existing?.startAt;
    var endAt = existing?.endAt;
    var submitting = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              final hasTitle =
                  titleBnController.text.trim().isNotEmpty ||
                  titleEnController.text.trim().isNotEmpty;
              final hasMessage =
                  messageBnController.text.trim().isNotEmpty ||
                  messageEnController.text.trim().isNotEmpty;

              if (!hasTitle) {
                _showMessage('Add at least one title (Bangla or English).');
                return;
              }
              if (!hasMessage) {
                _showMessage('Add at least one message (Bangla or English).');
                return;
              }
              if (startAt != null &&
                  endAt != null &&
                  endAt!.isBefore(startAt!)) {
                _showMessage('End time cannot be earlier than start time.');
                return;
              }

              setDialogState(() => submitting = true);
              try {
                await _announcementService.upsertAnnouncement(
                  id: existing?.id,
                  titleBn: titleBnController.text,
                  messageBn: messageBnController.text,
                  titleEn: titleEnController.text,
                  messageEn: messageEnController.text,
                  posterUrl: posterUrlController.text,
                  active: active,
                  showModal: showModal,
                  sendPush: sendPush,
                  startAt: startAt,
                  endAt: endAt,
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              } catch (e) {
                _showMessage('Failed to save announcement: $e');
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => submitting = false);
                }
              }
            }

            final title = existing == null
                ? 'Create Announcement'
                : 'Edit Announcement';

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleBnController,
                        decoration: const InputDecoration(
                          labelText: 'Title (Bangla)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: messageBnController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Message (Bangla)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: titleEnController,
                        decoration: const InputDecoration(
                          labelText: 'Title (English)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: messageEnController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Message (English)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: posterUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Poster URL (optional)',
                          hintText: 'https://...',
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        subtitle: const Text('Show in app list'),
                        value: active,
                        onChanged: (value) {
                          setDialogState(() => active = value);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show as modal'),
                        subtitle: const Text(
                          'Popup on home screen when active + live',
                        ),
                        value: showModal,
                        onChanged: (value) {
                          setDialogState(() => showModal = value);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Send push notification'),
                        subtitle: const Text(
                          'Queue broadcast push to all users via topic',
                        ),
                        value: sendPush,
                        onChanged: (value) {
                          setDialogState(() => sendPush = value);
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await _pickDateTime(startAt);
                                if (picked == null) return;
                                setDialogState(() => startAt = picked);
                              },
                              icon: const Icon(Icons.schedule_rounded),
                              label: Text(
                                startAt == null
                                    ? 'Set start'
                                    : _formatDateTime(startAt),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Clear start',
                            onPressed: startAt == null
                                ? null
                                : () => setDialogState(() => startAt = null),
                            icon: const Icon(Icons.clear_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await _pickDateTime(endAt);
                                if (picked == null) return;
                                setDialogState(() => endAt = picked);
                              },
                              icon: const Icon(Icons.event_available_rounded),
                              label: Text(
                                endAt == null
                                    ? 'Set end'
                                    : _formatDateTime(endAt),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Clear end',
                            onPressed: endAt == null
                                ? null
                                : () => setDialogState(() => endAt = null),
                            icon: const Icon(Icons.clear_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleBnController.dispose();
    messageBnController.dispose();
    titleEnController.dispose();
    messageEnController.dispose();
    posterUrlController.dispose();

    if (saved == true) {
      _showMessage('Announcement saved.');
    }
  }

  Future<DateTime?> _pickDateTime(DateTime? initialValue) async {
    final now = DateTime.now();
    final initial = initialValue ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null) return null;

    if (!mounted) return null;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    final time = pickedTime ?? TimeOfDay.fromDateTime(initial);
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      time.hour,
      time.minute,
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Not set';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Future<void> _confirmDelete(AnnouncementItem item) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete announcement?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (sure != true) return;

    try {
      await _announcementService.deleteAnnouncement(item.id);
      _showMessage('Announcement deleted.');
    } catch (e) {
      _showMessage('Delete failed: $e');
    }
  }

  Widget _statusChip({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _pushStatusLabel(AnnouncementItem item) {
    final status = (item.pushStatus ?? '').trim().toLowerCase();
    if (status == 'sent') return 'Push Sent';
    if (status == 'pending') return 'Push Pending';
    if (status == 'processing') return 'Push Processing';
    if (status == 'failed') return 'Push Failed';
    if (item.sendPush) return 'Push Pending';
    return 'Push Off';
  }

  Widget _buildAnnouncementCard(BuildContext context, AnnouncementItem item) {
    final glass = NoorifyGlassTheme(context);
    final title = item.titleBn.isNotEmpty ? item.titleBn : item.titleEn;
    final message = item.messageBn.isNotEmpty ? item.messageBn : item.messageEn;
    final windowText =
        'Window: ${_formatDateTime(item.startAt)} -> '
        '${_formatDateTime(item.endAt)}';
    final pushLabel = _pushStatusLabel(item);
    final pushStatusLower = pushLabel.toLowerCase();
    final pushColor = pushStatusLower.contains('sent')
        ? const Color(0x2436D57A)
        : pushStatusLower.contains('failed')
        ? const Color(0x24E75F6D)
        : pushStatusLower.contains('pending') ||
              pushStatusLower.contains('processing')
        ? const Color(0x24FACC15)
        : const Color(0x24A0A8B1);
    final pushTextColor = pushStatusLower.contains('sent')
        ? const Color(0xFF3AD37E)
        : pushStatusLower.contains('failed')
        ? const Color(0xFFE77584)
        : pushStatusLower.contains('pending') ||
              pushStatusLower.contains('processing')
        ? const Color(0xFFF5D94E)
        : glass.textMuted;

    return NoorifyGlassCard(
      radius: BorderRadius.circular(16),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title.isEmpty ? '(Untitled)' : title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: glass.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    _statusChip(
                      label: item.active ? 'Active' : 'Inactive',
                      color: item.active
                          ? const Color(0x2436D57A)
                          : const Color(0x24A0A8B1),
                      textColor: item.active
                          ? const Color(0xFF3AD37E)
                          : glass.textMuted,
                    ),
                    _statusChip(
                      label: item.showModal ? 'Modal On' : 'Modal Off',
                      color: item.showModal
                          ? const Color(0x2438BDF8)
                          : const Color(0x24A0A8B1),
                      textColor: item.showModal
                          ? const Color(0xFF5BC8FF)
                          : glass.textMuted,
                    ),
                    _statusChip(
                      label: pushLabel,
                      color: pushColor,
                      textColor: pushTextColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: glass.textSecondary, fontSize: 12),
            ),
          ],
          if ((item.posterUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.image_outlined, size: 15, color: glass.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.posterUrl!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: glass.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            windowText,
            style: TextStyle(color: glass.textMuted, fontSize: 10.5),
          ),
          if ((item.pushError ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Push error: ${item.pushError}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE77584),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openEditor(existing: item),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await _announcementService.setActive(item.id, !item.active);
                    _showMessage(
                      item.active
                          ? 'Announcement disabled.'
                          : 'Announcement enabled.',
                    );
                  } catch (e) {
                    _showMessage('Status update failed: $e');
                  }
                },
                icon: const Icon(Icons.toggle_on_rounded, size: 16),
                label: Text(item.active ? 'Disable' : 'Enable'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await _announcementService.setShowModal(
                      item.id,
                      !item.showModal,
                    );
                    _showMessage(
                      item.showModal ? 'Modal turned off.' : 'Modal turned on.',
                    );
                  } catch (e) {
                    _showMessage('Modal status update failed: $e');
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(item.showModal ? 'Disable Modal' : 'Enable Modal'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await _announcementService.queuePush(item.id);
                    _showMessage('Push queued for broadcast.');
                  } catch (e) {
                    _showMessage('Queue push failed: $e');
                  }
                },
                icon: const Icon(Icons.campaign_outlined, size: 16),
                label: const Text('Queue Push'),
              ),
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(item),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE75F6D),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBody(BuildContext context) {
    return StreamBuilder<List<AnnouncementItem>>(
      stream: _announcementService.watchAnnouncements(limit: 120),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to load announcements.\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final announcements = snapshot.data ?? const <AnnouncementItem>[];
        if (announcements.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No announcements yet.\nTap "Add Announcement" to create one.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 90),
          itemBuilder: (context, index) {
            return _buildAnnouncementCard(context, announcements[index]);
          },
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemCount: announcements.length,
        );
      },
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: NoorifyGlassCard(
          radius: BorderRadius.circular(18),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 40,
                color: glass.accent,
              ),
              const SizedBox(height: 10),
              Text(
                'Admin access required',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: glass.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set your Firestore user role to "admin" in users/{uid}.',
                textAlign: TextAlign.center,
                style: TextStyle(color: glass.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return StreamBuilder<bool>(
      stream: AdminRoleService.instance.watchCurrentUserAdmin(),
      builder: (context, snapshot) {
        final checkingRole =
            snapshot.connectionState == ConnectionState.waiting;
        final isAdmin = snapshot.data ?? false;

        return Scaffold(
          backgroundColor: glass.bgBottom,
          floatingActionButton: isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Announcement'),
                )
              : null,
          body: NoorifyGlassBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: glass.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: checkingRole
                        ? const Center(child: CircularProgressIndicator())
                        : (isAdmin
                              ? _buildAdminBody(context)
                              : _buildAccessDenied(context)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
