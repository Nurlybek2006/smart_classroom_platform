import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../services/hive_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/premium_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _offlineMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notif = HiveService.getSetting('notifications_enabled');
    final offline = HiveService.getSetting('offline_mode');
    setState(() {
      _notificationsEnabled = notif ?? true;
      _offlineMode = offline ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softGray,
      appBar: const PremiumAppBar(title: AppStrings.settings, showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          GlassCard(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Хабарламалар',
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    activeTrackColor: AppColors.accentBlue,
                    onChanged: (v) {
                      setState(() => _notificationsEnabled = v);
                      HiveService.saveSetting('notifications_enabled', v);
                    },
                  ),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.cloud_off_rounded,
                  title: 'Офлайн режим',
                  trailing: Switch.adaptive(
                    value: _offlineMode,
                    activeTrackColor: AppColors.accentBlue,
                    onChanged: (v) {
                      setState(() => _offlineMode = v);
                      HiveService.saveSetting('offline_mode', v);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Қолданба туралы',
                  trailing: Text(
                    'v1.0.0',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Кэшті тазалау',
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                  onTap: () async {
                    await HiveService.clearAll();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Кэш тазаланды')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
