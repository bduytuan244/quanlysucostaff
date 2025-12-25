class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String phone;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.phone
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String doccumentId) {
    return UserModel(id: doccumentId, name: map['name'] ?? '', email: map['email'] ?? '', role: map['role'] ?? 'technician', isActive: map['isActive']?? true, phone: map['phone']);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
    };
  }
}