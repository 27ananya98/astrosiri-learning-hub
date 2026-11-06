class User {
  final String id;
  final String? email;
  final String? mobile;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final bool isNewUser;
  final String? loginContact;
  final String? accessToken;
  final String? refreshToken;

  // Additional rich profile fields
  final String? experience;
  final String? bio;
  final List<String> languages;
  final List<String> areasOfInterest;
  final List<String> preferredSubjects;
  final String? dob;
  final String? city;
  final String? state;
  final String? gender;
  final String? country;
  final String? address;
  final bool isProfileCompleted;
  final int streakDays;
  final int pointsThisWeek;
  final List<String> completedLessons;
  final List<String> certificates;

  const User({
    required this.id,
    this.email,
    this.mobile,
    required this.fullName,
    this.role = '',
    this.avatarUrl,
    this.isNewUser = false,
    this.loginContact,
    this.accessToken,
    this.refreshToken,
    this.experience,
    this.bio,
    this.languages = const [],
    this.areasOfInterest = const [],
    this.preferredSubjects = const [],
    this.dob,
    this.city,
    this.state,
    this.gender,
    this.country,
    this.address,
    this.isProfileCompleted = false,
    this.streakDays = 0,
    this.pointsThisWeek = 0,
    this.completedLessons = const [],
    this.certificates = const [],
  });

  factory User.fromJson(
    Map<String, dynamic> json, {
    String? accessToken,
    String? refreshToken,
    bool? isNewUser,
    String? fallbackIdentifier,
  }) {
    final userData = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic>
              ? (json['data']['user'] is Map<String, dynamic>
                    ? json['data']['user'] as Map<String, dynamic>
                    : json['data'] as Map<String, dynamic>)
              : json);

    final emailVal =
        userData['email']?.toString() ??
        (fallbackIdentifier != null && fallbackIdentifier.contains('@')
            ? fallbackIdentifier
            : null);

    final mobileVal =
        userData['mobile']?.toString() ??
        (fallbackIdentifier != null && !fallbackIdentifier.contains('@')
            ? fallbackIdentifier
            : null);

    final loginContactVal =
        (userData['loginContact']?.toString() ??
        (fallbackIdentifier != null
            ? (fallbackIdentifier.contains('@') ? 'EMAIL' : 'MOBILE')
            : null));

    final personalDetails = userData['personalDetails'] is Map<String, dynamic>
        ? userData['personalDetails'] as Map<String, dynamic>
        : null;

    final dataMap = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : null;
    final tokensMap = json['tokens'] is Map<String, dynamic>
        ? json['tokens'] as Map<String, dynamic>
        : (dataMap != null && dataMap['tokens'] is Map<String, dynamic>
              ? dataMap['tokens'] as Map<String, dynamic>
              : null);

    final List<String> parsedLanguages = [];
    final rawLanguages =
        userData['languages'] ?? dataMap?['languages'] ?? json['languages'];
    if (rawLanguages is List) {
      for (var l in rawLanguages) {
        if (l != null) parsedLanguages.add(l.toString());
      }
    }

    final List<String> parsedAreas = [];
    final rawAreas =
        userData['areasOfInterest'] ??
        dataMap?['areasOfInterest'] ??
        json['areasOfInterest'];
    if (rawAreas is List) {
      for (var a in rawAreas) {
        if (a != null) parsedAreas.add(a.toString());
      }
    }

    final List<String> parsedPreferred = [];
    final rawPreferred =
        userData['preferredSubjects'] ??
        dataMap?['preferredSubjects'] ??
        json['preferredSubjects'];
    if (rawPreferred is List) {
      for (var p in rawPreferred) {
        if (p != null) parsedPreferred.add(p.toString());
      }
    }

    final List<String> parsedLessons = [];
    final rawLessons =
        userData['completedLessons'] ??
        dataMap?['completedLessons'] ??
        json['completedLessons'];
    if (rawLessons is List) {
      for (var l in rawLessons) {
        if (l != null) parsedLessons.add(l.toString());
      }
    }

    final List<String> parsedCertificates = [];
    final rawCertificates =
        userData['certificates'] ??
        dataMap?['certificates'] ??
        json['certificates'];
    if (rawCertificates is List) {
      for (var c in rawCertificates) {
        if (c != null) {
          if (c is Map) {
            parsedCertificates.add(
              c['title']?.toString() ??
                  c['name']?.toString() ??
                  c['id']?.toString() ??
                  'Certificate',
            );
          } else {
            parsedCertificates.add(c.toString());
          }
        }
      }
    }

    return User(
      id: (userData['id'] ?? userData['_id'] ?? '').toString(),
      email: emailVal,
      mobile: mobileVal,
      fullName: (userData['fullName'] ?? userData['name'] ?? '').toString(),
      role: userData['role']?.toString() ?? '',
      avatarUrl:
          userData['avatarUrl']?.toString() ?? userData['picture']?.toString(),
      isNewUser: isNewUser ?? (json['isNewUser'] as bool? ?? false),
      loginContact: loginContactVal,
      accessToken:
          accessToken ??
          json['accessToken']?.toString() ??
          json['access_token']?.toString() ??
          json['token']?.toString() ??
          dataMap?['accessToken']?.toString() ??
          dataMap?['access_token']?.toString() ??
          dataMap?['token']?.toString() ??
          tokensMap?['accessToken']?.toString() ??
          tokensMap?['access_token']?.toString() ??
          tokensMap?['token']?.toString(),
      refreshToken:
          refreshToken ??
          json['refreshToken']?.toString() ??
          json['refresh_token']?.toString() ??
          dataMap?['refreshToken']?.toString() ??
          dataMap?['refresh_token']?.toString() ??
          tokensMap?['refreshToken']?.toString() ??
          tokensMap?['refresh_token']?.toString(),
      experience: userData['experience']?.toString(),
      bio: userData['bio']?.toString(),
      languages: parsedLanguages.isNotEmpty ? parsedLanguages : const [],
      areasOfInterest: parsedAreas,
      preferredSubjects: parsedPreferred,
      dob: personalDetails?['dob']?.toString() ?? userData['dob']?.toString(),
      city:
          personalDetails?['city']?.toString() ?? userData['city']?.toString(),
      state:
          personalDetails?['state']?.toString() ??
          userData['state']?.toString(),
      gender:
          personalDetails?['gender']?.toString() ??
          userData['gender']?.toString(),
      country:
          personalDetails?['country']?.toString() ??
          userData['country']?.toString(),
      address:
          personalDetails?['address']?.toString() ??
          userData['address']?.toString(),
      isProfileCompleted:
          userData['isProfileCompleted'] as bool? ??
          personalDetails?['isProfileCompleted'] as bool? ??
          false,
      streakDays: (userData['streakDays'] as num?)?.toInt() ?? 0,
      pointsThisWeek: (userData['pointsThisWeek'] as num?)?.toInt() ?? 0,
      completedLessons: parsedLessons,
      certificates: parsedCertificates,
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? mobile,
    String? fullName,
    String? role,
    String? avatarUrl,
    bool? isNewUser,
    String? loginContact,
    String? accessToken,
    String? refreshToken,
    String? experience,
    String? bio,
    List<String>? languages,
    List<String>? areasOfInterest,
    List<String>? preferredSubjects,
    String? dob,
    String? city,
    String? state,
    String? gender,
    String? country,
    String? address,
    bool? isProfileCompleted,
    int? streakDays,
    int? pointsThisWeek,
    List<String>? completedLessons,
    List<String>? certificates,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isNewUser: isNewUser ?? this.isNewUser,
      loginContact: loginContact ?? this.loginContact,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      experience: experience ?? this.experience,
      bio: bio ?? this.bio,
      languages: languages ?? this.languages,
      areasOfInterest: areasOfInterest ?? this.areasOfInterest,
      preferredSubjects: preferredSubjects ?? this.preferredSubjects,
      dob: dob ?? this.dob,
      city: city ?? this.city,
      state: state ?? this.state,
      gender: gender ?? this.gender,
      country: country ?? this.country,
      address: address ?? this.address,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      streakDays: streakDays ?? this.streakDays,
      pointsThisWeek: pointsThisWeek ?? this.pointsThisWeek,
      completedLessons: completedLessons ?? this.completedLessons,
      certificates: certificates ?? this.certificates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'mobile': mobile,
      'fullName': fullName,
      'role': role,
      'avatarUrl': avatarUrl,
      'isNewUser': isNewUser,
      'loginContact': loginContact,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'experience': experience,
      'bio': bio,
      'languages': languages,
      'areasOfInterest': areasOfInterest,
      'preferredSubjects': preferredSubjects,
      'dob': dob,
      'city': city,
      'state': state,
      'gender': gender,
      'country': country,
      'address': address,
      'isProfileCompleted': isProfileCompleted,
      'streakDays': streakDays,
      'pointsThisWeek': pointsThisWeek,
      'completedLessons': completedLessons,
      'certificates': certificates,
    };
  }
}
