import 'package:flutter/material.dart';

class Badge extends StatelessWidget {
  const Badge({super.key, required this.label, this.color, this.textColor});
  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).colorScheme.secondary;
    final fg = textColor ?? Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
