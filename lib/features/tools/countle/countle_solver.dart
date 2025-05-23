class Item {
  final List<int> numbers;
  final String trace;
  final Set<String> used;

  Item({
    required this.numbers,
    required this.trace,
    Set<String>? used,
  }) : used = used ?? {};

  @override
  String toString() => 'Item(numbers: $numbers, trace: $trace)';
}

class CountleSolver {
  List<String> solutions = [];
  final int maxSolutions = 100;
  final int maxIterations = 5000000;
  int iterations = 0;

  String _formatOperation(int left, String op, int right, int result) {
    return '$left$op$right=$result';
  }

  void solve(List<int> numbers, int target) {
    solutions.clear();
    iterations = 0;
    _calculate([Item(numbers: numbers, trace: "")], target);
  }

  void _calculate(List<Item> items, int target) {
    var queue = List<Item>.from(items);
    var seen = <String>{};
    
    while (queue.isNotEmpty && solutions.length < maxSolutions && iterations < maxIterations) {
      iterations++;
      final item = queue.removeAt(0);
      
      if (item.numbers.reduce((a, b) => a * b) < target) continue;
      
      if (item.numbers.length == 1) {
        if (item.numbers[0] == target) {
          final solution = item.trace.trim();
          if (!solutions.contains(solution)) {
            solutions.add(solution);
            if (solutions.length >= maxSolutions) break;
          }
        }
        continue;
      }

      final sortedNumbers = List<int>.from(item.numbers)..sort();
      final key = sortedNumbers.join(',');
      if (seen.contains(key)) continue;
      seen.add(key);
      
      final newNumbers = List<int>.from(item.numbers)..sort((a, b) => b.compareTo(a));
      queue.insertAll(0, _calculateOne(Item(
        numbers: newNumbers,
        trace: item.trace,
        used: item.used,
      )));
    }
  }

  List<Item> _calculateOne(Item item) {
    var result = <Item>[];
    final numbers = item.numbers;

    for (var i = 0; i < numbers.length; i++) {
      for (var j = i + 1; j < numbers.length; j++) {
        final left = numbers[i];
        final right = numbers[j];
        
        var remaining = List<int>.from(numbers);
        remaining.removeAt(j);
        remaining.removeAt(i);

        // Addition
        final sum = left + right;
        result.add(Item(
          numbers: [sum, ...remaining],
          trace: "${item.trace} ${_formatOperation(left, '+', right, sum)}",
          used: item.used,
        ));

        // Multiplication
        if (left != 1 && right != 1) {
          final product = left * right;
          result.add(Item(
            numbers: [product, ...remaining],
            trace: "${item.trace} ${_formatOperation(left, '×', right, product)}",
            used: item.used,
          ));
        }

        // Subtraction (both directions)
        if (left > right) {
          final diff = left - right;
          result.add(Item(
            numbers: [diff, ...remaining],
            trace: "${item.trace} ${_formatOperation(left, '-', right, diff)}",
            used: item.used,
          ));
        } else if (right > left) {
          final diff = right - left;
          result.add(Item(
            numbers: [diff, ...remaining],
            trace: "${item.trace} ${_formatOperation(right, '-', left, diff)}",
            used: item.used,
          ));
        }

        // Division (both directions if possible)
        if (right != 0 && left % right == 0) {
          final quotient = left ~/ right;
          result.add(Item(
            numbers: [quotient, ...remaining],
            trace: "${item.trace} ${_formatOperation(left, '÷', right, quotient)}",
            used: item.used,
          ));
        }
        if (left != 0 && right % left == 0) {
          final quotient = right ~/ left;
          result.add(Item(
            numbers: [quotient, ...remaining],
            trace: "${item.trace} ${_formatOperation(right, '÷', left, quotient)}",
            used: item.used,
          ));
        }
      }
    }

    return result;
  }
} 