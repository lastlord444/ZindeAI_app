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
  bool _lastSwapWasNetworkError = false;

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
    if (!mounted) return;
    setState(() {
      isConsumed =
          prefs.getBool('consumed_${widget.mealName}') ?? widget.initialConsumed;
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
  /// Debounce: _isSwapLoading kontrolü ile aynı anda 2 istek engellenir.
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
      _lastSwapWasNetworkError = false;
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

      // 2'den az alternatif → empty state göster
      if (response.alternatives.length < 2) {
        _showEmptyAlternativesSheet();
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
      _showErrorSnackBar(
        e.suggestion ?? e.message,
        isRetryable: false,
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSwapLoading = false;
        _lastSwapWasNetworkError = true;
        _swapErrorMessage = 'Bağlantı hatası: ${e.message}';
      });
      _showErrorSnackBar(
        'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.',
        isRetryable: true,
      );
    } on AppBaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSwapLoading = false;
        _swapErrorMessage = e.message;
      });
      _showErrorSnackBar(e.message, isRetryable: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSwapLoading = false;
        _swapErrorMessage = 'Beklenmeyen hata oluştu.';
      });
      _showErrorSnackBar('Beklenmeyen hata oluştu.', isRetryable: true);
    }
  }

  /// Başarılı swap sonrası yeşil SnackBar göster.
  void _showSuccessSnackBar(String newMealName) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Alternatif uygulandı: $newMealName'),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Hata SnackBar: kırmızı, opsiyonel retry aksiyonu.
  void _showErrorSnackBar(String message, {bool isRetryable = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isRetryable ? 6 : 4),
        action: isRetryable
            ? SnackBarAction(
                label: 'Tekrar Dene',
                textColor: Colors.white,
                onPressed: _showSwapModal,
              )
            : null,
      ),
    );
  }

  /// Alternatif bulunamadı → BottomSheet empty state.
  void _showEmptyAlternativesSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Alternatif Bulunamadı',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Bu öğüne uygun yeterli alternatif yok.\n'
                'Filtrelerinizi gevşetmeyi veya farklı bir öğün denemeyi deneyin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                    onPressed: () {
                      Navigator.pop(context);
                      _showSwapModal();
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Kapat'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// API'den gelen 2 alternatifli BottomSheet.
  void _showApiSwapModal(SwapAlternativesResponse response) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Alternatif Seçin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${response.count} alternatif  •  ${response.tolerance}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Divider(height: 20),
              ...response.alternatives.map((alt) => Card(
                    elevation: 0,
                    color: Colors.grey.shade50,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade50,
                        child: Icon(Icons.restaurant,
                            color: Colors.green.shade700, size: 20),
                      ),
                      title: Text(alt.ad,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${alt.kalori.toStringAsFixed(0)} kcal  •  '
                        'P: ${alt.protein.toStringAsFixed(0)}g  '
                        'K: ${alt.karb.toStringAsFixed(0)}g  '
                        'Y: ${alt.yag.toStringAsFixed(0)}g\n'
                        '${alt.porsiyon} porsiyon (${alt.porsiyonG.toStringAsFixed(0)}g)',
                        style: const TextStyle(fontSize: 11, height: 1.4),
                      ),
                      isThreeLine: true,
                      trailing: Icon(Icons.chevron_right,
                          color: Colors.grey.shade400),
                      onTap: () {
                        final previousMeal = currentMeal;
                        setState(() {
                          currentMeal = alt.ad;
                          currentCalories = alt.kalori.toStringAsFixed(0);
                          _swapErrorMessage = null;
                          _lastSwapWasNetworkError = false;
                        });
                        Navigator.pop(sheetContext);
                        // Başarılı swap → yeşil feedback
                        if (previousMeal != alt.ad) {
                          _showSuccessSnackBar(alt.ad);
                        }
                      },
                    ),
                  )),
              const SizedBox(height: 8),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Alternatif Seçin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (widget.alternatives.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.search_off,
                          size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Alternatif yok.',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              else
                ...widget.alternatives.map((alt) => ListTile(
                      leading: const Icon(Icons.restaurant_menu),
                      title: Text(alt),
                      onTap: () {
                        setState(() {
                          currentMeal = alt;
                        });
                        Navigator.pop(context);
                        _showSuccessSnackBar(alt);
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
                          decoration:
                              isConsumed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text('$currentCalories kcal',
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      // Badges
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _buildBadge('Budget', Colors.green),
                          _buildBadge('High Protein', Colors.blue),
                          if (_isSwapDisabled)
                            _buildBadge('Swap N/A', Colors.red),
                        ],
                      ),
                      if (_swapErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 12,
                                  color: _lastSwapWasNetworkError
                                      ? Colors.red.shade700
                                      : Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _swapErrorMessage!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _lastSwapWasNetworkError
                                        ? Colors.red.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                              if (_lastSwapWasNetworkError)
                                GestureDetector(
                                  onTap: _showSwapModal,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      'Tekrar dene',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
                  tooltip: isLocked ? 'Kilidi aç' : 'Kilitle',
                ),
                // Swap Button (loading + disabled state)
                _isSwapLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.swap_horiz,
                          color: (isLocked || _isSwapDisabled)
                              ? Colors.grey.shade300
                              : Colors.deepPurple,
                        ),
                        onPressed: (isLocked || _isSwapDisabled)
                            ? null
                            : _showSwapModal,
                        tooltip: _isSwapDisabled
                            ? 'Alternatif yok'
                            : 'Yemek değiştir',
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
