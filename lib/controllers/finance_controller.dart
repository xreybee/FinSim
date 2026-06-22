import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/goal_model.dart';
import '../models/transaction_model.dart';
import '../services/firebase_service.dart';

class FinanceController extends ChangeNotifier {
  final FirebaseService _db = FirebaseService();

  UserModel? _userProfile;
  List<GoalModel> _goals = [];
  List<TransactionModel> _transactions = [];

  StreamSubscription? _profileSub;
  StreamSubscription? _goalsSub;
  StreamSubscription? _transSub;

  UserModel? get userProfile => _userProfile;
  List<GoalModel> get goals => _goals;
  List<TransactionModel> get transactions => _transactions;

  /// Starts listening to real-time streams of profile, goals, and transactions for the given user.
  void init(String uid) {
    _profileSub?.cancel();
    _goalsSub?.cancel();
    _transSub?.cancel();

    _profileSub = _db.streamUserProfile(uid).listen((profile) {
      _userProfile = profile;
      notifyListeners();
    });

    _goalsSub = _db.streamGoals(uid).listen((goalsList) {
      _goals = goalsList;
      notifyListeners();
    });

    _transSub = _db.streamTransactions(uid).listen((transList) {
      _transactions = transList;
      notifyListeners();
    });
  }

  /// Cancels all subscriptions and clears local state.
  void clear() {
    _profileSub?.cancel();
    _goalsSub?.cancel();
    _transSub?.cancel();
    _userProfile = null;
    _goals = [];
    _transactions = [];
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> updateProfile(double salary, String profession) async {
    if (_userProfile == null) return;
    await _db.updateUserProfile(_userProfile!.uid, salary, profession);
  }

  Future<void> updatePersonalProfile(String name, String photoUrl, String profession) async {
    if (_userProfile == null) return;
    await _db.updatePersonalProfile(_userProfile!.uid, name, photoUrl, profession);
  }

  Future<void> addGoal(String name, double targetPrice, double currentSavings, DateTime deadline) async {
    if (_userProfile == null) return;
    await _db.addGoal(_userProfile!.uid, name, targetPrice, currentSavings, deadline);
  }

  Future<void> addSavingsToGoal(String goalId, double amount) async {
    if (_userProfile == null) return;
    final goalIndex = _goals.indexWhere((g) => g.id == goalId);
    if (goalIndex != -1) {
      final goal = _goals[goalIndex];
      await _db.updateGoalSavings(_userProfile!.uid, goalId, goal.currentSavings + amount);
    }
  }

  Future<void> deleteGoal(String goalId) async {
    if (_userProfile == null) return;
    await _db.deleteGoal(_userProfile!.uid, goalId);
  }

  Future<void> addTransaction(double amount, String category, String note) async {
    if (_userProfile == null) return;
    await _db.addTransaction(_userProfile!.uid, amount, category, note, DateTime.now());
  }

  Future<void> deleteTransaction(String transId) async {
    if (_userProfile == null) return;
    await _db.deleteTransaction(_userProfile!.uid, transId);
  }

  // --- BUDGET calculations ---

  double get monthlySalary => _userProfile?.monthlySalary ?? 0.0;

  double get survivalPct => _userProfile?.survivalPct ?? 40.0;
  double get transportPct => _userProfile?.transportPct ?? 10.0;
  double get stylePct => _userProfile?.stylePct ?? 10.0;
  double get entertainmentPct => _userProfile?.entertainmentPct ?? 10.0;
  double get emergencyPct => _userProfile?.emergencyPct ?? 10.0;
  double get goalsPct => _userProfile?.goalsPct ?? 20.0;

  // Dynamic allocation limits
  double get limitSurvival => monthlySalary * (survivalPct / 100.0);
  double get limitTransport => monthlySalary * (transportPct / 100.0);
  double get limitStyle => monthlySalary * (stylePct / 100.0);
  double get limitEntertainment => monthlySalary * (entertainmentPct / 100.0);
  double get limitEmergency => monthlySalary * (emergencyPct / 100.0);
  double get limitGoals => monthlySalary * (goalsPct / 100.0);

  // Monthly real spending sums
  double get spendingSurvival {
    return _transactions
        .where((t) => (t.category == 'Makanan' || t.category == 'Survival') && _isCurrentMonth(t.date))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get spendingTransport {
    return _transactions
        .where((t) => t.category == 'Transportasi' && _isCurrentMonth(t.date))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get spendingStyle {
    return _transactions
        .where((t) => (t.category == 'Gaya Hidup' || t.category == 'Style') && _isCurrentMonth(t.date))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get spendingEntertainment {
    return _transactions
        .where((t) => t.category == 'Hiburan' && _isCurrentMonth(t.date))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get spendingEmergency {
    return _transactions
        .where((t) => t.category == 'Dana Darurat' && _isCurrentMonth(t.date))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalSavingsInGoals {
    return _goals.fold(0.0, (sum, g) => sum + g.currentSavings);
  }

  // Remaining budget per category
  double get remainingSurvival => limitSurvival - spendingSurvival;
  double get remainingTransport => limitTransport - spendingTransport;
  double get remainingStyle => limitStyle - spendingStyle;
  double get remainingEntertainment => limitEntertainment - spendingEntertainment;
  double get remainingEmergency => limitEmergency - spendingEmergency;
  double get remainingGoals => limitGoals - totalSavingsInGoals;

  // Overall clean cash balance
  double get overallRemainingBalance {
    return monthlySalary - (spendingSurvival + spendingTransport + spendingStyle + spendingEntertainment + spendingEmergency + totalSavingsInGoals);
  }

  bool _isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.month == now.month && date.year == now.year;
  }

  int _getDaysInMonth(int year, int month) {
    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeap ? 29 : 28;
    }
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month - 1];
  }

  Future<void> updateBudgetRule({
    required double survival,
    required double transport,
    required double style,
    required double entertainment,
    required double emergency,
    required double goals,
  }) async {
    if (_userProfile == null) return;
    final updated = _userProfile!.copyWith(
      survivalPct: survival,
      transportPct: transport,
      stylePct: style,
      entertainmentPct: entertainment,
      emergencyPct: emergency,
      goalsPct: goals,
    );
    await _db.createUserProfile(updated);
  }

  // Advisory logic per category
  Map<String, dynamic> getCategoryStatus(String category) {
    double actual = 0.0;
    double limit = 0.0;
    double pct = 0.0;
    String advice = '';

    switch (category) {
      case 'Survival':
        actual = spendingSurvival;
        limit = limitSurvival;
        pct = survivalPct;
        advice = "Pengeluaran Bertahan Hidup Anda melebihi batas alokasi ${pct.toStringAsFixed(0)}%. Harap prioritaskan kebutuhan pokok!";
        break;
      case 'Transportasi':
        actual = spendingTransport;
        limit = limitTransport;
        pct = transportPct;
        advice = "Biaya Transportasi Anda melebihi alokasi ${pct.toStringAsFixed(0)}%. Pertimbangkan beralih ke alternatif yang lebih hemat!";
        break;
      case 'Style':
        actual = spendingStyle;
        limit = limitStyle;
        pct = stylePct;
        advice = "Pengeluaran Gaya Hidup Anda melebihi batas alokasi ${pct.toStringAsFixed(0)}%. Tunda pengeluaran non-mendesak Anda!";
        break;
      case 'Hiburan':
        actual = spendingEntertainment;
        limit = limitEntertainment;
        pct = entertainmentPct;
        advice = "Pengeluaran Hiburan Anda melebihi batas alokasi ${pct.toStringAsFixed(0)}%. Coba kurangi frekuensi hiburan/jajan di sisa bulan ini!";
        break;
      case 'Dana Darurat':
        actual = spendingEmergency;
        limit = limitEmergency;
        pct = emergencyPct;
        advice = "Dana Darurat terpakai melebihi alokasi ${pct.toStringAsFixed(0)}%. Berhati-hatilah dan segera isi kembali pos darurat!";
        break;
      case 'Goals':
        actual = totalSavingsInGoals;
        limit = limitGoals;
        pct = goalsPct;
        advice = "Tabungan impian Anda saat ini belum mencapai target ideal ${pct.toStringAsFixed(0)}% dari gaji. Ayo sisihkan lebih konsisten!";
        break;
    }

    // Goals category is healthy if it is >= limit, other spending categories are healthy if <= limit
    final bool isOver = category == 'Goals' 
        ? (actual < limit && limit > 0) 
        : (actual > limit);
    final String healthText = isOver ? 'Kurang Sehat' : 'Sehat';

    // Calculate smart pacing warnings
    final now = DateTime.now();
    final daysIn = _getDaysInMonth(now.year, now.month);
    final currentDay = now.day;
    final double elapsedRatio = currentDay / daysIn;

    bool isPacingTooFast = false;
    String pacingAdvice = '';
    if (category != 'Goals' && limit > 0 && actual > (limit * elapsedRatio * 1.15) && actual > 150000.0 && actual <= limit) {
      isPacingTooFast = true;
      pacingAdvice = "Penggunaan anggaran $category berjalan terlalu cepat (${(actual/limit*100).toStringAsFixed(0)}% terpakai dalam $currentDay/$daysIn hari). Batasi belanja pos ini agar tidak over sebelum akhir bulan!";
    }

    return {
      'actual': actual,
      'limit': limit,
      'isHealthy': !isOver,
      'status': healthText,
      'advice': advice,
      'isPacingTooFast': isPacingTooFast,
      'pacingAdvice': pacingAdvice,
    };
  }

  /// Get list of all warning advices.
  List<String> getWarnings() {
    List<String> warnings = [];
    final categories = ['Survival', 'Transportasi', 'Style', 'Hiburan', 'Dana Darurat'];
    for (var cat in categories) {
      final status = getCategoryStatus(cat);
      if (!status['isHealthy']) {
        warnings.add(status['advice']);
      } else if (status['isPacingTooFast'] == true) {
        warnings.add(status['pacingAdvice']);
      }
    }
    return warnings;
  }

  Future<void> restoreBackup(String jsonStr) async {
    if (_userProfile == null) return;
    await _db.restoreBackup(_userProfile!.uid, jsonStr);
    if (FirebaseService.useMock) {
      init(_userProfile!.uid);
    }
  }
}
