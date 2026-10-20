import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/features/profile/presentation/widgets/avatar_picker_sheet.dart';

void main() {
  group('AvatarPickerSheet gender filtering tests', () {
    test('male user sees male + neutral + initial avatars only', () {
      final options = getAvailableAvatarOptions('male');
      final ids = options.map((o) => o.id).toList();

      expect(options.length, equals(4));
      expect(ids, contains('avatar_male_1'));
      expect(ids, contains('avatar_male_2'));
      expect(ids, contains('avatar_neutral'));
      expect(ids, contains('initial'));

      expect(ids, isNot(contains('avatar_female_1')));
      expect(ids, isNot(contains('avatar_female_2')));
    });

    test('female user sees female + neutral + initial avatars only', () {
      final options = getAvailableAvatarOptions('female');
      final ids = options.map((o) => o.id).toList();

      expect(options.length, equals(4));
      expect(ids, contains('avatar_female_1'));
      expect(ids, contains('avatar_female_2'));
      expect(ids, contains('avatar_neutral'));
      expect(ids, contains('initial'));

      expect(ids, isNot(contains('avatar_male_1')));
      expect(ids, isNot(contains('avatar_male_2')));
    });

    test('unspecified or other user sees all 6 avatar options', () {
      final otherOptions = getAvailableAvatarOptions('other');
      expect(otherOptions.length, equals(6));

      final nullOptions = getAvailableAvatarOptions(null);
      expect(nullOptions.length, equals(6));

      final emptyOptions = getAvailableAvatarOptions('');
      expect(emptyOptions.length, equals(6));

      final allIds = otherOptions.map((o) => o.id).toSet();
      expect(
        allIds,
        equals({
          'avatar_male_1',
          'avatar_male_2',
          'avatar_female_1',
          'avatar_female_2',
          'avatar_neutral',
          'initial',
        }),
      );
    });

    test('getAvatarAssetPath resolves correct asset png path or null for initial',
        () {
      expect(
        getAvatarAssetPath('avatar_male_1'),
        equals('assets/images/avatars/avatar_male_1.png'),
      );
      expect(
        getAvatarAssetPath('male_1'),
        equals('assets/images/avatars/avatar_male_1.png'),
      );
      expect(
        getAvatarAssetPath('avatar_female_2'),
        equals('assets/images/avatars/avatar_female_2.png'),
      );
      expect(
        getAvatarAssetPath('avatar_neutral'),
        equals('assets/images/avatars/avatar_neutral.png'),
      );
      expect(getAvatarAssetPath('initial'), isNull);
      expect(getAvatarAssetPath(null), isNull);
    });
  });
}
