import 'package:flutter_test/flutter_test.dart';
import 'countle_solver.dart';

void main() {
  late CountleSolver solver;

  setUp(() {
    solver = CountleSolver();
  });

  test('Simple test case: [2,3,5,10] target 20', () {
    solver.solve([2, 3, 5, 10], 20);
    expect(solver.solutions.isNotEmpty, true);
    print('Solutions for 20:');
    for (var solution in solver.solutions) {
      print(solution);
    }
  });

  test('Test case 1: [4,7,8,25,50,75] target 886', () {
    solver.solve([4, 7, 8, 25, 50, 75], 886);
    expect(solver.solutions.isNotEmpty, true);
    print('Solutions for 886:');
    for (var solution in solver.solutions) {
      print(solution);
    }
  });

  test('Test case 2: [3,3,7,8,10,75] target 359', () {
    solver.solve([3, 3, 7, 8, 10, 75], 359);
    expect(solver.solutions.isNotEmpty, true);
    print('Solutions for 359:');
    for (var solution in solver.solutions) {
      print(solution);
    }
  });

  test('Test case 3: [8,8,8,8,8,8] target 999 (impossible)', () {
    solver.solve([8, 8, 8, 8, 8, 8], 999);
    expect(solver.solutions.isEmpty, true, reason: 'Should have no solutions as 999 is impossible to reach with six 8s');
    print('Solutions for 999 (should be empty):');
    for (var solution in solver.solutions) {
      print(solution);
    }
  });
} 