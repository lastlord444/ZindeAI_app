import 'package:flutter/material.dart';
import '../services/plan_service.dart';
import '../services/models/plan_request.dart';
import '../widgets/meal_card.dart';

class GeneratePlanScreen extends StatefulWidget {
  final PlanService? planService;

  const GeneratePlanScreen({
    super.key,
    this.planService,
  });

  @override
  State<GeneratePlanScreen> createState() => _GeneratePlanScreenState();
}

class _GeneratePlanScreenState extends State<GeneratePlanScreen> {
  late final PlanService _planService;

  @override
  void initState() {
    super.initState();
    _planService = widget.planService ?? PlanService();
  }

  // Plan? _currentPlan; // Unused in MVP
  bool _isLoading = false;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _planService = widget.planService ?? PlanService();
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mock request for now, or simple default
      final request = GeneratePlanRequest(
        userId: '00000000-0000-0000-0000-000000000000', // Mock/Test User
        weekStart:
            DateTime.now().toIso8601String().split('T')[0], // Today YYYY-MM-DD
        goalTag: 'cut',
        budgetMode: 'medium', // Default
      );

      await _planService.generatePlan(request);

      setState(() {
        // _currentPlan = plan; // Unused in MVP
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Plan oluşturulurken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZindeAI Planlayıcı'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tariff Selector removed for MVP
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generatePlan,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: Text(_isLoading ? 'Oluşturuluyor...' : 'Plan Oluştur'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _allMealTypes.length,
              itemBuilder: (context, index) {
                final type = _allMealTypes[index];
                final isActive = _activeMeals.contains(type);
                final data = _mockMealData[type];

                return MealCard(
                  mealName: data['name'],
                  calories: data['kcal'],
                  alternatives: List<String>.from(data['alts']),
                  isActive: isActive,
                  onToggleActive: () {
                    setState(() {
                      if (isActive) {
                        _activeMeals.remove(type);
                      } else {
                        _activeMeals.add(type);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
