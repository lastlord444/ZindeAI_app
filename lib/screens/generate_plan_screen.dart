
import 'package:flutter/material.dart';
import '../services/plan_service.dart';
import '../services/models/plan_request.dart';
import '../widgets/meal_card.dart';
import '../widgets/week_view.dart';

class GeneratePlanScreen extends StatefulWidget {
  final PlanService? planService;
  
  const GeneratePlanScreen({
    super.key,
    this.planService,
  });

  @override
  State<GeneratePlanScreen> createState() => _GeneratePlanScreenState();
}

class _GeneratePlanScreenState extends State<GeneratePlanScreen> with SingleTickerProviderStateMixin {
  late final PlanService _planService;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _planService = widget.planService ?? PlanService();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Plan? _currentPlan; // Unused in MVP
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mock request for now, or simple default
      final request = GeneratePlanRequest(
        userId: '00000000-0000-0000-0000-000000000000', // Mock/Test User
        weekStart: DateTime.now().toIso8601String().split('T')[0], // Today YYYY-MM-DD
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Günlük'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Haftalık'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generatePlan,
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
            child: TabBarView(
              controller: _tabController,
              children: [
                // Günlük tab: Statik meal cards (demo)
                ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: const [
                     MealCard(mealName: "Yulaf Ezmesi & Yumurta", calories: "350", alternatives: ["Menemen", "Toast"]),
                     MealCard(mealName: "Izgara Tavuk Salata", calories: "450", alternatives: ["Ton Balıklı Salata", "Mercimek Çorbası"]),
                     MealCard(mealName: "Ara Öğün: Kuruyemiş", calories: "150"),
                     MealCard(mealName: "Akşam: Somon & Sebze", calories: "500", alternatives: ["Köfte & Piyaz"]),
                     MealCard(mealName: "Protein Shake", calories: "200"),
                     MealCard(mealName: "Bitki Çayı & Lor", calories: "100"),
                  ],
                ),
                // Haftalık tab: Week view with loading/empty states
                WeekView(
                  plan: null, // _currentPlan (MVP'de yok, demo için null)
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
