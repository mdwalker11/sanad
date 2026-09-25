import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/workers/worker_profile.dart';

void main() {
  test('worker profile rejects blank bio', () {
    expect(
      () => WorkerProfileDraft(
        userId: 'worker-1',
        bio: ' ',
        yearsExperience: 2,
        gender: 'male',
        hasTools: true,
        hasTransport: true,
      ),
      throwsArgumentError,
    );
  });

  test('worker profile rejects negative experience', () {
    expect(
      () => WorkerProfileDraft(
        userId: 'worker-1',
        bio: 'فني تكييف',
        yearsExperience: -1,
        gender: 'male',
        hasTools: true,
        hasTransport: true,
      ),
      throwsArgumentError,
    );
  });
}
