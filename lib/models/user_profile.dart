class UserProfile {
  UserProfile({
    required this.userId,
    this.phoneNumber,
    this.email,
    this.username,
    this.fullName,
    this.age,
    this.gender,
    this.profession,
    this.bio,
    this.profileImageUrl,
    this.goalAmountRwf,
    this.goalTargetDate,
  });

  final String userId;
  final String? phoneNumber;
  final String? email;
  final String? username;
  final String? fullName;
  final int? age;
  final String? gender;
  final String? profession;
  final String? bio;
  final String? profileImageUrl;
  final double? goalAmountRwf;
  final DateTime? goalTargetDate;

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!.trim();
    if (username != null && username!.trim().isNotEmpty) return username!.trim();
    if (email != null && email!.trim().isNotEmpty) return email!.trim();
    if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) return phoneNumber!.trim();
    return 'Guest';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      email: json['email']?.toString(),
      username: json['username']?.toString(),
      fullName: json['full_name']?.toString(),
      age: json['age'] == null ? null : int.tryParse(json['age'].toString()),
      gender: json['gender']?.toString(),
      profession: json['profession']?.toString(),
      bio: json['bio']?.toString(),
      profileImageUrl: json['profile_image_url']?.toString(),
      goalAmountRwf: json['goal_amount_rwf'] == null
          ? null
          : double.tryParse(json['goal_amount_rwf'].toString()),
      goalTargetDate: json['goal_target_date'] == null
          ? null
          : DateTime.tryParse(json['goal_target_date'].toString()),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'full_name': fullName,
      'email': email,
      'age': age,
      'gender': gender,
      'profession': profession,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'goal_amount_rwf': goalAmountRwf,
      'goal_target_date': goalTargetDate?.toIso8601String().split('T').first,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? username,
    int? age,
    String? gender,
    String? profession,
    String? bio,
    String? profileImageUrl,
    double? goalAmountRwf,
    DateTime? goalTargetDate,
  }) {
    return UserProfile(
      userId: userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      username: username ?? this.username,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      profession: profession ?? this.profession,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      goalAmountRwf: goalAmountRwf ?? this.goalAmountRwf,
      goalTargetDate: goalTargetDate ?? this.goalTargetDate,
    );
  }
}
