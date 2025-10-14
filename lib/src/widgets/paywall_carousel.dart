import 'package:flutter/material.dart';

class PaywallCarousel extends StatelessWidget {
  const PaywallCarousel({super.key, this.items = const []});
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _placeholder(context);
    }
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.86),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: items[index],
          );
        },
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final cards = List.generate(3, (i) => _PaywallCardPlaceholder(index: i + 1));
    return PaywallCarousel(items: cards);
  }
}

class _PaywallCardPlaceholder extends StatelessWidget {
  const _PaywallCardPlaceholder({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2F2F2F),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vorteil $index', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Kurzer Text zum Vorteil der Pro-Version.', style: TextStyle(color: Colors.white70)),
          const Spacer(),
          Row(
            children: const [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 6),
              Text('Pro', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}
