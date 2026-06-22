class UserModel {
  final String uid;
  final String email;
  final double monthlySalary;
  final String profession;
  final String name;
  final String photoUrl;
  final double survivalPct;
  final double transportPct;
  final double stylePct;
  final double entertainmentPct;
  final double emergencyPct;
  final double goalsPct;

  UserModel({
    required this.uid,
    required this.email,
    required this.monthlySalary,
    required this.profession,
    this.name = '',
    this.photoUrl = '',
    this.survivalPct = 40.0,
    this.transportPct = 10.0,
    this.stylePct = 10.0,
    this.entertainmentPct = 10.0,
    this.emergencyPct = 10.0,
    this.goalsPct = 20.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'monthlySalary': monthlySalary,
      'profession': profession,
      'name': name,
      'photoUrl': photoUrl,
      'survivalPct': survivalPct,
      'transportPct': transportPct,
      'stylePct': stylePct,
      'entertainmentPct': entertainmentPct,
      'emergencyPct': emergencyPct,
      'goalsPct': goalsPct,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      monthlySalary: (map['monthlySalary'] as num?)?.toDouble() ?? 0.0,
      profession: map['profession'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      survivalPct: (map['survivalPct'] as num?)?.toDouble() ?? 40.0,
      transportPct: (map['transportPct'] as num?)?.toDouble() ?? 10.0,
      stylePct: (map['stylePct'] as num?)?.toDouble() ?? 10.0,
      entertainmentPct: (map['entertainmentPct'] as num?)?.toDouble() ?? 10.0,
      emergencyPct: (map['emergencyPct'] as num?)?.toDouble() ?? 10.0,
      goalsPct: (map['goalsPct'] as num?)?.toDouble() ?? 20.0,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    double? monthlySalary,
    String? profession,
    String? name,
    String? photoUrl,
    double? survivalPct,
    double? transportPct,
    double? stylePct,
    double? entertainmentPct,
    double? emergencyPct,
    double? goalsPct,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      profession: profession ?? this.profession,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      survivalPct: survivalPct ?? this.survivalPct,
      transportPct: transportPct ?? this.transportPct,
      stylePct: stylePct ?? this.stylePct,
      entertainmentPct: entertainmentPct ?? this.entertainmentPct,
      emergencyPct: emergencyPct ?? this.emergencyPct,
      goalsPct: goalsPct ?? this.goalsPct,
    );
  }
}
