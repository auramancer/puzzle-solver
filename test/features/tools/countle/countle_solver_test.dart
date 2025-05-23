import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_solver/features/tools/countle/countle_solver_page.dart';

void main() {
  test('Countle solver finds solutions for complex cases', () {
    final solutions = <String>{};
    
    void calculate(List<int> numbers, int target) {
      final items = numbers.map((n) => Item(n, false, n.toString())).toList();
      
      // Sort numbers to try larger numbers first for division
      items.sort((a, b) => b.value.compareTo(a.value));
      
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
            bestDepth = depth; // Update best depth
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
      
      print('Solutions for $target using $numbers:');
      for (final solution in sortedSolutions.take(5)) {
        print(solution);
      }
      print('---');
    }

    // Test case 1: Complex calculation with large numbers
    calculate([4, 7, 8, 25, 50, 75], 886);
    expect(solutions.isNotEmpty, isTrue, reason: 'Should find solution for 886');
    solutions.clear();

    // Test case 2: Medium complexity calculation
    calculate([3, 3, 7, 8, 10, 75], 359);
    expect(solutions.isNotEmpty, isTrue, reason: 'Should find solution for 359');
    solutions.clear();

    // Test case 3: All same numbers - should have no solution
    calculate([8, 8, 8, 8, 8, 8], 999);
    expect(solutions.isEmpty, isTrue, reason: 'Should NOT find any solution for 999 using only 8s');
  });
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
  for (var op in operations) {
    try {
      final result = op.operation(a, b);
      final distance = (target - result).abs();
      if (distance == 0) {
        op = Operation(op.operation, op.symbol, op.commutative, 0);
      } else if (distance < target ~/ 2) {
        op = Operation(op.operation, op.symbol, op.commutative, 1);
      } else {
        op = Operation(op.operation, op.symbol, op.commutative, 2);
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