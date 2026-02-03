import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdbTcpServer {
  static final AdbTcpServer instance = AdbTcpServer._internal();
  AdbTcpServer._internal();

  final int tcpPort = 8456;
  final Map<String, Socket> connectedClients = {};
  final Map<String, StringBuffer> _buffers = {};

  static const String _adbPath = "All helper/platform-tools/adb.exe";
  static const String _scrcpyPath = "All helper/scrwin64/scrcpy.exe";
  static const String _mdnsPath = "All helper/mdns_service/mdns_service.exe";

  final String adbFullPath = File(_adbPath).absolute.path;
  final String scrcpyFullPath = File(_scrcpyPath).absolute.path;
  final String mdnsFullPath = File(_mdnsPath).absolute.path;

  ServerSocket? _server;
  Process? _mdnsProcess;
  bool _isRunning = false;
  final _statusController = StreamController<bool>.broadcast();

  bool get isRunning => _isRunning;
  Stream<bool> get statusStream => _statusController.stream;

  Future<void> init() async {
    await start();
  }

  Future<void> stop_port() async {
    try {
      if (_server != null) {
        await _server!.close();
        _server = null;
      }

      _isRunning = false;
      _statusController.add(false);

      dev.log("TCP Server stopped");
    } catch (e) {
      dev.log("Failed to stop TCP Server: $e");
    }
  }

  Future<bool> start() async {
    dev.log("TCP Server already running, stopping first...");
    await stop_port();

    try {
      _server = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        tcpPort,
        shared: false, // important on Windows
      );

      _isRunning = true;
      _statusController.add(true);

      dev.log("TCP Server started on port $tcpPort");

      _listenForConnections();

      // Start mDNS only AFTER TCP is confirmed
      await _startMdnsService();

      return true;
    } catch (e) {
      dev.log("Failed to start TCP Server: $e");
      return false;
    }
  }

  Future<void> stopExistingMdnsService() async {
    try {
      // Windows-only
      final result = await Process.run('taskkill', [
        '/IM',
        'mdns_service.exe',
        '/F',
      ], runInShell: true);

      if (result.exitCode == 0) {
        dev.log('Existing mDNS service stopped');
      } else {
        dev.log('No existing mDNS service found');
      }
    } catch (e) {
      dev.log('Failed to stop existing mDNS service: $e');
    }
  }

  Future<void> _startMdnsService() async {
    try {
      // Stop any old instance first
      await stopExistingMdnsService();

      if (_mdnsProcess != null) return;

      final mdnsDir = File(mdnsFullPath).parent.path;

      _mdnsProcess = await Process.start(
        mdnsFullPath,
        [],
        workingDirectory: mdnsDir,
      );

      dev.log("mDNS service started: $mdnsFullPath");

      _mdnsProcess!.stdout.transform(const SystemEncoding().decoder).listen((
        data,
      ) {
        dev.log("[mDNS] $data");
      });

      _mdnsProcess!.stderr.transform(const SystemEncoding().decoder).listen((
        data,
      ) {
        dev.log("[mDNS ERROR] $data");
      });

      _mdnsProcess!.exitCode.then((code) {
        dev.log("mDNS service exited with code: $code");
        _mdnsProcess = null;
      });
    } catch (e) {
      dev.log("Failed to start mDNS service: $e");
    }
  }

  Future<void> _stopMdnsService() async {
    if (_mdnsProcess != null) {
      _mdnsProcess!.kill();
      _mdnsProcess = null;
      dev.log("mDNS service stopped");
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    for (final socket in connectedClients.values) {
      try {
        socket.close();
      } catch (_) {}
    }
    connectedClients.clear();
    _buffers.clear();
    await SimpleAudioProcessManager.instance.stopAll();
    await _stopMdnsService();
    await _server?.close();
    _server = null;
    _isRunning = false;
    _statusController.add(false);
    dev.log("TCP Server stopped");
  }

  void _listenForConnections() {
    _server?.listen((socket) {
      final ip = socket.remoteAddress.address;
      dev.log("Client connected: $ip");

      connectedClients[ip] = socket;
      _buffers[ip] = StringBuffer();

      socket.listen(
        (raw) async {
          final txt = utf8.decode(raw);
          final buf = _buffers[ip]!..write(txt);

          var all = buf.toString();

          while (all.contains("\n")) {
            final idx = all.indexOf("\n");
            final line = all.substring(0, idx).trim();
            all = all.substring(idx + 1);

            if (line.isNotEmpty) {
              await _handleCommand(ip, socket, line);
            }
          }

          buf
            ..clear()
            ..write(all);
        },
        onDone: () async {
          connectedClients.remove(ip);
          _buffers.remove(ip);
          broadcast("close");
          if (ip == "127.0.0.1" || ip == "localhost") return;
          await SimpleAudioProcessManager.instance.stopAll();
        },
        onError: (_) async {
          connectedClients.remove(ip);
          _buffers.remove(ip);
          broadcast("close");
          if (ip == "127.0.0.1" || ip == "localhost") return;
          await SimpleAudioProcessManager.instance.stopAll();
        },
      );
    });
  }

  bool safeWrite(Socket socket, dynamic data) {
    try {
      String msg;

      if (data is Map<String, dynamic>) {
        msg = "${jsonEncode(data)}\n";
      } else if (data is String) {
        msg = data.endsWith("\n") ? data : "$data\n";
      } else {
        throw Exception("Unsupported data type");
      }

      socket.write(msg);
      return true;
    } catch (_) {
      return false;
    }
  }

  static void broadcast(String cmd) {
    final jsonMsg = "${jsonEncode({"msg": cmd})}\n";

    final dead = <String>[];

    instance.connectedClients.forEach((ip, socket) {
      if (ip == "127.0.0.1" || ip == "localhost") {
        return;
      }

      final ok = instance.safeWrite(socket, jsonMsg);
      if (!ok) dead.add(ip);
    });

    for (final ip in dead) {
      instance.connectedClients.remove(ip);
      instance._buffers.remove(ip);
    }
  }

  static void broadcastjson(Map<String, dynamic> data) {
    final dead = <String>[];

    instance.connectedClients.forEach((ip, socket) {
      final ok = instance.safeWrite(socket, data);
      if (!ok) dead.add(ip);
    });

    for (final ip in dead) {
      instance.connectedClients.remove(ip);
      instance._buffers.remove(ip);
    }
  }

  Future<List<dynamic>> adbRun(String ip, List<String> cmd) async {
    final full = [adbFullPath, "-s", "$ip:5555", ...cmd];

    try {
      final r = await Process.run(full.first, full.sublist(1));
      return [r.stdout.toString().trim(), r.exitCode];
    } catch (_) {
      return ["", 1];
    }
  }

  Future<bool?> getBluetoothStatus(String ip) async {
    final r = await adbRun(ip, [
      "shell",
      "settings",
      "get",
      "global",
      "bluetooth_on",
    ]);
    if (r[1] != 0) return null;
    return r[0] == "1";
  }

  Future<bool?> toggleBluetooth(String ip) async {
    final current = await getBluetoothStatus(ip);
    if (current == null) return null;

    final cmd = current ? "disable" : "enable";

    final r = await adbRun(ip, ["shell", "cmd", "bluetooth_manager", cmd]);

    if (r[1] != 0) return null;
    return !current;
  }

  Future<bool?> getMobileStatus(String ip) async {
    final r = await adbRun(ip, [
      "shell",
      "settings",
      "get",
      "global",
      "mobile_data",
    ]);
    if (r[1] != 0) return null;
    return r[0] == "1";
  }

  Future<bool?> toggleMobile(String ip) async {
    final current = await getMobileStatus(ip);
    if (current == null) return null;

    final r =
        current
            ? await adbRun(ip, ["shell", "svc", "data", "disable"])
            : await adbRun(ip, ["shell", "svc", "data", "enable"]);

    if (r[1] != 0) return null;
    return !current;
  }

  void _sendJson(Socket socket, Map<String, dynamic> data) {
    safeWrite(socket, "${jsonEncode(data)}\n");
  }

  void _app_data_updates(
    String ip,
    Socket socket,
    Map<String, dynamic> jsonData,
  ) {
    broadcastjson(jsonData);
    dev.log("App Data Updates - Button: ${jsonData["package"]}");
  }

  Future<void> _handleInputCommand(String ip, Map<String, dynamic> json) async {
    final type = json["type"];

    switch (type) {
      case "tap":
        final x = json["x"];
        final y = json["y"];
        await adbRun(ip, ["shell", "input", "tap", "$x", "$y"]);
        break;

      case "swipe":
        await adbRun(ip, [
          "shell",
          "input",
          "swipe",
          "${json["x1"]}",
          "${json["y1"]}",
          "${json["x2"]}",
          "${json["y2"]}",
          "${json["duration"] ?? 50}",
        ]);
        break;

      case "keyevent":
        await adbRun(ip, ["shell", "input", "keyevent", json["code"]]);
        break;
    }
  }

  Future<void> _handleCommand(String ip, Socket socket, String cmd) async {
    try {
      final jsonData = jsonDecode(cmd);

      if (jsonData is Map<String, dynamic>) {
        if (jsonData["type"] == "add_new_recent_app") {
          _app_data_updates(ip, socket, jsonData);
          return;
        }

        if (jsonData["type"] == "sync_all_favorites") {
          _app_data_updates(ip, socket, jsonData);
          return;
        }

        if (jsonData["type"] == "tap" ||
            jsonData["type"] == "swipe" ||
            jsonData["type"] == "keyevent") {
          await _handleInputCommand(ip, jsonData);
          return;
        }
      }
    } catch (_) {}

    dev.log("Command received: $cmd");

    if (cmd.startsWith("req_app_audio=")) {
      final pkg = cmd.replaceAll("req_app_audio=", "");

      final String scrcpyPath = dotenv.get('SCRCPY_Shrey11_');
      final String audioFlag = dotenv.get('SCRCPY_FLAG_Shrey11_');
      final String port = dotenv.get('HiddenPort_Shrey11_');

      final ok = await SimpleAudioProcessManager.instance.start(pkg, [
        scrcpyPath,
        "-s",
        "$ip:$port",
        "$audioFlag=$pkg",
        "--no-window",
        "--audio-output-buffer=15",
        "--no-power-on",
      ]);
      _sendJson(socket, {"type": "set_app_audio", "app": pkg, "status": ok});
      return;
    }

    if (cmd == "stop_all_audio") {
      await SimpleAudioProcessManager.instance.stopAll();
      _sendJson(socket, {"type": "stop_all_audio", "status": true});
      return;
    }

    switch (cmd) {
      case "getBluetooth":
        _sendJson(socket, {
          "type": "getBluetooth",
          "status": await getBluetoothStatus(ip),
        });
        break;

      case "toggleBluetooth":
        _sendJson(socket, {
          "type": "toggleBluetooth",
          "status": await toggleBluetooth(ip),
        });
        break;

      case "getMobileData":
        _sendJson(socket, {
          "type": "getMobileData",
          "status": await getMobileStatus(ip),
        });
        break;

      case "toggleMobileData":
        _sendJson(socket, {
          "type": "toggleMobileData",
          "status": await toggleMobile(ip),
        });
        break;

      case "go home":
      case "go recent":
      case "go back":
        _sendJson(socket, {"type": cmd, "ok": true});
        break;

      default:
        dev.log("Unknown command: $cmd");
    }
  }
}

class SimpleAudioProcessManager {
  static final SimpleAudioProcessManager instance =
      SimpleAudioProcessManager._();
  SimpleAudioProcessManager._();

  Process? _proc;
  String? _pkg;

  bool get hasActive => _proc != null;
  String? get activePackage => _pkg;

  Future<bool> start(String pkg, List<String> args) async {
    if (_pkg == pkg) {
      dev.log("Audio process already running for $pkg");
      return true;
    }
    dev.log("Starting audio process for $pkg");
    if (_proc != null) {
      _proc!.kill();
      _proc = null;
      _pkg = null;
    }

    try {
      final p = await Process.start(args[0], args.sublist(1));
      _proc = p;
      _pkg = pkg;

      p.exitCode.then((_) {
        if (_pkg == pkg) {
          _proc = null;
          _pkg = null;
        }
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> stop() async {
    if (_proc == null) return false;
    _proc!.kill();
    _proc = null;
    _pkg = null;
    return true;
  }

  Future<bool> stopIf(String pkg) async {
    if (_pkg == pkg) {
      return stop();
    }
    return false;
  }

  Future<void> stopAll() async => stop();
}
