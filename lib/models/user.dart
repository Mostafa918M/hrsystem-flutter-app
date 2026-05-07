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
  });

  factory User.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
