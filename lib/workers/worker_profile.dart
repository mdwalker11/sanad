class WorkerProfileDraft {
  WorkerProfileDraft({
    required this.userId,
    required this.bio,
    required this.yearsExperience,
    required this.gender,
    required this.hasTools,
    required this.hasTransport,
  }) {
    if (userId.trim().isEmpty || bio.trim().isEmpty) {
      throw ArgumentError('بيانات ملف العامل ناقصة');
    }
    if (yearsExperience < 0) {
      throw ArgumentError('سنوات الخبرة غير صالحة');
    }
  }

  final String userId;
  final String bio;
  final int yearsExperience;
  final String gender;
  final bool hasTools;
  final bool hasTransport;

  Map<String, dynamic> toInsertMap() => {
    'user_id': userId,
    'bio': bio.trim(),
    'years_experience': yearsExperience,
    'gender': gender,
    'has_tools': hasTools,
    'has_transport': hasTransport,
    'verification_status': 'pending',
  };
}
