import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/macro_calculator.dart';
import '../services/local_plan_generator.dart';
import '../services/tolerance_validator.dart';

/// Plan oluşturma ekranı — local plan generator ile çalışır (network YOK).
class GeneratePlanScreen extends StatefulWidget {
  final UserProfile? profile;

  const GeneratePlanScreen({super.key, this.profile});

  @override
  State<GeneratePlanScreen> createState() => _GeneratePlanScreenState();
}

class _GeneratePlanScreenState extends State<GeneratePlanScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _generator = LocalPlanGenerator();
  final _calculator = const MacroCalculator();

  bool _isLoading = false;
  String? _errorMessage;
  PlanGenerationResult? _result;
  MacroTargets? _targets;

  UserProfile get _profile =>
      widget.profile ??
      const UserProfile(
        userId: 'demo',
        age: 25,
        heightCm: 175,
        weightKg: 70,
        gender: Gender.male,
        activityLevel: ActivityLevel.moderate,
        goal: GoalType.cut,
        experience: ExperienceLevel.intermediate,
      );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _targets = _calculator.calculate(_profile);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Local plan üretimi — network YOK
    await Future.delayed(const Duration(milliseconds: 300)); // UI feedback

    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final result = _generator.generateDayPlan(
      profile: _profile,
      date: dateStr,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _result = result;
      if (!result.success) {
        _errorMessage = result.errorMessage;
      }
    });
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
            Tab(icon: Icon(Icons.today), text: 'Günlük Plan'),
            Tab(icon: Icon(Icons.info_outline), text: 'Tolerans'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Profil özeti
          if (_targets != null) _ProfileSummaryBar(targets: _targets!, goal: _profile.goal),
          // Plan oluştur butonu
          _PlanGenerateButton(
            isLoading: _isLoading,
            onPressed: _generatePlan,
          ),
          // Hata mesajı
          if (_errorMessage != null) _ErrorCard(message: _errorMessage!),
          // Tab içerikleri
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Günlük plan
                _result?.success == true
                    ? _DayPlanView(plan: _result!.plan!, targets: _targets!)
                    : const Center(
                        child: Text(
                          'Plan oluşturmak için butona basın',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                // Tolerans tab
                _result?.toleranceResult != null
                    ? _ToleranceView(
                        result: _result!.toleranceResult!,
                        attempts: _result!.attempts,
                        adjustments: _result!.adjustments,
                      )
                    : const Center(
                        child: Text(
                          'Tolerans bilgisi plan oluşturulduktan sonra gösterilir',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Profil özet barı — hedef kcal ve makrolar.
class _ProfileSummaryBar extends StatelessWidget {
  final MacroTargets targets;
  final GoalType goal;

  const _ProfileSummaryBar({required this.targets, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _chip('${targets.targetKcal.round()} kcal', Colors.green),
          _chip('P: ${targets.proteinG.round()}g', Colors.blue),
          _chip('C: ${targets.carbG.round()}g', Colors.orange),
          _chip('F: ${targets.fatG.round()}g', Colors.red),
          _chip('${goal.mealSlotCount} ogun', Colors.purple),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Chip(
      label: Text(text, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

/// Plan oluştur butonu.
class _PlanGenerateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _PlanGenerateButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(isLoading ? 'Olusturuluyor...' : 'Plan Olustur'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

/// Hata kartı.
class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: TextStyle(color: Colors.red.shade900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Günlük plan görünümü — slot'lar + alternatifler.
class _DayPlanView extends StatelessWidget {
  final GeneratedDayPlan plan;
  final MacroTargets targets;

  const _DayPlanView({required this.plan, required this.targets});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: plan.slots.length,
      itemBuilder: (context, index) {
        final slot = plan.slots[index];
        return _MealSlotCard(slot: slot);
      },
    );
  }
}

/// Tek bir öğün slot kartı — ana yemek + 2 alternatif.
class _MealSlotCard extends StatelessWidget {
  final GeneratedMealSlot slot;

  const _MealSlotCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slot başlığı
            Text(
              slot.mealTypeDisplay,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            // Ana yemek
            _mealRow(slot.primary, isPrimary: true),
            const Divider(height: 16),
            // Alternatifler
            Text('Alternatifler:',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            _mealRow(slot.alt1),
            _mealRow(slot.alt2),
          ],
        ),
      ),
    );
  }

  Widget _mealRow(SelectedMeal meal, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (isPrimary) const Icon(Icons.restaurant, size: 18, color: Colors.green),
          if (!isPrimary) const Icon(Icons.swap_horiz, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              meal.meal.ad,
              style: TextStyle(
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                fontSize: isPrimary ? 15 : 13,
              ),
            ),
          ),
          Text(
            '${meal.portionG.round()}g',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Text(
            '${meal.kcal.round()} kcal',
            style: TextStyle(
              fontSize: isPrimary ? 14 : 12,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tolerans görünümü — PASS/FAIL + sapma yüzdeleri.
class _ToleranceView extends StatelessWidget {
  final ToleranceResult result;
  final int attempts;
  final List<AdjusterApplied> adjustments;

  const _ToleranceView({
    required this.result,
    required this.attempts,
    required this.adjustments,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // PASS/FAIL banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: result.passed ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  result.passed ? Icons.check_circle : Icons.cancel,
                  size: 60,
                  color: result.passed ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 8),
                Text(
                  result.passed ? 'TOLERANS PASS' : 'TOLERANS FAIL',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: result.passed ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
                Text('$attempts deneme', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sapma detayları
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sapma Yuzdeleri (Limit: +/-%15)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _deviationRow('Kalori', result.kcalDeviation,
                      '${result.actualKcal.round()} / ${result.targets.targetKcal.round()} kcal'),
                  _deviationRow('Protein', result.proteinDeviation,
                      '${result.actualProtein.round()} / ${result.targets.proteinG.round()} g'),
                  _deviationRow('Karbonhidrat', result.carbDeviation,
                      '${result.actualCarb.round()} / ${result.targets.carbG.round()} g'),
                  _deviationRow('Yag', result.fatDeviation,
                      '${result.actualFat.round()} / ${result.targets.fatG.round()} g'),
                ],
              ),
            ),
          ),

          // Adjuster kullanıldıysa göster
          if (adjustments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Macro Adjuster Kullanildi',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...adjustments.map((a) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '+ ${a.adjusterName}: ${a.addedG.toStringAsFixed(1)}g '
                            '(${a.addedKcal.round()} kcal, P:${a.addedProtein.toStringAsFixed(1)}g, '
                            'C:${a.addedCarb.toStringAsFixed(1)}g, F:${a.addedFat.toStringAsFixed(1)}g)',
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _deviationRow(String label, double deviation, String detail) {
    final isOk = deviation.abs() <= tolerancePercent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check : Icons.warning,
            size: 18,
            color: isOk ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            '${deviation >= 0 ? '+' : ''}${deviation.toStringAsFixed(1)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOk ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Text(detail, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
