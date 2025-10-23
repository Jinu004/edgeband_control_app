import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device_status.dart';

class BleService extends ChangeNotifier {
  static const String serviceUuid = "12345678-1234-1234-1234-123456789abc";
  static const String controlCharUuid = "22334455-6677-8899-aabb-ccddeeff0011";
  static const String responseCharUuid = "33445566-7788-99aa-bbcc-ddeeff001122";

  BluetoothDevice? _device;
  BluetoothCharacteristic? _controlChar;
  BluetoothCharacteristic? _responseChar;
  StreamSubscription? _deviceStateSubscription;
  StreamSubscription? _responseSubscription;

  bool _isConnected = false;
  bool _isScanning = false;
  DeviceStatus? _deviceStatus;
  String? _lastError;
  List<BluetoothDevice> _discoveredDevices = [];

  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  DeviceStatus? get deviceStatus => _deviceStatus;
  String? get lastError => _lastError;
  List<BluetoothDevice> get discoveredDevices => _discoveredDevices;

  Future<void> startScan() async {
    _isScanning = true;
    _discoveredDevices.clear();
    _lastError = null;
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          if (result.device.platformName.contains('EdgeBandCutter')) {
            if (!_discoveredDevices.contains(result.device)) {
              _discoveredDevices.add(result.device);
              notifyListeners();
            }
          }
        }
      });

      await Future.delayed(const Duration(seconds: 15));
      await FlutterBluePlus.stopScan();
    } catch (e) {
      _lastError = 'Scan error: $e';
      debugPrint('Scan error: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _lastError = null;
      notifyListeners();

      await device.connect(timeout: const Duration(seconds: 15));
      _device = device;

      _deviceStateSubscription = device.connectionState.listen((state) {
        _isConnected = state == BluetoothConnectionState.connected;
        if (!_isConnected) {
          _cleanup();
        }
        notifyListeners();
      });

      await Future.delayed(const Duration(milliseconds: 500));
      final services = await device.discoverServices();

      for (var service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (var char in service.characteristics) {
            if (char.uuid.toString() == controlCharUuid) {
              _controlChar = char;
            } else if (char.uuid.toString() == responseCharUuid) {
              _responseChar = char;
              await char.setNotifyValue(true);
              _responseSubscription = char.lastValueStream.listen(_handleResponse);
            }
          }
        }
      }

      if (_controlChar == null || _responseChar == null) {
        throw Exception('Required characteristics not found');
      }

      _isConnected = true;
      notifyListeners();

      // Request initial status
      await Future.delayed(const Duration(milliseconds: 500));
      await sendCommand('get_status');

      return true;
    } catch (e) {
      _lastError = 'Connection error: $e';
      debugPrint('Connection error: $e');
      _cleanup();
      notifyListeners();
      return false;
    }
  }

  void _handleResponse(List<int> value) {
    try {
      final jsonString = utf8.decode(value);
      debugPrint('📥 BLE Response: $jsonString');

      final Map<String, dynamic> json = jsonDecode(jsonString);

      // Handle error responses
      if (json['status'] == 'error') {
        _lastError = json['message'] ?? 'Unknown error from device';
        debugPrint('❌ Device error: $_lastError');
        notifyListeners();
        return;
      }

      // Handle status updates (contains device state)
      if (json.containsKey('state')) {
        _deviceStatus = DeviceStatus.fromJson(json);
        _lastError = null; // Clear error on successful status update
        notifyListeners();
      }

      // Handle simple OK responses
      if (json['status'] == 'ok') {
        _lastError = null;
        debugPrint('✅ Command successful: ${json['message'] ?? ""}');
      }
    } catch (e) {
      debugPrint('Error parsing response: $e');
      _lastError = 'Failed to parse device response';
      notifyListeners();
    }
  }

  Future<bool> sendCommand(String command, {Map<String, dynamic>? params}) async {
    if (_controlChar == null || !_isConnected) {
      _lastError = 'Device not connected';
      notifyListeners();
      return false;
    }

    try {
      final Map<String, dynamic> cmdData = {'cmd': command};
      if (params != null) {
        cmdData.addAll(params);
      }

      final jsonString = jsonEncode(cmdData);
      await _controlChar!.write(utf8.encode(jsonString), withoutResponse: false);

      debugPrint('Sent command: $jsonString');
      return true;
    } catch (e) {
      _lastError = 'Command error: $e';
      debugPrint('Command error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> setLength(double meters) async {
    // ESP32 ControlCharacteristic expects 'length' (not 'value')
    // It validates 0.1-100m and internally converts to cm by multiplying by 100
    debugPrint('📤 Setting length: $meters meters');
    final success = await sendCommand('set_length', params: {'length': meters});

    // Wait a bit for the device to process and send status update
    if (success) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return success;
  }

  Future<bool> startCutting() async {
    debugPrint('📤 Starting cutting operation');
    return await sendCommand('start');
  }

  Future<bool> stopCutting() async {
    debugPrint('📤 Stopping cutting operation');
    return await sendCommand('stop');
  }

  Future<bool> resumeCutting() async {
    debugPrint('📤 Resuming cutting operation');
    return await sendCommand('resume');
  }

  Future<bool> speedIncrease() async {
    return await sendCommand('speed_up');
  }

  Future<bool> speedDecrease() async {
    return await sendCommand('speed_down');
  }

  Future<bool> setDiameter(double cm) async {
    return await sendCommand('set_diameter', params: {'value': cm});
  }

  Future<bool> setSpeed(int speed) async {
    return await sendCommand('set_speed', params: {'value': speed});
  }

  Future<bool> setOffset(double cm) async {
    return await sendCommand('set_offset', params: {'value': cm});
  }

  Future<bool> setMinStartSpeed(int speed) async {
    return await sendCommand('set_min_start_speed', params: {'value': speed});
  }

  Future<bool> setMinStopSpeed(int speed) async {
    return await sendCommand('set_min_stop_speed', params: {'value': speed});
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _cleanup();
  }

  void _cleanup() {
    _deviceStateSubscription?.cancel();
    _responseSubscription?.cancel();
    _device = null;
    _controlChar = null;
    _responseChar = null;
    _isConnected = false;
    _deviceStatus = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}