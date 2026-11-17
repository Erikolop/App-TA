import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../models/device.dart';
import '../models/watering_event.dart';
import '../models/reading.dart';

class ApiService {
  static const _timeout = Duration(seconds: 20);
  static const _json = {'Content-Type': 'application/json'};

  Uri _uri(String path) => Uri.parse('${Config.baseUrl}$path');

  // ── Devices ──────────────────────────────────────────────────────────────

  Future<List<Device>> fetchDevices() async {
    final r = await http.get(_uri('/devices')).timeout(_timeout);
    _checkStatus(r);
    return (jsonDecode(r.body) as List)
        .map((e) => Device.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Device> fetchDevice(int id) async {
    final r = await http.get(_uri('/devices/$id')).timeout(_timeout);
    _checkStatus(r);
    return Device.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> fetchNewDevices() async {
    final r = await http.get(_uri('/devices/new')).timeout(_timeout);
    _checkStatus(r);
    return List<Map<String, dynamic>>.from(jsonDecode(r.body) as List);
  }

  Future<Device> updateDevice(int id, Map<String, dynamic> changes) async {
    final r = await http
        .patch(_uri('/devices/$id'), headers: _json, body: jsonEncode(changes))
        .timeout(_timeout);
    _checkStatus(r);
    return Device.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  // ── Readings ─────────────────────────────────────────────────────────────

  Future<List<Reading>> fetchReadings(int deviceId, {int hours = 24}) async {
    final r = await http
        .get(_uri('/devices/$deviceId/readings?hours=$hours'))
        .timeout(_timeout);
    _checkStatus(r);
    return (jsonDecode(r.body) as List)
        .map((e) => Reading.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Events ───────────────────────────────────────────────────────────────

  Future<List<WateringEvent>> fetchEvents() async {
    final r = await http.get(_uri('/events')).timeout(_timeout);
    _checkStatus(r);
    return (jsonDecode(r.body) as List)
        .map((e) => WateringEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WateringEvent> fetchEvent(int id) async {
    final r = await http.get(_uri('/events/$id')).timeout(_timeout);
    _checkStatus(r);
    return WateringEvent.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _checkStatus(http.Response r) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ApiException(r.statusCode, r.body);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
