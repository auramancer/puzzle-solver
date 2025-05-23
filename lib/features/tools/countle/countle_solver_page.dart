import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Item {
  final int value;
  final bool used;
  final String expression;

  Item(this.value, this.used, this.expression);

  Item copyWith({int? value, bool? used, String? expression}) {
    return Item(
      value ?? this.value,
      used ?? this.used,
      expression ?? this.expression,
    );
  }
}

// Helper class for operations
class Operation {
  final int Function(int a, int b) operation;
  final String symbol;
  final bool commutative;
  final int priority;

  Operation(this.operation, this.symbol, this.commutative, this.priority);
}

// Prioritize operations based on target and current numbers
List<Operation> _prioritizeOperations(int a, int b, int target) {
  final operations = [
    Operation((a, b) => a * b, '*', true, 0),
    Operation((a, b) => a + b, '+', true, 0),
    Operation((a, b) => a - b, '-', false, 0),
    if (b != 0) Operation((a, b) => a ~/ b, '/', false, 0),
  ];

  // Assign priorities based on how close the result gets to target
  for (var i = 0; i < operations.length; i++) {
    try {
      final result = operations[i].operation(a, b);
      final distance = (target - result).abs();
      if (distance == 0) {
        operations[i] = Operation(operations[i].operation, operations[i].symbol, operations[i].commutative, 0);
      } else if (distance < target ~/ 2) {
        operations[i] = Operation(operations[i].operation, operations[i].symbol, operations[i].commutative, 1);
      } else {
        operations[i] = Operation(operations[i].operation, operations[i].symbol, operations[i].commutative, 2);
      }
    } catch (_) {}
  }

  // Sort operations by priority (lower is better)
  operations.sort((a, b) => a.priority.compareTo(b.priority));
  return operations;
}

// Check if a result is making progress towards the target
bool _isProgressTowardsTarget(int result, int target) {
  final ratio = result / target;
  // Allow results that are within reasonable range of the target
  return ratio >= 0.1 && ratio <= 10;
}

final countleSolutionsProvider = StateProvider<List<String>>((ref) => []);

class CountleSolverPage extends ConsumerStatefulWidget {
  const CountleSolverPage({super.key});

  @override
  ConsumerState<CountleSolverPage> createState() => _CountleSolverPageState();
}

class _CountleSolverPageState extends ConsumerState<CountleSolverPage> {
  final targetController = TextEditingController();
  final List<TextEditingController> numberControllers =
      List.generate(6, (index) => TextEditingController());
  
  bool isCalculating = false;
  bool _hasSolved = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to validate input
    targetController.addListener(_validateInputs);
    for (var controller in numberControllers) {
      controller.addListener(_validateInputs);
    }
  }

  @override
  void dispose() {
    targetController.removeListener(_validateInputs);
    for (var controller in numberControllers) {
      controller.removeListener(_validateInputs);
      controller.dispose();
    }
    targetController.dispose();
    super.dispose();
  }

  bool get _areInputsValid {
    if (targetController.text.isEmpty) return false;
    final target = int.tryParse(targetController.text);
    if (target == null) return false;

    final validNumbers = numberControllers
        .map((c) => int.tryParse(c.text))
        .where((n) => n != null)
        .length;

    return validNumbers == 6;
  }

  void _validateInputs() {
    setState(() {
      // Just to trigger a rebuild
    });
  }

  void solve() {
    if (!_areInputsValid) return;

    final target = int.parse(targetController.text);
    final numbers = numberControllers
        .map((c) => int.tryParse(c.text))
        .where((n) => n != null)
        .map((n) => n!)
        .toList();

    setState(() {
      isCalculating = true;
      _hasSolved = false;
    });

    // Convert numbers to items
    final items = numbers.map((n) => Item(n, false, n.toString())).toList();
    // Sort numbers to try larger numbers first for division
    items.sort((a, b) => b.value.compareTo(a.value));
    
    final solutions = <String>{};
    int bestDepth = 10; // Track the shortest solution found

    void findSolutions(List<Item> items, int target, {int depth = 0, List<String> steps = const []}) {
      // Prune if we've exceeded the best solution depth
      if (depth >= bestDepth || depth > 5 || solutions.length >= 5) return;

      // Try single numbers first
      for (var i = 0; i < items.length; i++) {
        if (items[i].used) continue;
        final a = items[i];

        if (a.value == target) {
          if (steps.isEmpty) {
            solutions.add(a.expression);
          } else {
            solutions.add([...steps, '${a.expression}=${target}'].join(', '));
          }
          bestDepth = depth;
          return;
        }
      }

      // Try operations that are more likely to reach the target first
      for (var i = 0; i < items.length; i++) {
        if (items[i].used) continue;
        final a = items[i];

        for (var j = 0; j < items.length; j++) {
          if (i == j || items[j].used) continue;
          final b = items[j];

          // Define operation priority based on target
          final operations = _prioritizeOperations(a.value, b.value, target);
          
          for (final op in operations) {
            try {
              final result = op.operation(a.value, b.value);
              // Skip if result is not making progress towards target
              if (result < 0 || result > target * 2 || !_isProgressTowardsTarget(result, target)) continue;
              
              final step = '${a.expression}${op.symbol}${b.expression}=${result}';
              final newSteps = [...steps, step];
              
              if (result == target) {
                solutions.add(newSteps.join(', '));
                bestDepth = depth;
                return;
              }
              
              final newItems = [...items];
              newItems[i] = Item(result, false, result.toString());
              newItems[j] = b.copyWith(used: true);
              
              findSolutions(newItems, target, depth: depth + 1, steps: newSteps);

              // Try reverse order only for non-commutative operations
              if (!op.commutative && solutions.length < 5) {
                try {
                  final reverseResult = op.operation(b.value, a.value);
                  if (reverseResult < 0 || reverseResult > target * 2 || !_isProgressTowardsTarget(reverseResult, target)) continue;
                  
                  final reverseStep = '${b.expression}${op.symbol}${a.expression}=${reverseResult}';
                  final reverseSteps = [...steps, reverseStep];
                  
                  if (reverseResult == target) {
                    solutions.add(reverseSteps.join(', '));
                    bestDepth = depth;
                    return;
                  }
                  
                  final reverseItems = [...items];
                  reverseItems[j] = Item(reverseResult, false, reverseResult.toString());
                  reverseItems[i] = a.copyWith(used: true);
                  
                  findSolutions(reverseItems, target, depth: depth + 1, steps: reverseSteps);
                } catch (e) {
                  // Skip invalid reverse operations
                }
              }
            } catch (e) {
              // Skip invalid operations
            }
          }
        }
      }
    }

    findSolutions(items, target);
    
    // Sort solutions by number of steps
    final sortedSolutions = solutions.toList()
      ..sort((a, b) => a.split(',').length.compareTo(b.split(',').length));

    ref.read(countleSolutionsProvider.notifier).state = sortedSolutions;
    setState(() {
      isCalculating = false;
      _hasSolved = true;
    });
  }

  Widget _buildNumberBox({
    required TextEditingController controller,
    required bool isTarget,
  }) {
    return Container(
      width: isTarget ? 200 : 80,
      height: isTarget ? 120 : 80,
      decoration: BoxDecoration(
        color: const Color(0xFF4267B2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Colors.white,
              selectionColor: Colors.white24,
              selectionHandleColor: Colors.white,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTarget ? 48 : 32,
              fontWeight: FontWeight.bold,
            ),
            cursorColor: Colors.white,
            cursorWidth: 2,
            maxLength: 3,
            decoration: InputDecoration(
              counter: const SizedBox.shrink(),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: isTarget ? 32 : 16,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final solutions = ref.watch(countleSolutionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Countle Solver'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: _buildNumberBox(
                  controller: targetController,
                  isTarget: true,
                ).animate().fadeIn().scale(),
              ),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      6,
                      (index) => _buildNumberBox(
                        controller: numberControllers[index],
                        isTarget: false,
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: 100 * index),
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ElevatedButton.icon(
                    onPressed: _areInputsValid && !isCalculating ? solve : null,
                    icon: isCalculating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.calculate),
                    label: Text(isCalculating ? 'Solving...' : 'Solve'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: const Color(0xFF4267B2),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF4267B2).withOpacity(0.6),
                      disabledForegroundColor: Colors.white.withOpacity(0.6),
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 800)),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    color: solutions.isEmpty && _hasSolved
                        ? Colors.red.shade700
                        : const Color(0xFF4267B2),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Solutions:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (isCalculating) ...[
                                const SizedBox(width: 16),
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (isCalculating)
                            const Text(
                              'Calculating solutions...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else if (_hasSolved && solutions.isEmpty)
                            const Text(
                              'No solutions found',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                              ),
                            )
                          else if (!_hasSolved)
                            Text(
                              'Enter numbers and click solve',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            )
                          else
                            ...solutions.map(
                              (solution) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  solution,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 1000)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 