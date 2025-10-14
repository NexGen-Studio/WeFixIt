import 'package:flutter/material.dart';

// Platzhalter für AdMob Banner. Für Free-User sichtbar.
// Unterstützte Größen: 320x50 (Banner), 300x250 (Medium Rectangle)
enum AdPlaceholderSize { banner320x50, mrec300x250 }

class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({super.key, this.size = AdPlaceholderSize.banner320x50});
  final AdPlaceholderSize size;

  @override
  Widget build(BuildContext context) {
    final sizePx = _resolveSize(size);
    return SizedBox(
      width: sizePx.width,
      height: sizePx.height,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          _labelFor(size),
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ),
    );
  }

  Size _resolveSize(AdPlaceholderSize s) {
    switch (s) {
      case AdPlaceholderSize.banner320x50:
        return const Size(320, 50);
      case AdPlaceholderSize.mrec300x250:
        return const Size(300, 250);
    }
  }

  String _labelFor(AdPlaceholderSize s) {
    switch (s) {
      case AdPlaceholderSize.banner320x50:
        return 'AdMob 320x50 (Platzhalter)';
      case AdPlaceholderSize.mrec300x250:
        return 'AdMob 300x250 (Platzhalter)';
    }
  }
}
