class User {
  final String id;
  String name;
  String email;
  String? profileImagePath;
  DateTime createdAt;
  Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImagePath,
    required this.createdAt,
    Map<String, dynamic>? preferences,
  }) : preferences = preferences ?? {};

  String get firstName {
    return name.split(' ').first;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImagePath': profileImagePath,
      'createdAt': createdAt.toIso8601String(),
      'preferences': preferences,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImagePath: json['profileImagePath'],
      createdAt: DateTime.parse(json['createdAt']),
      preferences: json['preferences'] ?? {},
    );
  }

  void updatePreference(String key, dynamic value) {
    preferences[key] = value;
  }

  T getPreference<T>(String key, T defaultValue) {
    return preferences.containsKey(key) ? preferences[key] as T : defaultValue;
  }
}