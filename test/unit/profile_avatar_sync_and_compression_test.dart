import 'package:flutter_test/flutter_test.dart';
import 'package:fit_host/core/services/profile_avatar_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileAvatarService Identifier Categorization Tests', () {
    test('isAssetAvatar identifies bundled presets, assets, and monogram', () {
      expect(ProfileAvatarService.isAssetAvatar(null), isTrue);
      expect(ProfileAvatarService.isAssetAvatar(''), isTrue);
      expect(ProfileAvatarService.isAssetAvatar('initial'), isTrue);
      expect(ProfileAvatarService.isAssetAvatar('default'), isTrue);
      expect(ProfileAvatarService.isAssetAvatar('avatar_male_1'), isTrue);
      expect(ProfileAvatarService.isAssetAvatar('avatar_male_2'), isTrue);
      expect(ProfileAvatarService.isAssetAvatar('avatar_female_1'), isTrue);
      expect(ProfileAvatarService.isAssetAvatar('avatar_female_2'), isTrue);
      expect(ProfileAvatarService.isAssetAvatar('avatar_neutral'), isTrue);
      expect(
        ProfileAvatarService.isAssetAvatar(
          'assets/images/avatars/avatar_male_1.png',
        ),
        isTrue,
      );

      // Custom file paths and network URLs must NOT be treated as asset avatars
      expect(
        ProfileAvatarService.isAssetAvatar(
          '/data/user/0/com.fithost.fit_host/avatar.webp',
        ),
        isFalse,
      );
      expect(
        ProfileAvatarService.isAssetAvatar('/Users/test/Documents/photo.jpg'),
        isFalse,
      );
      expect(
        ProfileAvatarService.isAssetAvatar(
          'https://api.amitrana.tech/storage/v1/object/public/avatars/user.webp',
        ),
        isFalse,
      );
    });

    test('isDefaultProfileImage identifies unconfigured/default states', () {
      expect(ProfileAvatarService.isDefaultProfileImage(null), isTrue);
      expect(ProfileAvatarService.isDefaultProfileImage(''), isTrue);
      expect(ProfileAvatarService.isDefaultProfileImage('initial'), isTrue);
      expect(ProfileAvatarService.isDefaultProfileImage('default'), isTrue);

      // Explicit chosen avatars or custom photos are not default
      expect(
        ProfileAvatarService.isDefaultProfileImage('avatar_male_1'),
        isFalse,
      );
      expect(
        ProfileAvatarService.isDefaultProfileImage('avatar_female_1'),
        isFalse,
      );
      expect(
        ProfileAvatarService.isDefaultProfileImage('/data/user/0/avatar.webp'),
        isFalse,
      );
      expect(
        ProfileAvatarService.isDefaultProfileImage(
          'https://example.com/avatar.png',
        ),
        isFalse,
      );
    });

    test(
      'isCustomDeviceAvatar accurately identifies local device store paths',
      () {
        expect(
          ProfileAvatarService.isCustomDeviceAvatar(
            '/data/user/0/com.fithost/profile_avatars/avatar_123.webp',
          ),
          isTrue,
        );
        expect(
          ProfileAvatarService.isCustomDeviceAvatar(
            '/private/var/mobile/Containers/avatar_456.webp',
          ),
          isTrue,
        );

        // Must be false for assets, defaults, and URLs
        expect(ProfileAvatarService.isCustomDeviceAvatar(null), isFalse);
        expect(ProfileAvatarService.isCustomDeviceAvatar(''), isFalse);
        expect(ProfileAvatarService.isCustomDeviceAvatar('initial'), isFalse);
        expect(
          ProfileAvatarService.isCustomDeviceAvatar('avatar_male_1'),
          isFalse,
        );
        expect(
          ProfileAvatarService.isCustomDeviceAvatar(
            'assets/images/avatars/avatar_neutral.png',
          ),
          isFalse,
        );
        expect(
          ProfileAvatarService.isCustomDeviceAvatar(
            'https://supabase.co/storage/avatars/user.webp',
          ),
          isFalse,
        );
        expect(
          ProfileAvatarService.isCustomDeviceAvatar(
            'http://example.com/photo.jpg',
          ),
          isFalse,
        );
      },
    );

    test(
      'syncAvatarToRemoteStorage skips cloud upload for asset and default avatars',
      () async {
        // 1. Monogram initial should return as-is without attempting upload
        final initialResult =
            await ProfileAvatarService.syncAvatarToRemoteStorage(
              userId: 'test-user-123',
              localOrRemotePath: 'initial',
            );
        expect(initialResult, equals('initial'));

        // 2. Preset asset avatar should return as-is without attempting upload
        final assetResult =
            await ProfileAvatarService.syncAvatarToRemoteStorage(
              userId: 'test-user-123',
              localOrRemotePath: 'avatar_male_1',
            );
        expect(assetResult, equals('avatar_male_1'));

        // 3. Remote URL should return as-is without re-uploading
        const remoteUrl =
            'https://api.amitrana.tech/storage/v1/object/public/avatars/user.webp';
        final urlResult = await ProfileAvatarService.syncAvatarToRemoteStorage(
          userId: 'test-user-123',
          localOrRemotePath: remoteUrl,
        );
        expect(urlResult, equals(remoteUrl));
      },
    );

    test(
      'Non-existent local file path returns path safely without crash',
      () async {
        const nonExistent = '/tmp/definitely_not_existing_avatar_9999.webp';
        final result = await ProfileAvatarService.syncAvatarToRemoteStorage(
          userId: 'test-user-123',
          localOrRemotePath: nonExistent,
        );
        expect(result, equals(nonExistent));
      },
    );
  });
}
