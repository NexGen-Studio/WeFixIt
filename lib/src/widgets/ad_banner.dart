import 'package:flutter/material.dart';

// Platzhalter für AdMob Banner (320x50). Für Free-User sichtbar.
class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Text(
        'AdMob Banner (Platzhalter)',
        style: TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }
}
