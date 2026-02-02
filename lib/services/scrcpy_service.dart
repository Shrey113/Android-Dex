import 'dart:async';
import 'dart:io';

/// Represents a connected ADB device
class AdbDevice {
  final String address;
  final String? product;
  final String? model;
  final String? device;
  final String? transportId;

  AdbDevice({
    required this.address,
    this.product,
    this.model,
    this.device,
    this.transportId,
  });

  String get displayName => model ?? device ?? address;

  String get displayInfo {
    final parts = <String>[];
    if (product != null) parts.add(product!);
    if (device != null && device != model) parts.add(device!);
    return parts.isEmpty ? address : parts.join(' • ');
  }
}

class ScrcpyService {
  static const String _adbPath = "All helper/platform-tools/adb.exe";
  static const String _scrcpyPath = "All helper/scrwin64/scrcpy.exe";

  late final String adbFullPath;
  late final String scrcpyFullPath;

  Process? _process;
  bool _isRunning = false;

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;
  bool get isRunning => _isRunning;

  ScrcpyService() {
    adbFullPath = File(_adbPath).absolute.path;
    scrcpyFullPath = File(_scrcpyPath).absolute.path;
  }

  Future<bool> checkToolsExist() async {
    return File(adbFullPath).existsSync() && File(scrcpyFullPath).existsSync();
  }

  /// Get list of connected ADB devices using `adb devices -l`
  Future<List<AdbDevice>> getConnectedDevices() async {
    try {
      final result = await Process.run(adbFullPath, ['devices', '-l']);
      final output = result.stdout.toString();

      final devices = <AdbDevice>[];
      final lines = output.split('\n');

      for (final line in lines) {
        // Skip header and empty lines
        if (line.startsWith('List of') || line.trim().isEmpty) continue;

        // Parse device line: "192.168.29.168:5555    device product:CPH2447 model:CPH2447 device:OP594DL1 transport_id:67"
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length < 2 || parts[1] != 'device') continue;

        final address = parts[0];
        String? product, model, device, transportId;

        for (final part in parts.skip(2)) {
          if (part.startsWith('product:')) {
            product = part.substring(8);
          } else if (part.startsWith('model:')) {
            model = part.substring(6);
          } else if (part.startsWith('device:')) {
            device = part.substring(7);
          } else if (part.startsWith('transport_id:')) {
            transportId = part.substring(13);
          }
        }

        devices.add(
          AdbDevice(
            address: address,
            product: product,
            model: model,
            device: device,
            transportId: transportId,
          ),
        );
      }

      return devices;
    } catch (e) {
      return [];
    }
  }

  Future<(bool, String)> connectAdb(String ip) async {
    try {
      final result = await Process.run(adbFullPath, ['connect', ip]);

      final output = '${result.stdout}${result.stderr}'.trim().toLowerCase();

      final success =
          output.contains('connected') || output.contains('already');

      return (success, output);
    } catch (e) {
      return (false, 'Connection failed: $e');
    }
  }

  Future<(bool, String)> startScrcpy(String ip) async {
    try {
      final scrcpyDir = File(scrcpyFullPath).parent.path;

      _process = await Process.start(scrcpyFullPath, [
        '-s',
        ip,
        '--new-display=1920x1080/280',
        '--no-audio',
        '--start-app=com.example.androiddex',
        '--no-vd-system-decorations',
      ], workingDirectory: scrcpyDir);

      _isRunning = true;
      _statusController.add(true);

      // Listen for process exit to update status
      _process!.exitCode.then((code) {
        _isRunning = false;
        _process = null;
        _statusController.add(false);
      });

      return (true, 'Display started');
    } catch (e) {
      return (false, 'Failed to start scrcpy: $e');
    }
  }

  void stopScrcpy() {
    _process?.kill(ProcessSignal.sigterm);
    _process = null;
    if (_isRunning) {
      _isRunning = false;
      _statusController.add(false);
    }
  }

  void dispose() {
    stopScrcpy();
    _statusController.close();
  }
}
