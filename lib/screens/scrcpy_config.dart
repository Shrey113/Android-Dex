import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_dex/widgets/glass_card.dart';

class ScrcpyConfigScreen extends StatefulWidget {
  const ScrcpyConfigScreen({super.key});

  @override
  State<ScrcpyConfigScreen> createState() => _ScrcpyConfigScreenState();
}

class _ScrcpyConfigScreenState extends State<ScrcpyConfigScreen> {
  int _fps = 60;
  String _codec = 'h264';
  bool _noDestroyContent = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fps = prefs.getInt('scrcpy.fps') ?? 60;
      _codec = prefs.getString('scrcpy.codec') ?? 'h264';
      _noDestroyContent =
          prefs.getBool('scrcpy.no_vd_destroy_content') ?? false;
      _loading = false;
    });
  }

  Future<void> _setFps(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('scrcpy.fps', v);
    setState(() => _fps = v);
  }

  Future<void> _setCodec(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('scrcpy.codec', v);
    setState(() => _codec = v);
  }

  Future<void> _setNoDestroyContent(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('scrcpy.no_vd_destroy_content', v);
    setState(() => _noDestroyContent = v);
  }

  String _buildCommand() {
    final base = [
      'scrcpy',
      '--new-display=1920x1080/280',
      '--no-audio',
      '--start-app=com.example.androiddex',
      '--no-vd-system-decorations',
      '-f',
      '--shortcut-mod=lctrl',
    ];
    final extra = <String>[];
    if (_fps > 0) extra.add('--max-fps=$_fps');
    if (_codec.isNotEmpty) extra.add('--video-codec=$_codec');
    if (_noDestroyContent) extra.add('--no-vd-destroy-content');
    return [...base, ...extra].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: Text('Loading...')));
    }
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Scrcpy Config',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Max FPS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Dropdown<int>(
                      value: _fps,
                      items: const [30, 60, 90, 120],
                      itemToText: (v) => '$v',
                      onChanged: (v) => _setFps(v),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Video Codec',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Dropdown<String>(
                      value: _codec,
                      items: const ['h264', 'h265'],
                      itemToText: (v) => v,
                      onChanged: (v) => _setCodec(v),
                    ),
                    const SizedBox(height: 16),
                    _AnimatedSwitch(
                      value: _noDestroyContent,
                      onChanged: (v) => _setNoDestroyContent(v),
                      title: 'Add --no-vd-destroy-content',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Command Preview',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E28),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF2A2A35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _buildCommand(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Color(0xFFE8E8E8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _buildCommand()),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) itemToText;
  final void Function(T) onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.itemToText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A35), width: 1),
      ),
      child: DropdownButton<T>(
        value: value,
        items:
            items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      itemToText(e),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                )
                .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        isExpanded: true,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(12),
        dropdownColor: const Color(0xFF1E1E28),
      ),
    );
  }
}

class _AnimatedSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;

  const _AnimatedSwitch({
    required this.value,
    required this.onChanged,
    required this.title,
  });

  @override
  State<_AnimatedSwitch> createState() => _AnimatedSwitchState();
}

class _AnimatedSwitchState extends State<_AnimatedSwitch> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF7C4DFF);
    final inactiveColor = const Color(0xFF2A2A35);
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: () => widget.onChanged(!widget.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 48,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color:
                  widget.value
                      ? activeColor.withValues(alpha: 0.25)
                      : inactiveColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.value ? activeColor : const Color(0xFF2A2A35),
                width: 1,
              ),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment:
                  widget.value ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: _pressed ? 18 : 16,
                height: _pressed ? 18 : 16,
                decoration: BoxDecoration(
                  color: widget.value ? activeColor : const Color(0xFFE8E8E8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.value
                              ? activeColor
                              : const Color(0xFF000000))
                          .withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
