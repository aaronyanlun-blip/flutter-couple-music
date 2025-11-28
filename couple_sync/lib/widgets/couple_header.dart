import 'package:flutter/material.dart';

class CoupleHeader extends StatelessWidget {
  final String partner1Name;
  final String partner2Name;
  final String partner1Image; // URL or asset path
  final String partner2Image; // URL or asset path

  const CoupleHeader({
    Key? key,
    required this.partner1Name,
    required this.partner2Name,
    required this.partner1Image,
    required this.partner2Image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pinkAccent, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Partner 1 image
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(partner1Image),
          ),
          const SizedBox(width: 12),
          // Names in column
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                partner1Name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                "&",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              Text(
                partner2Name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Partner 2 image
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(partner2Image),
          ),
        ],
      ),
    );
  }
}
