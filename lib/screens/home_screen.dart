import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';
import '../widgets/soil_gauge.dart';
import 'device_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final devices = provider.devices;
    final loading = provider.loadingDevices;
    final error = provider.deviceError;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base, AppSpacing.lg, AppSpacing.base, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SmartGrow',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(fontSize: 28),
                        ),
                        Text(
                          '${devices.length} device${devices.length == 1 ? '' : 's'} connected',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: error == null
                            ? AppColors.accent.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: error == null ? AppColors.accent : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            error == null ? 'Live' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: error == null ? AppColors.accent : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            if (loading)
              SliverToBoxAdapter(
                child: _buildLoadingGauge(),
              )
            else if (error != null)
              SliverToBoxAdapter(child: _ErrorBanner(message: error))
            else if (devices.isEmpty)
              const SliverToBoxAdapter(child: _EmptyState())
            else
              SliverToBoxAdapter(
                child: _DeviceFocusCard(
                  device: devices.first,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DeviceDetailScreen(deviceId: devices.first.id),
                    ),
                  ),
                  onModeChanged: (mode) => context
                      .read<DeviceProvider>()
                      .updateDevice(devices.first.id, {'mode': mode}),
                  onPumpToggled: (val) => context
                      .read<DeviceProvider>()
                      .updateDevice(devices.first.id, {'manual_pump': val}),
                ),
              ),

            // All devices (after the first)
            if (!loading && error == null && devices.length > 1) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.base,
                      AppSpacing.lg, AppSpacing.base, AppSpacing.sm),
                  child: Text('All Plants',
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final d = devices[i + 1];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0,
                          AppSpacing.base, AppSpacing.md),
                      child: _MiniDeviceCard(
                        device: d,
                        onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) =>
                                DeviceDetailScreen(deviceId: d.id),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: devices.length - 1,
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGauge() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardBorderRadius,
          border: Border.all(color: AppColors.divider),
        ),
      ),
    );
  }
}

// ── Focus card: gauge + controls for the primary device ───────────────────

class _DeviceFocusCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<bool> onPumpToggled;

  const _DeviceFocusCard({
    required this.device,
    required this.onTap,
    required this.onModeChanged,
    required this.onPumpToggled,
  });

  @override
  Widget build(BuildContext context) {
    final pump = device.pumpOn ?? false;
    final isManual = device.mode == 'manual';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardBorderRadius,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              // Top: name + plant
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base, AppSpacing.base, AppSpacing.base, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          device.plant.isNotEmpty ? device.plant : 'No plant set',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Icon(Icons.chevron_right,
                        color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),

              // Gauge
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
                child: SoilGauge(
                  value: device.soilMoisture,
                  dryThreshold: device.dryThreshold,
                  wetThreshold: device.wetThreshold,
                  size: 220,
                ),
              ),

              // Air readings row
              if (device.airTemp != null || device.airHumidity != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.base, 0, AppSpacing.base, AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (device.airTemp != null)
                        _StatChip(
                            icon: Icons.thermostat_outlined,
                            label: '${device.airTemp!.toStringAsFixed(1)}°C'),
                      if (device.airTemp != null && device.airHumidity != null)
                        const SizedBox(width: AppSpacing.sm),
                      if (device.airHumidity != null)
                        _StatChip(
                            icon: Icons.water_outlined,
                            label: '${device.airHumidity!.toStringAsFixed(0)}%'),
                    ],
                  ),
                ),

              const Divider(height: 1),

              // Mode selector + pump toggle
              Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Row(
                  children: [
                    // Mode pills
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['auto', 'manual', 'off'].map((m) {
                            final selected = device.mode == m;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () => onModeChanged(m),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.accent
                                        : AppColors.tabUnselected,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    m[0].toUpperCase() + m.substring(1),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? AppColors.onAccent
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    // Pump toggle (only active in manual mode)
                    Row(
                      children: [
                        Text(
                          pump ? 'ON' : 'OFF',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: pump
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: isManual
                              ? () => onPumpToggled(!pump)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 48,
                            height: 26,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: pump
                                  ? AppColors.accent
                                  : AppColors.tabUnselected,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 150),
                              alignment: pump
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isManual
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini card for secondary devices ──────────────────────────────────────

class _MiniDeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;

  const _MiniDeviceCard({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardBorderRadius,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name,
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    device.plant.isNotEmpty ? device.plant : 'No plant set',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              device.soilMoisture != null ? '${device.soilMoisture}%' : '--',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.grass_outlined, size: 56, color: AppColors.divider),
            const SizedBox(height: AppSpacing.base),
            Text('No devices yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Power on an ESP32 and go to Plants → Add Device.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: AppRadius.cardBorderRadius,
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.red, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: 13, color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
