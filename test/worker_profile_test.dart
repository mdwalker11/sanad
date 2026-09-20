import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/workers/worker_profile.dart';

void main() {
  test('worker profile creates safe insert payload', () {
    final profile = WorkerProfileDraft(
      userId: 'worker-1',
      bio: 'فني تكييف',
      yearsExperience: 5,
      gender: 'male',
      hasTools: true,
      hasTransport: false,
    );

    expect(profile.toInsertMap(), {
      'user_id': 'worker-1',
      'bio': 'فني تكييف',
      'years_experience': 5,
      'gender': 'male',
      'has_tools': true,
      'has_transport': false,
      'verification_status': 'pending',
    });
  });
}
