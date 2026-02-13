import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/algo_client.dart';
import '../services/errors.dart';
import '../services/models/swap_models.dart';

class MealCard extends StatefulWidget {
  final String mealName;
  final String calories;
  final String? mealId;
  final String? ogunSlot;
  final String? diyetTipi;
  final List<String> alerjenler;
  final List<String> alternatives;
  final bool initialLocked;
  final bool initialConsumed;
  final AlgoClient? algoClient;

  const MealCard({
    super.key,
    required this.mealName,
    required this.calories,
    this.mealId,
    this.ogunSlot,
    this.diyetTipi,
    this.alerjenler = const [],
    this.alternatives = const [],
    this.initialLocked = false,
    this.initialConsumed = false,
    this.algoClient,
  });

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  late bool isLocked;
  late bool isConsumed;
  late String currentMeal;
  late String currentCalories;
  bool _isSwapLoading = false;
  bool _isSwapDisabled = false;
  String? _swapErrorMessage;

  AlgoClient get _algoClient => widget.algoClient ?? AlgoClient();

  @override
  void initState() {
    super.initState();
    isLocked = widget.initialLocked;
    isConsumed = widget.initialConsumed;
    currentMeal = widget.mealName;
    currentCalories = widget.calories;
    _loadState();
  }

  void _toggleLock() {
    setState(() {
      isLocked = !isLocked;
    });
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

  /// API'den swap alternatifleri getir ve BottomSheet göster.
  Future<void> _showSwapModal() async {
    if (isLocked || _isSwapDisabled || _isSwapLoading) return;

    // mealId yoksa eski statik davranışa düş
    if (widget.mealId == null || widget.ogunSlot == null) {
      _showStaticSwapModal();
      return;
    }

    setState(() {
      _isSwapLoading = true;
      _swapErrorMessage = null;
    });

    try {
      final request = SwapAlternativesRequest(
        yemekId: widget.mealId!,
        ogunSlot: widget.ogunSlot!,
        diyetTipi: widget.diyetTipi ?? 'normal',
        alerjenler: widget.alerjenler,
      );

      final response = await _algoClient.getAlternatives(request);

      if (!mounted) return;

      setState(() {
        _isSwapLoading = false;
      });

      // 2'den az alternatif → gösterme (hata say)
      if (response.alternatives.length < 2) {
        _showSwapError('Yeterli alternatif bulunamadı.');
        return;
      }

      _showApiSwapModal(response);
    } on InsufficientPoolException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSwapLoading = false;
        _isSwapDisabled = true;
        _swapErrorMessage = e.suggestion ?? e.message;
      });
      _showSwapError(e.suggestion ?? e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSwapLoading = false;
      });
      _showSwapError(e.message);
    } on AppBaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSwapLoading = false;
      });
      _showSwapError(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSwapLoading = false;
      });
      _showSwapError('Beklenmeyen hata oluştu.');
    }
  }

  void _showSwapError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// API'den gelen 2 alternatifli BottomSheet.
  void _showApiSwapModal(SwapAlternativesResponse response) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Alternatif Seçin (${response.tolerance})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${response.count} alternatif bulundu',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 10),
              ...response.alternatives.map((alt) => ListTile(
                    leading: const Icon(Icons.restaurant, color: Colors.green),
                    title: Text(alt.ad),
                    subtitle: Text(
                      '${alt.kalori.toStringAsFixed(0)} kcal  •  '
                      'P: ${alt.protein.toStringAsFixed(0)}g  '
                      'K: ${alt.karb.toStringAsFixed(0)}g  '
                      'Y: ${alt.yag.toStringAsFixed(0)}g  •  '
                      '${alt.porsiyon} (${alt.porsiyonG.toStringAsFixed(0)}g)',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () {
                      setState(() {
                        currentMeal = alt.ad;
                        currentCalories = alt.kalori.toStringAsFixed(0);
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

  /// Eski statik alternatifler (mealId yokken fallback).
  void _showStaticSwapModal() {
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
                      Text("$currentCalories kcal", style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      // Badges
                      Row(
                        children: [
                          _buildBadge("Budget", Colors.green),
                          const SizedBox(width: 4),
                          _buildBadge("High Protein", Colors.blue),
                          if (_isSwapDisabled) ...[
                            const SizedBox(width: 4),
                            _buildBadge("Swap N/A", Colors.orange),
                          ],
                        ],
                      ),
                      if (_swapErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _swapErrorMessage!,
                            style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
                          ),
                        ),
                    ],
                  ),
                ),
                // Lock Button
                IconButton(
                  icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
                  color: isLocked ? Colors.red : Colors.grey,
                  onPressed: _toggleLock,
                ),
                // Swap Button (loading + disabled state)
                _isSwapLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.swap_horiz,
                          color: _isSwapDisabled ? Colors.grey.shade300 : null,
                        ),
                        onPressed: (isLocked || _isSwapDisabled) ? null : _showSwapModal,
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
