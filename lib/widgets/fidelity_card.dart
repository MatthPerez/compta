import 'dart:math';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

class FidelityCard extends StatelessWidget {
  final String number;
  final String title;

  const FidelityCard({super.key, required this.number, required this.title});

  Color _randomDarkColor() {
    final random = Random();

    return Color.fromARGB(
      255,
      random.nextInt(100),
      random.nextInt(100),
      random.nextInt(100),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _randomDarkColor();

    return InkWell(
      borderRadius: BorderRadius.circular(20),

      onTap: () {
        _showCardModal(context, color);
      },

      child: Container(
        width: MediaQuery.of(context).size.width * 0.48,

        decoration: BoxDecoration(
          color: color,

          borderRadius: BorderRadius.circular(20),

          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, 4),
              color: Colors.black26,
            ),
          ],
        ),

        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Text(
              title,

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCardModal(BuildContext context, Color color) {
    showDialog(
      context: context,

      builder: (context) {
        return Dialog(
          backgroundColor: color,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),

          child: Container(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                Text(
                  title,

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 32),

                Container(
                  color: Colors.white,

                  padding: const EdgeInsets.all(16),

                  child: BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: number,
                    width: 250,
                    height: 100,
                    drawText: true,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
