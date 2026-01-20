import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MealCard extends StatefulWidget {
  final String mealName;
  final String calories;
  final List<String> alternatives;
  final bool initialLocked;
  final bool initialConsumed;

  const MealCard({
    super.key,
    required this.mealName,
    required this.calories,
    this.alternatives = const [],
    this.initialLocked = false,
    this.initialConsumed = false,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  late bool isLocked;
  late bool isConsumed;
  late String currentMeal;

  @override
  void initState() {
    super.initState();
    isLocked = widget.initialLocked;
    isConsumed = widget.initialConsumed;
    currentMeal = widget.mealName;
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isConsumed = prefs.getBool('consumed_${widget.mealName}') ?? widget.initialConsumed;
    });
  }

  Future<void> _toggleConsumed(bool? value) async {
    final newValue = value ?? false;
    setState(() {
      isConsumed = newValue;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('consumed_${widget.mealName}', newValue);
  }

  void _showSwapModal() {
    if (isLocked) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Alternatif Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (widget.alternatives.isEmpty)
                const Text("Alternatif yok.")
              else
                ...widget.alternatives.map((alt) => ListTile(
                      title: Text(alt),
                      onTap: () {
                        setState(() {
                          currentMeal = alt;
                        });
                        Navigator.pop(context);
                      },
                    )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                // Checkbox for Consumed
                Checkbox(
                  value: isConsumed,
                  onChanged: _toggleConsumed,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentMeal,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: isConsumed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text("${widget.calories} kcal", style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      // Mock Badges
                      Row(
                        children: [
                          _buildBadge("Budget", Colors.green),
                          const SizedBox(width: 4),
                          _buildBadge("High Protein", Colors.blue),
                        ],
                      )
                    ],
                  ),
                ),
                // Lock Button
                IconButton(
                  icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
                  color: isLocked ? Colors.red : Colors.grey,
                  onPressed: _toggleLock,
                ),
                // Swap Button
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: isLocked ? null : _showSwapModal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
