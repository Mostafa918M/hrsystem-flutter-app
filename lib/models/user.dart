class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? profileImage;
  final String? employeeId;
  final int annualLeaveBalance;
  final int sickLeaveBalance;
  final int emergencyLeaveBalance;
  final double loans;
  final bool mustChangePassword;
  final Map<String, bool> enabledFeatures;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImage,
    this.employeeId,
    this.annualLeaveBalance = 0,
    this.sickLeaveBalance = 0,
    this.emergencyLeaveBalance = 0,
    this.loans = 0.0,
    this.mustChangePassword = false,
    this.enabledFeatures = const {},
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final featuresJson = json['enabledFeatures'] as Map<String, dynamic>? ?? {};
    final Map<String, bool> featuresMap = {};
    featuresJson.forEach((key, value) {
      if (value is bool) {
        featuresMap[key] = value;
      }
    });

    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['fullName'] ?? json['name'] ?? 'Unknown User',
      email: json['email'] ?? '',
      role: json['role'] ?? 'employee',
      profileImage: json['profileImage'],
      employeeId: json['employeeId']?.toString(),
      annualLeaveBalance: json['annualLeaveBalance'] ?? 0,
      sickLeaveBalance: json['sickLeaveBalance'] ?? 0,
      emergencyLeaveBalance: json['emergencyLeaveBalance'] ?? 0,
      loans: (json['loans'] as num?)?.toDouble() ?? 0.0,
      mustChangePassword: json['mustChangePassword'] ?? false,
      enabledFeatures: featuresMap,
    );
  }
}
