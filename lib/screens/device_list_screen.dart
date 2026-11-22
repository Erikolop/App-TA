import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/animated_page_route.dart';
import '../providers/device_provider.dart';
import '../widgets/device_card.dart';
import '../widgets/shimmer_card.dart';
import 'device_detail_screen.dart';
import 'add_device_screen.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final devices = provider.devices;
    final loading = provider.loadingDevices;
    final error = provider.deviceError;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Plants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Device',
            onPressed: () => context.pushSlideUp(const AddDeviceScreen()),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: provider.refresh,
        child: loading
            ? const ShimmerList()
            : error != null
                ? _ErrorState(message: error, onRetry: provider.refresh)
                : devices.isEmpty
                    ? _EmptyState(
                        onAddTap: () => context.pushSlideUp(
                          const AddDeviceScreen(),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        itemCount: devices.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (ctx, i) => DeviceCard(
                          device: devices[i],
                          onTap: () => ctx.pushAnimated(
                            DeviceDetailScreen(deviceId: devices[i].id),
                          ),
                        ),
                      ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;
  const _EmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grass_outlined, size: 64, color: AppColors.divider),
            const SizedBox(height: AppSpacing.base),
            Text('No plants yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Power on an ESP32 node and tap Add Device to get started.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: onAddTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '+ Add Device',
                  style: TextStyle(
                    color: AppColors.onAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.red),
            const SizedBox(height: AppSpacing.base),
            Text(message,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.red)),
            const SizedBox(height: AppSpacing.base),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
