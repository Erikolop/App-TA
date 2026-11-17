import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/device.dart';
import '../models/watering_event.dart';
import '../services/api_service.dart';

class DeviceProvider extends ChangeNotifier with WidgetsBindingObserver {
  final _api = ApiService();

  List<Device> devices = [];
  List<WateringEvent> events = [];

  // Three-state loading: true = first load, false = loaded or error.
  bool loadingDevices = true;
  bool loadingEvents = true;

  // null  = no error yet / within grace period
  // non-null = show error + retry button
  String? deviceError;
  String? eventError;

  // How many consecutive failures before we surface the error to the user.
  static const _errorGrace = 3;
  int _deviceFailCount = 0;
  int _eventFailCount = 0;

  Timer? _pollTimer;
  bool _paused = false; // true while app is backgrounded

  DeviceProvider() {
    WidgetsBinding.instance.addObserver(this);
    _loadAll();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) { if (!_paused) _loadAll(); },
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _paused = false;
      // Resume: reset failure counts so we don't show stale errors
      // then do one immediate load.
      _deviceFailCount = 0;
      _eventFailCount = 0;
      _loadAll();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _paused = true;
    }
  }

  // ── Core loaders ─────────────────────────────────────────────────────────

  Future<void> _loadAll() =>
      Future.wait([_loadDevices(), _loadEvents()]);

  Future<void> _loadDevices() async {
    try {
      final d = await _api.fetchDevices();
      devices = d;
      deviceError = null;
      _deviceFailCount = 0;
    } catch (_) {
      _deviceFailCount++;
      if (_deviceFailCount >= _errorGrace) {
        deviceError = 'Cannot reach server';
      }
      // Before the grace threshold: keep the last data, show nothing new.
    }
    loadingDevices = false;
    notifyListeners();
  }

  Future<void> _loadEvents() async {
    try {
      final e = await _api.fetchEvents();
      events = e;
      eventError = null;
      _eventFailCount = 0;
    } catch (_) {
      _eventFailCount++;
      if (_eventFailCount >= _errorGrace) {
        eventError = 'Cannot reach server';
      }
    }
    loadingEvents = false;
    notifyListeners();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Manual refresh — resets error state immediately (user chose to retry).
  Future<void> refresh() async {
    _deviceFailCount = 0;
    _eventFailCount = 0;
    deviceError = null;
    eventError = null;
    loadingDevices = true;
    loadingEvents = true;
    notifyListeners();
    await _loadAll();
  }

  /// Optimistically update a device locally, then sync to server.
  Future<void> updateDevice(int id, Map<String, dynamic> changes) async {
    // Optimistic: apply the change to the local list instantly.
    final idx = devices.indexWhere((d) => d.id == id);
    if (idx != -1) {
      devices[idx] = devices[idx].copyWith(
        mode: changes['mode'] as String?,
        dryThreshold: changes['dry_threshold'] as int?,
        wetThreshold: changes['wet_threshold'] as int?,
        maxRunS: changes['max_run_s'] as int?,
        cooldownMin: changes['cooldown_min'] as int?,
        manualPump: changes['manual_pump'] as bool?,
      );
      notifyListeners();
    }
    // Sync to server — fire and forget, then do one quiet refresh.
    try {
      await _api.updateDevice(id, changes);
    } catch (_) {
      // Server rejected — the next poll will restore the real value.
    }
    // Quiet refresh: don't set loadingDevices=true, just update silently.
    try {
      final d = await _api.fetchDevices();
      devices = d;
      deviceError = null;
      _deviceFailCount = 0;
      notifyListeners();
    } catch (_) {
      // ignore — keep optimistic value until next successful poll
    }
  }

  /// Add a new device (name + plant).
  Future<void> addDevice(int id, String name, String plant) async {
    await _api.updateDevice(id, {'name': name, 'plant': plant});
    await _loadDevices();
  }

  /// Fetch single device for the detail screen.
  Future<Device?> fetchDevice(int id) async {
    try {
      return await _api.fetchDevice(id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }
}
