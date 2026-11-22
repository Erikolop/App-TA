import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/device.dart';
import '../models/watering_event.dart';
import '../services/api_service.dart';

class DeviceProvider extends ChangeNotifier with WidgetsBindingObserver {
  final _api = ApiService();

  List<Device> devices = [];
  List<WateringEvent> events = [];

  // ── In-flight change protection ───────────────────────────────────────────
  // Maps device-id → { field → latestPendingValue }.
  // Every poll re-applies these on top of server data so a slow/stale poll
  // can never flash the UI back to an old value while a PATCH is in-flight.
  // A field is removed only after the PATCH that last set it succeeds (or
  // fails) AND the value this call set is still the latest pending value.
  final Map<int, Map<String, dynamic>> _inflight = {};

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
      // Re-apply any in-flight optimistic overrides on top of the server data.
      // This prevents a stale poll response from flickering the UI back to an
      // old value while a PATCH is still in-flight or hasn't been picked up yet.
      devices = d.map((device) {
        final overrides = _inflight[device.id];
        return overrides != null ? _applyChanges(device, overrides) : device;
      }).toList();
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
  /// In-flight tracking ensures polls never overwrite the pending value.
  Future<void> updateDevice(int id, Map<String, dynamic> changes) async {
    // Record every field we're about to send so polls can re-apply them.
    _inflight[id] = {...?_inflight[id], ...changes};

    // Optimistic: apply immediately so the UI responds at once.
    final idx = devices.indexWhere((d) => d.id == id);
    if (idx != -1) {
      devices[idx] = _applyChanges(devices[idx], changes);
      notifyListeners();
    }

    // Keep a snapshot of exactly what this call sent so we can selectively
    // remove only those keys after the call completes (a later tap may have
    // already overwritten some keys with newer values).
    final sent = Map<String, dynamic>.from(changes);

    try {
      await _api.updateDevice(id, sent);
      // Success: remove fields whose latest pending value still matches what
      // we just confirmed.  If the user tapped again, the newer value stays.
      _removeInflight(id, sent);
    } catch (_) {
      // Server rejected: remove overrides so the next poll restores truth.
      _removeInflight(id, sent);
    }
  }

  /// Remove [sent] keys from the in-flight map, but only when the recorded
  /// pending value still equals what this particular call sent.
  void _removeInflight(int id, Map<String, dynamic> sent) {
    final pending = _inflight[id];
    if (pending == null) return;
    for (final entry in sent.entries) {
      if (pending[entry.key] == entry.value) {
        pending.remove(entry.key);
      }
    }
    if (pending.isEmpty) _inflight.remove(id);
  }

  /// Apply a changes map on top of a Device, returning the updated copy.
  Device _applyChanges(Device d, Map<String, dynamic> changes) {
    return d.copyWith(
      mode: changes['mode'] as String?,
      dryThreshold: changes['dry_threshold'] as int?,
      wetThreshold: changes['wet_threshold'] as int?,
      maxRunS: changes['max_run_s'] as int?,
      cooldownMin: changes['cooldown_min'] as int?,
      manualPump: changes['manual_pump'] as bool?,
    );
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
