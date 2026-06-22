import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/goal_model.dart';
import '../models/transaction_model.dart';

class FirebaseService {
  static bool useMock = false;

  // Mock In-Memory Database keyed by User UID
  static final Map<String, UserModel> _mockProfiles = {};
  static final Map<String, List<GoalModel>> _mockGoals = {};
  static final Map<String, List<TransactionModel>> _mockTransactions = {};

  static final Map<String, StreamController<UserModel?>> _profileControllers = {};
  static final Map<String, StreamController<List<GoalModel>>> _goalsControllers = {};
  static final Map<String, StreamController<List<TransactionModel>>> _transactionsControllers = {};

  static StreamController<UserModel?> _getProfileController(String uid) {
    return _profileControllers.putIfAbsent(uid, () => StreamController<UserModel?>.broadcast());
  }

  static StreamController<List<GoalModel>> _getGoalsController(String uid) {
    return _goalsControllers.putIfAbsent(uid, () => StreamController<List<GoalModel>>.broadcast());
  }

  static StreamController<List<TransactionModel>> _getTransactionsController(String uid) {
    return _transactionsControllers.putIfAbsent(uid, () => StreamController<List<TransactionModel>>.broadcast());
  }

  static String? loadedSessionUid;
  static String? loadedSessionEmail;

  /// Initialize default mock values for immediate visual testing if Firebase is not configured yet.
  static void initMock() {
    useMock = true;
    const defaultUid = 'mock_uid_123';
    if (!_mockProfiles.containsKey(defaultUid)) {
      _mockProfiles[defaultUid] = UserModel(
        uid: defaultUid,
        email: 'rehan@finsim.com',
        monthlySalary: 12000000.0, // 12,000,000 IDR
        profession: 'Product Designer & Developer',
        name: 'Reyhan FinSim',
        photoUrl: '',
      );

      _mockGoals[defaultUid] = [
        GoalModel(
          id: 'mock_goal_1',
          userId: defaultUid,
          name: 'iPhone 17 Pro Max',
          targetPrice: 24000000.0,
          currentSavings: 9600000.0,
          deadline: DateTime.now().add(const Duration(days: 90)),
        ),
        GoalModel(
          id: 'mock_goal_2',
          userId: defaultUid,
          name: 'Dana Darurat 6 Bulan',
          targetPrice: 30000000.0,
          currentSavings: 18000000.0,
          deadline: DateTime.now().add(const Duration(days: 180)),
        ),
      ];

      _mockTransactions[defaultUid] = [
        TransactionModel(
          id: 'mock_t_1',
          userId: defaultUid,
          amount: 250000.0,
          category: 'Makanan',
          note: 'Makan Ramen dengan Tim',
          date: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        TransactionModel(
          id: 'mock_t_2',
          userId: defaultUid,
          amount: 150000.0,
          category: 'Transportasi',
          note: 'Top up E-Toll & Ojek Online',
          date: DateTime.now().subtract(const Duration(days: 1)),
        ),
        TransactionModel(
          id: 'mock_t_3',
          userId: defaultUid,
          amount: 1600000.0,
          category: 'Gaya Hidup',
          note: 'Beli Sneaker Baru',
          date: DateTime.now().subtract(const Duration(days: 2)),
        ),
        TransactionModel(
          id: 'mock_t_4',
          userId: defaultUid,
          amount: 450000.0,
          category: 'Hiburan',
          note: 'Konser Musik Akhir Pekan',
          date: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
    }
  }

  static Future<void> saveMockDb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Profiles
      final Map<String, dynamic> profilesJson = {};
      _mockProfiles.forEach((key, val) {
        profilesJson[key] = val.toMap();
      });
      await prefs.setString('mock_profiles', jsonEncode(profilesJson));

      // Goals
      final Map<String, dynamic> goalsJson = {};
      _mockGoals.forEach((key, list) {
        goalsJson[key] = list.map((g) => {
          'id': g.id,
          'userId': g.userId,
          'name': g.name,
          'targetPrice': g.targetPrice,
          'currentSavings': g.currentSavings,
          'deadline': g.deadline.toIso8601String(),
        }).toList();
      });
      await prefs.setString('mock_goals', jsonEncode(goalsJson));

      // Transactions
      final Map<String, dynamic> transactionsJson = {};
      _mockTransactions.forEach((key, list) {
        transactionsJson[key] = list.map((t) => {
          'id': t.id,
          'userId': t.userId,
          'amount': t.amount,
          'category': t.category,
          'note': t.note,
          'date': t.date.toIso8601String(),
        }).toList();
      });
      await prefs.setString('mock_transactions', jsonEncode(transactionsJson));
    } catch (e) {
      debugPrint('Error saving mock database: $e');
    }
  }

  static Future<void> loadMockDb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      loadedSessionUid = prefs.getString('mock_session_uid');
      loadedSessionEmail = prefs.getString('mock_session_email');

      // Profiles
      final String? profilesStr = prefs.getString('mock_profiles');
      if (profilesStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(profilesStr);
        _mockProfiles.clear();
        decoded.forEach((key, val) {
          _mockProfiles[key] = UserModel.fromMap(Map<String, dynamic>.from(val));
        });
      }

      // Goals
      final String? goalsStr = prefs.getString('mock_goals');
      if (goalsStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(goalsStr);
        _mockGoals.clear();
        decoded.forEach((key, val) {
          final List<dynamic> list = val;
          _mockGoals[key] = list.map((item) {
            final map = Map<String, dynamic>.from(item);
            final String id = map['id'] ?? '';
            return GoalModel.fromMap(map, id);
          }).toList();
        });
      }

      // Transactions
      final String? transactionsStr = prefs.getString('mock_transactions');
      if (transactionsStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(transactionsStr);
        _mockTransactions.clear();
        decoded.forEach((key, val) {
          final List<dynamic> list = val;
          _mockTransactions[key] = list.map((item) {
            final map = Map<String, dynamic>.from(item);
            final String id = map['id'] ?? '';
            return TransactionModel.fromMap(map, id);
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading mock database: $e');
    }
  }

  static void ensureDemoAccountInitialized() {
    const defaultUid = 'mock_uid_123';
    if (!_mockProfiles.containsKey(defaultUid)) {
      _mockProfiles[defaultUid] = UserModel(
        uid: defaultUid,
        email: 'rehan@finsim.com',
        monthlySalary: 12000000.0, // 12,000,000 IDR
        profession: 'Product Designer & Developer',
        name: 'Reyhan FinSim',
        photoUrl: '',
      );

      _mockGoals[defaultUid] = [
        GoalModel(
          id: 'mock_goal_1',
          userId: defaultUid,
          name: 'iPhone 17 Pro Max',
          targetPrice: 24000000.0,
          currentSavings: 9600000.0,
          deadline: DateTime.now().add(const Duration(days: 90)),
        ),
        GoalModel(
          id: 'mock_goal_2',
          userId: defaultUid,
          name: 'Dana Darurat 6 Bulan',
          targetPrice: 30000000.0,
          currentSavings: 18000000.0,
          deadline: DateTime.now().add(const Duration(days: 180)),
        ),
      ];

      _mockTransactions[defaultUid] = [
        TransactionModel(
          id: 'mock_t_1',
          userId: defaultUid,
          amount: 250000.0,
          category: 'Makanan',
          note: 'Makan Ramen dengan Tim',
          date: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        TransactionModel(
          id: 'mock_t_2',
          userId: defaultUid,
          amount: 150000.0,
          category: 'Transportasi',
          note: 'Top up E-Toll & Ojek Online',
          date: DateTime.now().subtract(const Duration(days: 1)),
        ),
        TransactionModel(
          id: 'mock_t_3',
          userId: defaultUid,
          amount: 1600000.0,
          category: 'Gaya Hidup',
          note: 'Beli Sneaker Baru',
          date: DateTime.now().subtract(const Duration(days: 2)),
        ),
        TransactionModel(
          id: 'mock_t_4',
          userId: defaultUid,
          amount: 450000.0,
          category: 'Hiburan',
          note: 'Konser Musik Akhir Pekan',
          date: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
      saveMockDb();
    }
  }

  // Firestore Instance
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // --- USER PROFILE ---

  Future<void> createUserProfile(UserModel user) async {
    if (useMock) {
      _mockProfiles[user.uid] = user;
      _getProfileController(user.uid).add(user);
      await saveMockDb();
      return;
    }
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<void> updateUserProfile(String uid, double monthlySalary, String profession) async {
    if (useMock) {
      final existing = _mockProfiles[uid] ?? UserModel(uid: uid, email: '', monthlySalary: 0.0, profession: '');
      final updated = existing.copyWith(
        monthlySalary: monthlySalary,
        profession: profession,
      );
      _mockProfiles[uid] = updated;
      _getProfileController(uid).add(updated);
      await saveMockDb();
      return;
    }
    await _firestore.collection('users').doc(uid).update({
      'monthlySalary': monthlySalary,
      'profession': profession,
    });
  }

  Future<void> updatePersonalProfile(String uid, String name, String photoUrl, String profession) async {
    if (useMock) {
      final existing = _mockProfiles[uid] ?? UserModel(uid: uid, email: '', monthlySalary: 0.0, profession: '');
      final updated = existing.copyWith(
        name: name,
        photoUrl: photoUrl,
        profession: profession,
      );
      _mockProfiles[uid] = updated;
      _getProfileController(uid).add(updated);
      await saveMockDb();
      return;
    }
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'photoUrl': photoUrl,
      'profession': profession,
    });
  }

  Stream<UserModel?> streamUserProfile(String uid) {
    if (useMock) {
      final profile = _mockProfiles[uid] ?? UserModel(uid: uid, email: '', monthlySalary: 0.0, profession: '');
      Timer.run(() => _getProfileController(uid).add(profile));
      return _getProfileController(uid).stream;
    }
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserModel.fromMap(snapshot.data()!);
    });
  }

  // --- GOALS ---

  Future<void> addGoal(String uid, String name, double targetPrice, double currentSavings, DateTime deadline) async {
    if (useMock) {
      final list = _mockGoals[uid] ?? [];
      final newGoal = GoalModel(
        id: 'mock_goal_${DateTime.now().millisecondsSinceEpoch}',
        userId: uid,
        name: name,
        targetPrice: targetPrice,
        currentSavings: currentSavings,
        deadline: deadline,
      );
      list.add(newGoal);
      _mockGoals[uid] = list;
      _getGoalsController(uid).add(List.from(list));
      await saveMockDb();
      return;
    }
    await _firestore.collection('users').doc(uid).collection('goals').add({
      'userId': uid,
      'name': name,
      'targetPrice': targetPrice,
      'currentSavings': currentSavings,
      'deadline': Timestamp.fromDate(deadline),
    });
  }

  Future<void> updateGoalSavings(String uid, String goalId, double newSavings) async {
    if (useMock) {
      final list = _mockGoals[uid] ?? [];
      final index = list.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        final existing = list[index];
        list[index] = GoalModel(
          id: existing.id,
          userId: existing.userId,
          name: existing.name,
          targetPrice: existing.targetPrice,
          currentSavings: newSavings,
          deadline: existing.deadline,
        );
        _mockGoals[uid] = list;
        _getGoalsController(uid).add(List.from(list));
        await saveMockDb();
      }
      return;
    }
    await _firestore.collection('users').doc(uid).collection('goals').doc(goalId).update({
      'currentSavings': newSavings,
    });
  }

  Future<void> deleteGoal(String uid, String goalId) async {
    if (useMock) {
      final list = _mockGoals[uid] ?? [];
      list.removeWhere((g) => g.id == goalId);
      _mockGoals[uid] = list;
      _getGoalsController(uid).add(List.from(list));
      await saveMockDb();
      return;
    }
    await _firestore.collection('users').doc(uid).collection('goals').doc(goalId).delete();
  }

  Stream<List<GoalModel>> streamGoals(String uid) {
    if (useMock) {
      final list = _mockGoals[uid] ?? [];
      Timer.run(() => _getGoalsController(uid).add(List.from(list)));
      return _getGoalsController(uid).stream;
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('goals')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GoalModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // --- TRANSACTIONS ---

  Future<void> addTransaction(String uid, double amount, String category, String note, DateTime date) async {
    if (useMock) {
      final list = _mockTransactions[uid] ?? [];
      final newT = TransactionModel(
        id: 'mock_t_${DateTime.now().millisecondsSinceEpoch}',
        userId: uid,
        amount: amount,
        category: category,
        note: note,
        date: date,
      );
      list.insert(0, newT); // Add to top
      _mockTransactions[uid] = list;
      _getTransactionsController(uid).add(List.from(list));
      await saveMockDb();
      return;
    }
    await _firestore.collection('users').doc(uid).collection('transactions').add({
      'userId': uid,
      'amount': amount,
      'category': category,
      'note': note,
      'date': Timestamp.fromDate(date),
    });
  }

  Future<void> deleteTransaction(String uid, String transId) async {
    if (useMock) {
      final list = _mockTransactions[uid] ?? [];
      list.removeWhere((t) => t.id == transId);
      _mockTransactions[uid] = list;
      _getTransactionsController(uid).add(List.from(list));
      await saveMockDb();
      return;
    }
    await _firestore.collection('users').doc(uid).collection('transactions').doc(transId).delete();
  }

  Stream<List<TransactionModel>> streamTransactions(String uid) {
    if (useMock) {
      final list = _mockTransactions[uid] ?? [];
      Timer.run(() => _getTransactionsController(uid).add(List.from(list)));
      return _getTransactionsController(uid).stream;
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TransactionModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> restoreBackup(String uid, String jsonBackupString) async {
    final Map<String, dynamic> data = jsonDecode(jsonBackupString);
    if (data['version'] != 1) {
      throw Exception('Versi backup tidak didukung');
    }
    
    // Parse profile
    final profileMap = Map<String, dynamic>.from(data['profile'] ?? {});
    if (profileMap.isNotEmpty) {
      final user = UserModel.fromMap(profileMap);
      if (useMock) {
        _mockProfiles[uid] = user;
        _getProfileController(uid).add(user);
      } else {
        await _firestore.collection('users').doc(uid).set(user.toMap());
      }
    }
    
    final List<dynamic> goalsList = data['goals'] ?? [];
    final List<GoalModel> parsedGoals = [];
    for (var g in goalsList) {
      final map = Map<String, dynamic>.from(g);
      DateTime deadline = DateTime.now();
      if (map['deadline'] != null) {
        deadline = DateTime.parse(map['deadline']);
      }
      parsedGoals.add(GoalModel(
        id: map['id'] ?? 'mock_goal_${DateTime.now().millisecondsSinceEpoch}_${parsedGoals.length}',
        userId: uid,
        name: map['name'] ?? '',
        targetPrice: (map['targetPrice'] as num?)?.toDouble() ?? 0.0,
        currentSavings: (map['currentSavings'] as num?)?.toDouble() ?? 0.0,
        deadline: deadline,
      ));
    }
    
    final List<dynamic> transList = data['transactions'] ?? [];
    final List<TransactionModel> parsedTrans = [];
    for (var t in transList) {
      final map = Map<String, dynamic>.from(t);
      DateTime date = DateTime.now();
      if (map['date'] != null) {
        date = DateTime.parse(map['date']);
      }
      parsedTrans.add(TransactionModel(
        id: map['id'] ?? 'mock_t_${DateTime.now().millisecondsSinceEpoch}_${parsedTrans.length}',
        userId: uid,
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        category: map['category'] ?? 'Lainnya',
        note: map['note'] ?? '',
        date: date,
      ));
    }

    if (useMock) {
      _mockGoals[uid] = parsedGoals;
      _mockTransactions[uid] = parsedTrans;
      _getGoalsController(uid).add(parsedGoals);
      _getTransactionsController(uid).add(parsedTrans);
      await saveMockDb();
    } else {
      // Delete existing in Firestore
      final goalsSnapshot = await _firestore.collection('users').doc(uid).collection('goals').get();
      for (var doc in goalsSnapshot.docs) {
        await doc.reference.delete();
      }
      final transSnapshot = await _firestore.collection('users').doc(uid).collection('transactions').get();
      for (var doc in transSnapshot.docs) {
        await doc.reference.delete();
      }

      // Add new to Firestore
      for (var g in parsedGoals) {
        await _firestore.collection('users').doc(uid).collection('goals').doc(g.id).set(g.toMap());
      }
      for (var t in parsedTrans) {
        await _firestore.collection('users').doc(uid).collection('transactions').doc(t.id).set(t.toMap());
      }
    }
  }
}
