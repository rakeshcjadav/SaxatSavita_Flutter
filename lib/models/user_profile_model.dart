class UserProfile {
  final String firstName;
  final String lastName;
  final String city;
  final String email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.city,
    required this.email,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      city: json['city'] ?? '',
      email: json['email'] ?? '',
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'city': city,
      'email': email,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? city,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      city: city ?? this.city,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  @override
  String toString() {
    return 'UserProfile(firstName: $firstName, lastName: $lastName, city: $city, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.city == city &&
        other.email == email;
  }

  @override
  int get hashCode {
    return firstName.hashCode ^
        lastName.hashCode ^
        city.hashCode ^
        email.hashCode;
  }
}
