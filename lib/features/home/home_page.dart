import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FFStudio Tools'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.handyman_outlined,
              size: 64,
            )
                .animate()
                .scale(duration: const Duration(milliseconds: 500))
                .then()
                .shake(),
            const SizedBox(height: 24),
            Text(
              'Welcome to FFStudio Tools',
              style: Theme.of(context).textTheme.headlineMedium,
            )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 500))
                .slideY(begin: 0.2),
            const SizedBox(height: 16),
            Text(
              'Your Swiss Army Knife for Development',
              style: Theme.of(context).textTheme.bodyLarge,
            )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 500))
                .slideY(begin: 0.2),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/tools'),
              icon: const Icon(Icons.build),
              label: const Text('Explore Tools'),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 300))
                .scale(delay: const Duration(milliseconds: 300)),
          ],
        ),
      ),
    );
  }
} 