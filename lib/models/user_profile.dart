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

  Map<String, dynamic> toPatchJson({required UserProfile previous}) {
    String? norm(String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return trimmed;
    }

    String? dateOnly(DateTime? value) => value?.toIso8601String().split('T').first;

    final patch = <String, dynamic>{};

    final nextFullName = norm(fullName);
    final prevFullName = norm(previous.fullName);
    if (nextFullName != prevFullName) patch['full_name'] = nextFullName;

    final nextEmail = norm(email);
    final prevEmail = norm(previous.email);
    if (nextEmail != prevEmail) patch['email'] = nextEmail;

    if (age != previous.age) patch['age'] = age;

    final nextGender = norm(gender);
    final prevGender = norm(previous.gender);
    if (nextGender != prevGender) patch['gender'] = nextGender;

    final nextProfession = norm(profession);
    final prevProfession = norm(previous.profession);
    if (nextProfession != prevProfession) patch['profession'] = nextProfession;

    final nextBio = norm(bio);
    final prevBio = norm(previous.bio);
    if (nextBio != prevBio) patch['bio'] = nextBio;

    final nextPhoto = norm(profileImageUrl);
    final prevPhoto = norm(previous.profileImageUrl);
    if (nextPhoto != prevPhoto) patch['profile_image_url'] = nextPhoto;

    if (goalAmountRwf != previous.goalAmountRwf) {
      patch['goal_amount_rwf'] = goalAmountRwf;
    }

    final nextGoalDate = dateOnly(goalTargetDate);
    final prevGoalDate = dateOnly(previous.goalTargetDate);
    if (nextGoalDate != prevGoalDate) patch['goal_target_date'] = nextGoalDate;

    return patch;
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
