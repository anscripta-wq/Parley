import 'package:flutter/material.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spoken Practice')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.record_voice_over, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Text('Live Spoken Practice', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                'Live WebRTC voice & video rooms will be wired up in Milestone 4.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
