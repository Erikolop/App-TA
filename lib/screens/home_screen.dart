import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
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
            // ── Header ──────────────────────────────────────────────────
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
                          loading
                              ? 'Connecting…'
                              : '${devices.length} device${devices.length == 1 ? '' : 's'} connected',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    _StatusPill(loading: loading, error: error),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // ── Body ────────────────────────────────────────────────────
            if (loading)
              const SliverToBoxAdapter(child: _HomeShimmer())
            else if (error != null)
              SliverToBoxAdapter(
                child: _ErrorState(
                  message: error,
                  onRetry: () => context.read<DeviceProvider>().refresh(),
                ),
              )
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
                      .updateDevice(
                          devices.first.id, {'manual_pump': val}),
                ),
              ),

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
}

// ── Status pill ───────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final bool loading;
  final String? error;
  const _StatusPill({required this.loading, required this.error});

  @override
  Widget build(BuildContext context) {
    final Color dot;
    final Color bg;
    final String label;

    if (loading) {
      dot = AppColors.textSecondary;
      bg = AppColors.tabUnselected;
      label = 'Connecting';
    } else if (error != null) {
      dot = Colors.red;
      bg = Colors.red.withValues(alpha: 0.1);
      label = 'Offline';
    } else {
      dot = AppColors.accent;
      bg = AppColors.accent.withValues(alpha: 0.1);
      label = 'Live';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: dot)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dot)),
      ]),
    );
  }
}

// ── Shimmer skeleton for initial load ────────────────────────────────────

class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: AppColors.canvas,
        child: Column(children: [
          // Focus card skeleton
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.cardBorderRadius,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Mini card skeletons
          Container(height: 72, decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardBorderRadius)),
          const SizedBox(height: AppSpacing.sm),
          Container(height: 72, decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardBorderRadius)),
        ]),
      ),
    );
  }
}

// ── Error state with retry feedback ──────────────────────────────────────

class _ErrorState extends StatefulWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  State<_ErrorState> createState() => _ErrorStateState();
}

class _ErrorStateState extends State<_ErrorState> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    widget.onRetry();
    // Give visual feedback for at least 800ms
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.06),
          borderRadius: AppRadius.cardBorderRadius,
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.wifi_off, color: Colors.red, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(widget.message,
                style: const TextStyle(fontSize: 13, color: Colors.red)),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _retrying ? null : _retry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
              ),
              child: _retrying
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Retry',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Focus card ────────────────────────────────────────────────────────────

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
    final pump = device.manualPump;
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
          child: Column(children: [
            // Name + plant
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base, AppSpacing.base, AppSpacing.base, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(device.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      device.plant.isNotEmpty ? device.plant : 'No plant set',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ]),
                  const Icon(Icons.chevron_right,
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

            // Air readings
            if (device.airTemp != null || device.airHumidity != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base, 0, AppSpacing.base, AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (device.airTemp != null)
                      _StatChip(icon: Icons.thermostat_outlined, label: '${device.airTemp!.toStringAsFixed(1)}°C'),
                    if (device.airTemp != null && device.airHumidity != null)
                      const SizedBox(width: AppSpacing.sm),
                    if (device.airHumidity != null)
                      _StatChip(icon: Icons.water_outlined, label: '${device.airHumidity!.toStringAsFixed(0)}%'),
                  ],
                ),
              ),

            const Divider(height: 1),

            // Controls: mode pills + pump toggle
            Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(children: [
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
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

                // Pump toggle
                GestureDetector(
                  onTap: isManual ? () => onPumpToggled(!pump) : null,
                  child: Row(children: [
                    Text(
                      pump ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isManual
                            ? (pump ? AppColors.accent : AppColors.textSecondary)
                            : AppColors.divider,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 48, height: 26,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isManual
                            ? (pump ? AppColors.accent : AppColors.tabUnselected)
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 150),
                        alignment: pump
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 22, height: 22,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Mini card ─────────────────────────────────────────────────────────────

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
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(device.name, style: Theme.of(context).textTheme.titleSmall),
              Text(
                device.plant.isNotEmpty ? device.plant : 'No plant set',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
          ),
          Text(
            device.soilMoisture != null ? '${device.soilMoisture}%' : '--',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
        ]),
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
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
        child: Column(children: [
          Icon(Icons.grass_outlined, size: 56, color: AppColors.divider),
          const SizedBox(height: AppSpacing.base),
          Text('No devices yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Power on an ESP32 and go to Plants → Add Device.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ]),
      ),
    );
  }
}
