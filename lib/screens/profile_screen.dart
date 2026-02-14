import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/macro_calculator.dart';

/// Profil ekranı — kullanıcı bilgileri + dinamik makro gösterimi.
///
/// Kullanıcı yaş/boy/kilo/aktivite/hedef değiştirdikçe
/// alttaki kcal+P/C/F anında güncellenir (reactive).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _calculator = const MacroCalculator();

  // Form değerleri
  int _age = 25;
  int _heightCm = 175;
  double _weightKg = 70.0;
  Gender _gender = Gender.male;
  ActivityLevel _activityLevel = ActivityLevel.moderate;
  GoalType _goal = GoalType.cut;
  ExperienceLevel _experience = ExperienceLevel.intermediate;

  // Hesaplanmış makrolar
  MacroTargets? _targets;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final profile = UserProfile(
      userId: 'demo',
      age: _age,
      heightCm: _heightCm,
      weightKg: _weightKg,
      gender: _gender,
      activityLevel: _activityLevel,
      goal: _goal,
      experience: _experience,
    );

    setState(() {
      _targets = _calculator.calculate(profile);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil ve Makro Hesaplama'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileForm(),
            const SizedBox(height: 24),
            if (_targets != null) _buildMacroDisplay(_targets!),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kişisel Bilgiler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Yaş
            Row(
              children: [
                const Expanded(child: Text('Yaş:')),
                Expanded(
                  flex: 2,
                  child: Slider(
                    value: _age.toDouble(),
                    min: 18,
                    max: 70,
                    divisions: 52,
                    label: '$_age yaş',
                    onChanged: (val) {
                      setState(() {
                        _age = val.toInt();
                      });
                      _calculate();
                    },
                  ),
                ),
                Text('$_age'),
              ],
            ),

            // Boy
            Row(
              children: [
                const Expanded(child: Text('Boy (cm):')),
                Expanded(
                  flex: 2,
                  child: Slider(
                    value: _heightCm.toDouble(),
                    min: 140,
                    max: 210,
                    divisions: 70,
                    label: '$_heightCm cm',
                    onChanged: (val) {
                      setState(() {
                        _heightCm = val.toInt();
                      });
                      _calculate();
                    },
                  ),
                ),
                Text('$_heightCm cm'),
              ],
            ),

            // Kilo
            Row(
              children: [
                const Expanded(child: Text('Kilo (kg):')),
                Expanded(
                  flex: 2,
                  child: Slider(
                    value: _weightKg,
                    min: 40,
                    max: 150,
                    divisions: 110,
                    label: '${_weightKg.toStringAsFixed(1)} kg',
                    onChanged: (val) {
                      setState(() {
                        _weightKg = val;
                      });
                      _calculate();
                    },
                  ),
                ),
                Text('${_weightKg.toStringAsFixed(1)} kg'),
              ],
            ),

            const Divider(height: 32),

            // Cinsiyet
            const Text('Cinsiyet:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<Gender>(
              segments: Gender.values
                  .map((g) => ButtonSegment(
                        value: g,
                        label: Text(g.displayName),
                      ))
                  .toList(),
              selected: {_gender},
              onSelectionChanged: (Set<Gender> selected) {
                setState(() {
                  _gender = selected.first;
                });
                _calculate();
              },
            ),

            const SizedBox(height: 16),

            // Aktivite
            const Text('Aktivite Seviyesi:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButton<ActivityLevel>(
              isExpanded: true,
              value: _activityLevel,
              items: ActivityLevel.values
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a.displayName),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _activityLevel = val;
                  });
                  _calculate();
                }
              },
            ),

            const SizedBox(height: 16),

            // Hedef
            const Text('Hedef:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<GoalType>(
              segments: GoalType.values
                  .map((g) => ButtonSegment(
                        value: g,
                        label: Text(g.displayName),
                      ))
                  .toList(),
              selected: {_goal},
              onSelectionChanged: (Set<GoalType> selected) {
                setState(() {
                  _goal = selected.first;
                });
                _calculate();
              },
            ),

            const SizedBox(height: 16),

            // Deneyim
            const Text('Deneyim Seviyesi:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButton<ExperienceLevel>(
              isExpanded: true,
              value: _experience,
              items: ExperienceLevel.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.displayName),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _experience = val;
                  });
                  _calculate();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroDisplay(MacroTargets targets) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Günlük Makro Hedefleriniz',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _macroRow('BMR (Bazal Metabolizma)', '${targets.bmr.round()} kcal'),
            _macroRow('TDEE (Günlük Enerji)', '${targets.tdee.round()} kcal'),
            const Divider(height: 24),
            _macroRow(
              'Hedef Kalori',
              '${targets.targetKcal.round()} kcal',
              color: Colors.green.shade900,
              bold: true,
            ),
            _macroRow('Protein', '${targets.proteinG.round()} g',
                color: Colors.blue.shade700),
            _macroRow('Karbonhidrat', '${targets.carbG.round()} g',
                color: Colors.orange.shade700),
            _macroRow('Yağ', '${targets.fatG.round()} g',
                color: Colors.red.shade700),
            const SizedBox(height: 16),
            Text(
              'Öğün Sayısı: ${_goal.mealSlotCount} öğün',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroRow(String label, String value,
      {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 18 : 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
