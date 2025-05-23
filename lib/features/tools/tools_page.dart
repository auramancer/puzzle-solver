import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'countle/countle_solver_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _tools.length,
        itemBuilder: (context, index) {
          final tool = _tools[index];
          return Card(
            child: InkWell(
              onTap: () {
                if (tool.name == 'Countle Solver') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CountleSolverPage(),
                    ),
                  );
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tool.icon,
                    size: 48,
                  ).animate().scale(),
                  const SizedBox(height: 16),
                  Text(
                    tool.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tool.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
        },
      ),
    );
  }
}

class Tool {
  final String name;
  final String description;
  final IconData icon;

  const Tool({
    required this.name,
    required this.description,
    required this.icon,
  });
}

final _tools = [
  const Tool(
    name: 'Countle Solver',
    description: 'Solve daily Countle puzzles',
    icon: Icons.calculate,
  ),
  const Tool(
    name: 'JSON Formatter',
    description: 'Format and validate JSON data',
    icon: Icons.data_object,
  ),
  const Tool(
    name: 'Color Picker',
    description: 'Pick and convert colors',
    icon: Icons.color_lens,
  ),
  const Tool(
    name: 'Base64',
    description: 'Encode/decode Base64 strings',
    icon: Icons.code,
  ),
  const Tool(
    name: 'Hash Generator',
    description: 'Generate various hash types',
    icon: Icons.tag,
  ),
  const Tool(
    name: 'URL Encoder',
    description: 'Encode/decode URLs',
    icon: Icons.link,
  ),
  const Tool(
    name: 'Text Diff',
    description: 'Compare text differences',
    icon: Icons.compare_arrows,
  ),
]; 