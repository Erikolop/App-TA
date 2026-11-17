import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/device_provider.dart';
import '../services/api_service.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  Timer? _timer;
  List<Map<String, dynamic>> _newDevices = [];
  bool _loading = true;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final d = await _api.fetchNewDevices();
      if (mounted) setState(() => _newDevices = d);
    } catch (_) {
      // retain last known list silently
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _truncate(String hwId) =>
      hwId.length <= 8 ? hwId : hwId.substring(hwId.length - 8);

  String _relativeTime(dynamic lastSeen) {
    if (lastSeen == null) return 'unknown';
    final dt = lastSeen is DateTime
        ? lastSeen
        : DateTime.tryParse(lastSeen.toString());
    if (dt == null) return 'unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes == 1) return '1 minute ago';
    if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
    if (diff.inHours == 1) return '1 hour ago';
    return '${diff.inHours} hours ago';
  }

  Future<void> _showDialog(Map<String, dynamic> device) async {
    final nameCtrl = TextEditingController();
    final plantCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorderRadius),
        title: const Text('Name & Add Device', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nameCtrl,
              decoration: InputDecoration(hintText: 'e.g. Cabai 1', labelText: 'Name', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent))),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: plantCtrl,
              decoration: InputDecoration(hintText: 'e.g. Cabai', labelText: 'Plant', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent))),
              textCapitalization: TextCapitalization.words,
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();
              final id = device['id'] as int;
              await context.read<DeviceProvider>().addDevice(id, nameCtrl.text.trim(), plantCtrl.text.trim());
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Device added'), backgroundColor: AppColors.accent, behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, shape: const StadiumBorder()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Add Device')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          // Info card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardBorderRadius, border: Border.all(color: AppColors.divider)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.accent, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'New devices appear here after powering on and connecting to WiFi. Tap a device to give it a name and plant.',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
            )
          else if (_newDevices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xl),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.sensors, size: 56, color: AppColors.divider),
                const SizedBox(height: AppSpacing.base),
                const Text('No new devices found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                const Text('Power on an ESP32 — it will appear here within 30 seconds.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
              ]),
            )
          else
            ...(_newDevices.map((d) {
              final hwId = _truncate(d['hw_id']?.toString() ?? d['id']?.toString() ?? '');
              final lastSeen = _relativeTime(d['last_seen']);
              return Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.base, 0, AppSpacing.base, AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardBorderRadius, border: Border.all(color: AppColors.divider)),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('···${hwId.toUpperCase()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'monospace')),
                        const SizedBox(height: 3),
                        Text('last seen $lastSeen', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ]),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: () => _showDialog(d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(999)),
                        child: const Text('Name & Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ]),
                ),
              );
            })),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
