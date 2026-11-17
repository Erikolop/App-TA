import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../models/watering_event.dart';
import '../services/api_service.dart';

class DeviceProvider extends ChangeNotifier {
  final _api = ApiService();

  List<Device> devices = [];
  List<WateringEvent> events = [];
  bool loadingDevices = true;
  bool loadingEvents = true;
  String? deviceError;
  String? eventError;

  Timer? _pollTimer;

  DeviceProvider() {
    _loadAll();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadAll());
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadDevices(), _loadEvents()]);
  }

  Future<void> _loadDevices() async {
    try {
      devices = await _api.fetchDevices();
      deviceError = null;
    } catch (_) {
      deviceError = 'Cannot reach server';
    }
    loadingDevices = false;
    notifyListeners();
  }

  Future<void> _loadEvents() async {
    try {
      events = await _api.fetchEvents();
      eventError = null;
    } catch (_) {
      eventError = 'Cannot reach server';
    }
    loadingEvents = false;
    notifyListeners();
  }

  /// Force a manual refresh (pull-to-refresh, post-action).
  Future<void> refresh() => _loadAll();

  /// Patch a device (mode, thresholds, pump switch) and refresh.
  Future<void> updateDevice(int id, Map<String, dynamic> changes) async {
    await _api.updateDevice(id, changes);
    await _loadDevices();
  }

  /// Add a new device (name + plant) and refresh.
  Future<void> addDevice(int id, String name, String plant) async {
    await _api.updateDevice(id, {'name': name, 'plant': plant});
    await _loadDevices();
  }

  /// Fetch single device (for detail screen).
  Future<Device?> fetchDevice(int id) async {
    try {
      return await _api.fetchDevice(id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
