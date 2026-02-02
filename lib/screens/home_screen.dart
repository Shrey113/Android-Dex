import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:android_dex/widgets/glass_card.dart';
import 'package:android_dex/services/scrcpy_service.dart';
import 'package:android_dex/services/Socke_3_Android_Dex.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _ipController = TextEditingController();
  final _scrcpyService = ScrcpyService();

  bool _isLoading = false;
  bool _isConnected = false;
  String _connectedIp = '';
  late AnimationController _pulseController;
  StreamSubscription<bool>? _statusSubscription;

  List<AdbDevice> _devices = [];
  bool _isLoadingDevices = false;
  Timer? _deviceRefreshTimer;

  bool _isServerRunning = false;
  StreamSubscription<bool>? _serverStatusSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _isServerRunning = AdbTcpServer.instance.isRunning;
    _serverStatusSubscription = AdbTcpServer.instance.statusStream.listen((
      isRunning,
    ) {
      if (mounted) {
        setState(() => _isServerRunning = isRunning);
      }
    });

    _statusSubscription = _scrcpyService.statusStream.listen((isRunning) {
      if (mounted) {
        final wasConnected = _isConnected;
        setState(() {
          _isConnected = isRunning;
          if (!isRunning) {
            _connectedIp = '';
          }
        });
        if (wasConnected && !isRunning) {
          _showSnackBar('Session ended', false);
        }
      }
    });

    _refreshDevices();
    _deviceRefreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshDevices(),
    );
  }

  @override
  void dispose() {
    _deviceRefreshTimer?.cancel();
    _statusSubscription?.cancel();
    _serverStatusSubscription?.cancel();
    _ipController.dispose();
    _pulseController.dispose();
    _scrcpyService.dispose();
    super.dispose();
  }

  Future<void> _refreshDevices() async {
    if (_isLoadingDevices) return;

    setState(() => _isLoadingDevices = true);
    final devices = await _scrcpyService.getConnectedDevices();
    if (mounted) {
      setState(() {
        _devices = devices;
        _isLoadingDevices = false;
      });
    }
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      _showSnackBar('Enter device IP address', false);
      return;
    }

    setState(() => _isLoading = true);

    if (!await _scrcpyService.checkToolsExist()) {
      _showSnackBar('Tools not found in helper folder', false);
      setState(() => _isLoading = false);
      return;
    }

    final (adbOk, adbMsg) = await _scrcpyService.connectAdb(ip);
    if (!adbOk) {
      _showSnackBar(adbMsg, false);
      setState(() => _isLoading = false);
      return;
    }

    final (scrcpyOk, _) = await _scrcpyService.startScrcpy(ip);
    if (!scrcpyOk) {
      _showSnackBar('Failed to start display', false);
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = false;
      _isConnected = true;
      _connectedIp = ip;
    });
    _showSnackBar('Connected successfully', true);
  }

  void _disconnect() {
    setState(() {
      _isConnected = false;
      _connectedIp = '';
    });
    _scrcpyService.stopScrcpy();
    _showSnackBar('Session ended', true);
  }

  Future<void> _toggleServer() async {
    if (_isServerRunning) {
      final shouldStop = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFFB74D),
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text('Stop Server?', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: const Text(
                'Stopping the server will block all DEX requests and disconnect all clients. Are you sure?',
                style: TextStyle(color: Color(0xFF8888A0), fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF8888A0)),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                  ),
                  child: const Text('Stop Server'),
                ),
              ],
            ),
      );
      if (shouldStop == true) {
        await AdbTcpServer.instance.stop();
        _showSnackBar('Server stopped', true);
      }
    } else {
      final started = await AdbTcpServer.instance.start();
      _showSnackBar(
        started ? 'Server started' : 'Failed to start server',
        started,
      );
    }
  }

  Future<void> _connectWithDevice(AdbDevice device) async {
    _ipController.text = device.address;
    await _connect();
  }

  void _showSnackBar(String msg, bool ok) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: ok ? const Color(0xFF1DB954) : const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [_buildTitleBar(), Expanded(child: _buildContent())],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.5, -0.6),
          radius: 1.5,
          colors: [Color(0xFF1A1A2E), Color(0xFF0D0D12)],
        ),
      ),
      child: CustomPaint(painter: _GridPainter(), size: Size.infinite),
    );
  }

  Widget _buildTitleBar() {
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => isDesktop ? windowManager.startDragging() : null,
      onDoubleTap: () async {
        if (isDesktop) {
          if (await windowManager.isMaximized()) {
            windowManager.unmaximize();
          } else {
            windowManager.maximize();
          }
        }
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    _isConnected
                        ? const Color(0xFF1DB954)
                        : const Color(0xFF555566),
                shape: BoxShape.circle,
                boxShadow:
                    _isConnected
                        ? [
                          BoxShadow(
                            color: const Color(
                              0xFF1DB954,
                            ).withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ]
                        : null,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isConnected ? 'Active Session' : 'Android DEX',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            if (_isConnected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _connectedIp,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1DB954),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (isDesktop) ...[
              _ServerToggleBtn(
                isRunning: _isServerRunning,
                onTap: _toggleServer,
              ),
              const SizedBox(width: 4),
              _WindowBtn(
                icon: Icons.remove,
                onTap: () => windowManager.minimize(),
              ),
              _WindowBtn(
                icon: Icons.close,
                onTap: () => windowManager.close(),
                isClose: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogo(),
              const SizedBox(height: 28),
              _buildConnectionPanel(),
              const SizedBox(height: 16),
              _buildDeviceList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.05);
            return Transform.scale(
              scale: _isConnected ? 1.0 : scale,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        _isConnected
                            ? [const Color(0xFF1DB954), const Color(0xFF1ED760)]
                            : [
                              const Color(0xFF7C4DFF),
                              const Color(0xFF00E5FF),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (_isConnected
                              ? const Color(0xFF1DB954)
                              : const Color(0xFF7C4DFF))
                          .withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  _isConnected ? Icons.cast_connected : Icons.cast,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        const Text(
          'Android DEX',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Wireless Display Extension',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionPanel() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.wifi_tethering,
                  size: 18,
                  color: Color(0xFF7C4DFF),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Connection',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Enter IP to connect',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8888A0)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ipController,
            enabled: !_isConnected && !_isLoading,
            style: const TextStyle(fontSize: 14, letterSpacing: 0.5),
            decoration: InputDecoration(
              hintText: '192.168.1.100:5555',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  Icons.lan_outlined,
                  size: 18,
                  color:
                      _isConnected
                          ? const Color(0xFF1DB954)
                          : const Color(0xFF8888A0),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              suffixIcon:
                  _isConnected
                      ? const Padding(
                        padding: EdgeInsets.only(right: 14),
                        child: Icon(
                          Icons.check_circle,
                          color: Color(0xFF1DB954),
                          size: 18,
                        ),
                      )
                      : null,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: _buildActionButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isLoading) {
      return FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A35),
          disabledBackgroundColor: const Color(0xFF2A2A35),
        ),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    if (_isConnected) {
      return FilledButton.icon(
        onPressed: _disconnect,
        icon: const Icon(Icons.stop_circle_outlined, size: 18),
        label: const Text('End Session', style: TextStyle(fontSize: 13)),
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
      );
    }

    return FilledButton.icon(
      onPressed: _connect,
      icon: const Icon(Icons.play_arrow_rounded, size: 20),
      label: const Text('Start DEX', style: TextStyle(fontSize: 13)),
      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF)),
    );
  }

  Widget _buildDeviceList() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.devices,
                  size: 18,
                  color: Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Devices',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Tap to connect',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8888A0)),
                    ),
                  ],
                ),
              ),
              if (_isLoadingDevices)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _refreshDevices,
                  icon: const Icon(Icons.refresh, size: 18),
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFF8888A0),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_devices.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    Icons.phone_android,
                    size: 32,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No devices found',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Connect via ADB wireless debugging',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_devices.length, (index) {
              final device = _devices[index];
              final isCurrentDevice = _connectedIp == device.address;

              return Padding(
                padding: EdgeInsets.only(top: index > 0 ? 8 : 0),
                child: _buildDeviceCard(device, isCurrentDevice),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(AdbDevice device, bool isCurrentDevice) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            (_isConnected || _isLoading)
                ? null
                : () => _connectWithDevice(device),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                isCurrentDevice
                    ? const Color(0xFF1DB954).withValues(alpha: 0.1)
                    : const Color(0xFF1E1E28),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isCurrentDevice
                      ? const Color(0xFF1DB954).withValues(alpha: 0.5)
                      : const Color(0xFF2A2A35),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        isCurrentDevice
                            ? [const Color(0xFF1DB954), const Color(0xFF1ED760)]
                            : [
                              const Color(0xFF2A2A35),
                              const Color(0xFF1E1E28),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.smartphone,
                  size: 18,
                  color:
                      isCurrentDevice
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isCurrentDevice
                                ? const Color(0xFF1DB954)
                                : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      device.address,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrentDevice)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF1DB954),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (!_isConnected && !_isLoading)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF1A1A2E).withValues(alpha: 0.5)
          ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WindowBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;

  const _WindowBtn({
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_WindowBtn> createState() => _WindowBtnState();
}

class _WindowBtnState extends State<_WindowBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            color:
                _hover
                    ? (widget.isClose
                        ? const Color(0xFFE53935)
                        : const Color(0xFF2A2A35))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 14,
            color: Colors.white.withValues(alpha: _hover ? 1.0 : 0.6),
          ),
        ),
      ),
    );
  }
}

class _ServerToggleBtn extends StatefulWidget {
  final bool isRunning;
  final VoidCallback onTap;

  const _ServerToggleBtn({required this.isRunning, required this.onTap});

  @override
  State<_ServerToggleBtn> createState() => _ServerToggleBtnState();
}

class _ServerToggleBtnState extends State<_ServerToggleBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          widget.isRunning
              ? 'Server Running (Click to stop)'
              : 'Server Stopped (Click to start)',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hover ? const Color(0xFF2A2A35) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  widget.isRunning ? Icons.dns : Icons.dns_outlined,
                  size: 16,
                  color:
                      widget.isRunning
                          ? const Color(0xFF1DB954)
                          : Colors.white.withValues(alpha: 0.5),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color:
                          widget.isRunning
                              ? const Color(0xFF1DB954)
                              : const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      boxShadow:
                          widget.isRunning
                              ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1DB954,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ]
                              : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
