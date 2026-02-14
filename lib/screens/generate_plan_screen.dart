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

class _GeneratePlanScreenState extends State<GeneratePlanScreen>
    with SingleTickerProviderStateMixin {
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

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = GeneratePlanRequest(
        userId: '00000000-0000-0000-0000-000000000000',
        weekStart: DateTime.now().toIso8601String().split('T')[0],
        goalTag: 'cut',
        budgetMode: 'medium',
      );

      await _planService.generatePlan(request);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
          // Plan oluştur butonu — sadece kendi state'ini etkiler
          _PlanGenerateButton(
            isLoading: _isLoading,
            onPressed: _generatePlan,
          ),
          // Hata mesajı (sadece hata varken rebuild)
          if (_errorMessage != null)
            _ErrorCard(message: _errorMessage!),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Günlük tab: Statik meal cards (const, rebuild yok)
                const _DailyMealList(),
                // Haftalık tab: Week view with loading/empty states
                WeekView(
                  plan: null,
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

/// Plan oluştur butonu — izole widget, parent rebuild'lerden korunur.
class _PlanGenerateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _PlanGenerateButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(isLoading ? 'Oluşturuluyor...' : 'Plan Oluştur'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

/// Hata kartı — izole widget.
class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            message,
            style: TextStyle(color: Colors.red.shade900),
          ),
        ),
      ),
    );
  }
}

/// Günlük öğün listesi — tamamen const, rebuild YOK.
class _DailyMealList extends StatelessWidget {
  const _DailyMealList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: const [
        MealCard(
          mealName: 'Yulaf Ezmesi & Yumurta',
          calories: '350',
          alternatives: ['Menemen', 'Toast'],
        ),
        MealCard(
          mealName: 'Izgara Tavuk Salata',
          calories: '450',
          alternatives: ['Ton Balıklı Salata', 'Mercimek Çorbası'],
        ),
        MealCard(
          mealName: 'Ara Öğün: Kuruyemiş',
          calories: '150',
        ),
        MealCard(
          mealName: 'Akşam: Somon & Sebze',
          calories: '500',
          alternatives: ['Köfte & Piyaz'],
        ),
        MealCard(
          mealName: 'Protein Shake',
          calories: '200',
        ),
        MealCard(
          mealName: 'Bitki Çayı & Lor',
          calories: '100',
        ),
      ],
    );
  }
}
