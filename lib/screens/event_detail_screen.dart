import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import '../core/theme.dart';
import '../models/watering_event.dart';
import '../services/api_service.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  WateringEvent? _event;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    try {
      final e = await ApiService().fetchEvent(widget.eventId);
      if (mounted) setState(() => _event = e);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Watering Event')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _error
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: AppSpacing.base),
                  const Text('Failed to load event'),
                  const SizedBox(height: AppSpacing.base),
                  ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, shape: const StadiumBorder()), child: const Text('Retry')),
                ]))
              : _event == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      children: [
                        _SummaryCard(event: _event!),
                        const SizedBox(height: AppSpacing.sm),
                        _MoistureCard(event: _event!),
                        const SizedBox(height: AppSpacing.sm),
                        _TimelineCard(event: _event!),
                        const SizedBox(height: AppSpacing.sm),
                        _DeviceCard(event: _event!),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final WateringEvent event;
  const _SummaryCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final isAuto = event.trigger == 'auto';
    return _Card(
      child: Column(
        children: [
          Text(event.durationLabel, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: isAuto ? AppColors.accent : AppColors.tabUnselected, borderRadius: BorderRadius.circular(999)),
            child: Text(event.trigger.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isAuto ? Colors.white : AppColors.textSecondary, letterSpacing: 0.5)),
          ),
          if (event.deviceName.isNotEmpty || event.plant.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              [if (event.deviceName.isNotEmpty) event.deviceName, if (event.plant.isNotEmpty) event.plant].join(' · '),
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _MoistureCard extends StatelessWidget {
  final WateringEvent event;
  const _MoistureCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final before = event.moistureBefore != null ? '${event.moistureBefore}%' : '--';
    final after = event.moistureAfter != null ? '${event.moistureAfter}%' : '--';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Moisture Change', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _BigValue(label: 'Before', value: before),
            const Icon(Icons.arrow_forward, color: AppColors.accent, size: 24),
            _BigValue(label: 'After', value: after),
          ]),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final WateringEvent event;
  const _TimelineCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy, HH:mm:ss');
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Timeline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow('Started', fmt.format(event.startedAt.toLocal())),
          _InfoRow('Ended', fmt.format(event.endedAt.toLocal())),
          _InfoRow('Duration', event.durationLabel),
          _InfoRow('Trigger', event.trigger[0].toUpperCase() + event.trigger.substring(1)),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final WateringEvent event;
  const _DeviceCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Device', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow('Name', event.deviceName.isNotEmpty ? event.deviceName : 'Unknown'),
          _InfoRow('Plant', event.plant.isNotEmpty ? event.plant : '—'),
        ],
      ),
    );
  }
}

class _BigValue extends StatelessWidget {
  final String label;
  final String value;
  const _BigValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary), textAlign: TextAlign.end)),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardBorderRadius, border: Border.all(color: AppColors.divider)),
      child: child,
    );
  }
}
