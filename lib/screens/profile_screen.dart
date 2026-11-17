import 'package:material_ui/material_ui.dart';
import '../core/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          // Avatar + name
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.cardBorderRadius,
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      color: AppColors.accent, size: 28),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SmartGrow User',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Tugas Akhir · Praktikum IoT',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // App info
          _SectionLabel('About the App'),
          _InfoCard(children: [
            _InfoRow(label: 'App', value: 'SmartGrow'),
            _InfoRow(
                label: 'Full title',
                value:
                    'Monitoring Kelembapan Tanah dan Penyiraman Otomatis'),
            _InfoRow(label: 'Version', value: '1.0.0'),
          ]),

          const SizedBox(height: AppSpacing.base),

          // Tech stack
          _SectionLabel('Tech Stack'),
          _InfoCard(children: [
            _InfoRow(label: 'Mobile', value: 'Flutter 3.x (Dart)'),
            _InfoRow(label: 'Backend', value: 'Node.js + Express on Vercel'),
            _InfoRow(label: 'Database', value: 'Neon (PostgreSQL)'),
            _InfoRow(label: 'Hardware', value: 'ESP32 DevKit V1'),
            _InfoRow(label: 'Sensor', value: 'Capacitive moisture v1.2 + DHT22'),
            _InfoRow(label: 'Actuator', value: '5V relay + mini submersible pump'),
          ]),

          const SizedBox(height: AppSpacing.base),

          // API info
          _SectionLabel('API'),
          _InfoCard(children: [
            _InfoRow(label: 'Base URL', value: 'ta-iot.vercel.app/api'),
            _InfoRow(label: 'Protocol', value: 'HTTPS REST'),
            _InfoRow(label: 'Poll interval', value: 'Every 5 seconds'),
          ]),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          bottom: AppSpacing.sm, left: 2),
      child: Text(text, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 15)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBorderRadius,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: List.generate(children.length, (i) {
          return Column(
            children: [
              children[i],
              if (i < children.length - 1)
                const Divider(height: 1, indent: AppSpacing.base),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
