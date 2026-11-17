import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/device_provider.dart';
import '../models/device.dart';
import '../models/reading.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int? _selectedDeviceId;
  int _hours = 24;
  List<Reading>? _readings;
  bool _loading = false;
  String? _error;
  final _api = ApiService();

  Future<void> _load(int deviceId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _api.fetchReadings(deviceId, hours: _hours);
      setState(() {
        _readings = r;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load readings';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceProvider>().devices;

    // Auto-select first device
    if (_selectedDeviceId == null && devices.isNotEmpty) {
      _selectedDeviceId = devices.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _load(_selectedDeviceId!);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('History')),
      body: devices.isEmpty
          ? const _EmptyDevices()
          : Column(
              children: [
                // Device selector
                _DeviceSelector(
                  devices: devices,
                  selectedId: _selectedDeviceId,
                  onSelect: (id) {
                    setState(() {
                      _selectedDeviceId = id;
                      _readings = null;
                    });
                    _load(id);
                  },
                ),

                // Range chips
                _RangeChips(
                  selected: _hours,
                  onSelect: (h) {
                    setState(() => _hours = h);
                    if (_selectedDeviceId != null) _load(_selectedDeviceId!);
                  },
                ),

                // Chart
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent))
                      : _error != null
                          ? Center(child: Text(_error!))
                          : _readings == null || _readings!.isEmpty
                              ? const _EmptyReadings()
                              : _ChartView(readings: _readings!),
                ),
              ],
            ),
    );
  }
}

class _DeviceSelector extends StatelessWidget {
  final List<Device> devices;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  const _DeviceSelector(
      {required this.devices, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 6),
        itemCount: devices.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = devices[i];
          final selected = d.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(d.id),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.tabUnselected,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                d.name.isNotEmpty ? d.name : 'Device ${d.id}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.onAccent : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RangeChips extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _RangeChips({required this.selected, required this.onSelect});

  static const _options = [6, 24, 48, 168];
  static const _labels = ['6h', '24h', '48h', '7d'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      child: Row(
        children: List.generate(_options.length, (i) {
          final active = selected == _options[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(_options[i]),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : AppColors.tabUnselected,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        active ? AppColors.onAccent : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ChartView extends StatelessWidget {
  final List<Reading> readings;

  const _ChartView({required this.readings});

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) return const _EmptyReadings();

    final spots = readings.asMap().entries.map((e) {
      final m = e.value.soilMoisture?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), m);
    }).toList();

    final fmt = DateFormat('HH:mm');
    final minY = 0.0;
    final maxY = 100.0;

    // Stats
    final values = readings
        .where((r) => r.soilMoisture != null)
        .map((r) => r.soilMoisture!)
        .toList();
    final avg = values.isEmpty
        ? 0
        : (values.reduce((a, b) => a + b) / values.length).round();
    final min = values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
    final max = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        children: [
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.cardBorderRadius,
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(label: 'Min', value: '$min%'),
                _Divider(),
                _Stat(label: 'Avg', value: '$avg%'),
                _Divider(),
                _Stat(label: 'Max', value: '$max%'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          // Chart
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.base, AppSpacing.base, AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.cardBorderRadius,
                border: Border.all(color: AppColors.divider),
              ),
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.divider,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}%',
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textSecondary),
                        ),
                        interval: 25,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval:
                            (readings.length / 4).ceilToDouble().clamp(1, 999),
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= readings.length) {
                            return const SizedBox();
                          }
                          return Text(
                            fmt.format(readings[idx].createdAt.toLocal()),
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.textSecondary),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.accent,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.accent.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.divider);
  }
}

class _EmptyReadings extends StatelessWidget {
  const _EmptyReadings();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart, size: 48, color: AppColors.divider),
          const SizedBox(height: AppSpacing.base),
          Text('No readings in this range',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.grass_outlined, size: 56, color: AppColors.divider),
          const SizedBox(height: AppSpacing.base),
          Text('No devices yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('Add a device first to see its history.',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
