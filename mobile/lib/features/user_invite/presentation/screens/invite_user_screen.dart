import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_center/l10n/generated/app_localizations.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../shared/theme/tokens.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../data/invite_repository.dart';

const List<String> _roleKeys = <String>[
  'parent',
  'teacher',
  'supervisor',
  'admin',
];

String _roleLabel(AppL10n l, String roleKey) {
  switch (roleKey) {
    case 'parent':
      return l.invRoleParent;
    case 'teacher':
      return l.invRoleTeacher;
    case 'supervisor':
      return l.invRoleSupervisor;
    case 'admin':
      return l.invRoleAdmin;
    default:
      return roleKey;
  }
}

/// شاشة الأدمن لدعوة مستخدم (بتنده Edge Function invite-user) + عرض رابط الدعوة.
class InviteUserScreen extends ConsumerStatefulWidget {
  const InviteUserScreen({super.key});

  @override
  ConsumerState<InviteUserScreen> createState() => _InviteUserScreenState();
}

class _InviteUserScreenState extends ConsumerState<InviteUserScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _name = TextEditingController();
  String _role = 'teacher';
  bool _busy = false;
  String? _link;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final String email = _email.text.trim();
    final String name = _name.text.trim();
    if (email.isEmpty || name.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _link = null;
    });
    try {
      final String? link = await ref
          .read(inviteRepositoryProvider)
          .inviteUser(email: email, fullName: name, role: _role);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _link = link;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      final AppL10n l = AppL10n.of(context);
      setState(() {
        _busy = false;
        _error = l.invSendError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return AppScaffold(
      title: l.invScreenTitle,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l.invNameLabel),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l.invEmailLabel),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l.invRoleLabel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: _roleKeys
                .map(
                  (String roleKey) => ChoiceChip(
                    label: Text(_roleLabel(l, roleKey)),
                    selected: _role == roleKey,
                    onSelected: (bool s) {
                      if (s) setState(() => _role = roleKey);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: _busy ? l.invSendingButton : l.invSendButton,
            icon: Icons.person_add,
            onPressed: _busy ? null : _invite,
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
          ],
          if (_link != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            _InviteLinkCard(link: _link!),
          ],
        ],
      ),
    );
  }
}

class _InviteLinkCard extends StatelessWidget {
  const _InviteLinkCard({required this.link});

  final String link;

  @override
  Widget build(BuildContext context) {
    final AppL10n l = AppL10n.of(context);
    return Card(
      color: AppColors.success.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l.invLinkReady,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(link, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l.invCopyLink,
              icon: Icons.copy,
              onPressed: () => Clipboard.setData(ClipboardData(text: link)),
            ),
          ],
        ),
      ),
    );
  }
}
