import 'package:deck_note/providers/auth_provider.dart';
import 'package:deck_note/providers/todo_provider.dart';
import 'package:deck_note/screens/login_screen.dart';
import 'package:deck_note/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  /// True when shown inside the wide layout's shell (no back button).
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _buildAppBar(context),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileHeader(context),
                    const SizedBox(height: 30),
                    _buildProfileInfo(context),
                    const SizedBox(height: 30),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    if (embedded) return content;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(child: content),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (!embedded) ...[
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
              icon: const FaIcon(
                FontAwesomeIcons.arrowLeft,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .slideY(begin: -0.2, end: 0);
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const FaIcon(
                FontAwesomeIcons.user,
                size: 60,
                color: Colors.white,
              ),
            ).animate()
              .scale(delay: 200.ms, duration: 600.ms),
            const SizedBox(height: 20),
            Text(
              authProvider.user?.name ?? 'User',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate()
              .fadeIn(delay: 300.ms),
            const SizedBox(height: 5),
            Text(
              authProvider.user?.userId ?? 'USER000000',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ).animate()
              .fadeIn(delay: 400.ms),
          ],
        );
      },
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return GlassmorphicContainer(
          width: double.infinity,
          height: 200,
          borderRadius: 20,
          blur: 20,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow(
                  FontAwesomeIcons.envelope,
                  'Email',
                  authProvider.user?.email ?? 'Not available',
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 20),
                _buildInfoRow(
                  FontAwesomeIcons.calendar,
                  'Member Since',
                  authProvider.user != null
                      ? '${authProvider.user!.createdAt.day}/${authProvider.user!.createdAt.month}/${authProvider.user!.createdAt.year}'
                      : 'Not available',
                ),
              ],
            ),
          ),
        ).animate()
          .fadeIn(delay: 500.ms)
          .slideY(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildInfoRow(FaIconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FaIcon(
            icon,
            size: 20,
            color: AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          context,
          'Edit Profile',
          FontAwesomeIcons.penToSquare,
          AppTheme.primaryColor,
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ProfileEditScreen(),
              ),
            );
          },
        ).animate()
          .fadeIn(delay: 600.ms)
          .slideX(begin: -0.2, end: 0),
        const SizedBox(height: 15),
        _buildActionButton(
          context,
          'Logout',
          FontAwesomeIcons.rightFromBracket,
          AppTheme.accentColor,
          () async {
            final authProvider = context.read<AuthProvider>();
            final todoProvider = context.read<TodoProvider>();
            await authProvider.signOut();
            todoProvider.reset();
            
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                (route) => false,
              );
            }
          },
        ).animate()
          .fadeIn(delay: 700.ms)
          .slideX(begin: -0.2, end: 0),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    FaIconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 60,
        borderRadius: 15,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.5),
            color.withValues(alpha: 0.2),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}