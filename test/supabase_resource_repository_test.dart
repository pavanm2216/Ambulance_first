import 'package:ambulance_first/core/services/supabase_resource_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseResourceRepository.isAmbulanceAvailable', () {
    test('accepts the live AVAILABLE enum value regardless of casing', () {
      expect(
        SupabaseResourceRepository.isAmbulanceAvailable(
          {'status': ' available '},
        ),
        isTrue,
      );
    });

    test('does not convert absent or non-available status to availability', () {
      expect(
        SupabaseResourceRepository.isAmbulanceAvailable({}),
        isFalse,
      );
      expect(
        SupabaseResourceRepository.isAmbulanceAvailable(
          {'status': 'OFFLINE'},
        ),
        isFalse,
      );
    });
  });
}
