import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const gradient_colors = [
  Color.fromARGB(255, 10, 10, 10),
  Color.fromARGB(255, 85, 85, 85),
  Color.fromARGB(255, 30, 30, 30),
];

class GithubLogButton extends StatefulWidget {
  final bool is_small;
  const GithubLogButton({super.key, this.is_small = false});

  @override
  _GithubLogButtonState createState() => _GithubLogButtonState();
}

class _GithubLogButtonState extends State<GithubLogButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double iconSize = widget.is_small ? 20 : 22;
    final double fontSize = widget.is_small ? 12 : 14;
    final double horizontalPadding = widget.is_small ? 11 : 12;
    final double verticalPadding = widget.is_small ? 7 : 8;
    final double verticalMargin = widget.is_small ? 5 : 6;
    final double borderRadius = widget.is_small ? 20 : 22;
    final double spacingWidth = widget.is_small ? 7 : 8;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          launchUrl(Uri.parse('https://github.com/shrey113'));
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(vertical: verticalMargin),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient_colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: GradientRotation(_controller.value * 2 * 3.14159),
                ),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      0.2 + 0.1 * _controller.value.abs(),
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      FontAwesomeIcons.github,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: spacingWidth),
                  Text(
                    "shrey113",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
