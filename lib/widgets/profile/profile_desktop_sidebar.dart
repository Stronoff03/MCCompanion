import 'package:flutter/material.dart';
import '../../design/design.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../screens/public_profile_screen.dart';
import 'profile_common.dart';

class ProfileDesktopSidebar extends StatelessWidget {
  final UserModel? me;
  final VoidCallback onAddFriend;
  final VoidCallback? onGoToHome;
  final VoidCallback? onGoToConnector;
  final VoidCallback? onGoToSkins;
  final Widget? nav;

  const ProfileDesktopSidebar({
    super.key,
    required this.me,
    required this.onAddFriend,
    this.onGoToHome,
    this.onGoToConnector,
    this.onGoToSkins,
    this.nav,
  });

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserSearchScreen(
          onGoToHome: onGoToHome,
          onGoToConnector: onGoToConnector,
          onGoToSkins: onGoToSkins,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(height: 2, color: AppTheme.accent.withValues(alpha: 0.60)),
          const SizedBox(height: 24),
          ProfileAvatar(
            initials: me?.initials ?? '?',
            size: 90,
            avatarUrl: me?.avatarUrl,
          ),
          const SizedBox(height: 16),
          Text(
            me?.displayLabel ?? '—',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (me?.username != null) ...[
            const SizedBox(height: 4),
            Text(
              '@${me!.username}',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
          if (me?.bio?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              me!.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Divider(color: AppTheme.borderGray),
          const SizedBox(height: 12),
          DsButton(
            label: l.findUser,
            icon: Icons.search_rounded,
            tone: DsButtonTone.neutral,
            size: DsButtonSize.small,
            expand: true,
            onPressed: () => _openSearch(context),
          ),
          const SizedBox(height: 8),
          DsButton(
            label: l.addFriend,
            icon: Icons.person_add_rounded,
            tone: DsButtonTone.accent,
            size: DsButtonSize.small,
            expand: true,
            onPressed: onAddFriend,
          ),
          if (nav != null) ...[
            const SizedBox(height: 12),
            Divider(color: AppTheme.borderGray),
            const SizedBox(height: 12),
            nav!,
          ],
        ],
      ),
    );
  }
}
