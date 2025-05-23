import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'countle_solver.dart';

class CountleSolverPage extends StatefulWidget {
  const CountleSolverPage({super.key});

  @override
  State<CountleSolverPage> createState() => _CountleSolverPageState();
}

class _CountleSolverPageState extends State<CountleSolverPage> {
  final targetController = TextEditingController();
  final List<TextEditingController> numberControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final targetFocusNode = FocusNode();
  final List<FocusNode> numberFocusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  final _solver = CountleSolver();
  List<String> _solutions = [];
  bool _isSolving = false;
  bool _areInputsValid = false;
  bool _hasSolved = false;
  Map<String, String> _lastSolvedValues = {};

  @override
  void initState() {
    super.initState();
    // Add listeners to all controllers to validate input
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
    targetFocusNode.dispose();
    for (var node in numberFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool _haveInputsChanged() {
    if (!_hasSolved) return true;
    
    if (_lastSolvedValues['target'] != targetController.text) return true;
    
    for (var i = 0; i < numberControllers.length; i++) {
      if (_lastSolvedValues['number$i'] != numberControllers[i].text) return true;
    }
    
    return false;
  }

  void _validateInputs() {
    final target = int.tryParse(targetController.text);
    if (target == null) {
      setState(() => _areInputsValid = false);
      return;
    }

    final numbers = numberControllers
        .map((controller) => int.tryParse(controller.text))
        .toList();
    
    final hasValidNumbers = !numbers.contains(null) && numbers.every((n) => n != null);
    final inputsChanged = _haveInputsChanged();
    
    setState(() => _areInputsValid = hasValidNumbers && inputsChanged);
  }

  void _saveCurrentValues() {
    _lastSolvedValues = {
      'target': targetController.text,
      for (var i = 0; i < numberControllers.length; i++)
        'number$i': numberControllers[i].text,
    };
  }

  void _onNumberSubmitted(int index) {
    if (index < numberFocusNodes.length - 1) {
      numberFocusNodes[index + 1].requestFocus();
    } else {
      numberFocusNodes[index].unfocus();
      if (_areInputsValid) {
        _solve();
      }
    }
  }

  Future<void> _solve() async {
    if (!_areInputsValid) return;

    setState(() {
      _isSolving = true;
      _solutions = [];
    });

    await Future.microtask(() {
      final target = int.parse(targetController.text);
      final numbers = numberControllers
          .map((controller) => int.parse(controller.text))
          .toList();

      _solver.solve(numbers, target);
      
      setState(() {
        _solutions = _solver.solutions;
        _isSolving = false;
        _hasSolved = true;
        _saveCurrentValues();
        _validateInputs();
      });
    });
  }

  Widget _buildNumberBox({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isTarget,
    void Function(String)? onSubmitted,
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
            focusNode: focusNode,
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
            onSubmitted: onSubmitted,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  focusNode: targetFocusNode,
                  isTarget: true,
                  onSubmitted: (_) => numberFocusNodes.first.requestFocus(),
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
                        focusNode: numberFocusNodes[index],
                        isTarget: false,
                        onSubmitted: (_) => _onNumberSubmitted(index),
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
                    onPressed: (_isSolving || !_areInputsValid) ? null : _solve,
                    icon: _isSolving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.calculate),
                    label: Text(_isSolving ? 'Solving...' : 'Solve'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: const Color(0xFF4267B2),
                      foregroundColor: Colors.white,
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 800)),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    color: _solutions.isEmpty && _hasSolved
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
                              if (_isSolving) ...[
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
                          if (_isSolving)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  'Calculating solutions...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          else if (_solutions.isEmpty)
                            Text(
                              'No solutions found',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _solutions
                                  .map(
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
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 1000)),
            ],
          ),
        ),
      ),
    );
  }
} 