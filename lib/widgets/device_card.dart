import 'package:material_ui/material_ui.dart';
import '../core/theme.dart';
import '../models/device.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;

  const DeviceCard({super.key, required this.device, this.onTap});

  @override
  Widget build(BuildContext context) {
    final moisture = device.soilMoisture;
    final pump = device.pumpOn ?? false;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorderRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            children: [
              // Soil level indicator bar
              _MoistureBar(
                moisture: moisture,
                dryThreshold: device.dryThreshold,
                wetThreshold: device.wetThreshold,
              ),
              const SizedBox(width: AppSpacing.md),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Online dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: device.isOnline ? Colors.green : AppColors.divider,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      device.plant.isNotEmpty ? device.plant : 'No plant set',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        // Mode pill
                        _Pill(
                          label: device.mode.toUpperCase(),
                          active: device.mode == 'auto',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Pump state
                        _Pill(
                          label: pump ? 'PUMP ON' : 'PUMP OFF',
                          active: pump,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),
              // Moisture value
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    moisture != null ? '$moisture%' : '--',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'moisture',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoistureBar extends StatelessWidget {
  final int? moisture;
  final int dryThreshold;
  final int wetThreshold;

  const _MoistureBar({
    required this.moisture,
    required this.dryThreshold,
    required this.wetThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = moisture != null ? (moisture! / 100).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: 6,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: fraction,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;

  const _Pill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? AppColors.accent : AppColors.tabUnselected,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: active ? AppColors.onAccent : AppColors.textSecondary,
        ),
      ),
    );
  }
}
