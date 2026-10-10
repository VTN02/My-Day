import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/update_service.dart';

void main() {
  group('UpdateService Version Comparison', () {
    test('Correctly identifies newer patch version (1.1.1 > 1.1.0)', () {
      expect(UpdateService.compareVersions('1.1.1', '1.1.0'), greaterThan(0));
      expect(
        UpdateService.isVersionNewer(
          remoteVersion: '1.1.1',
          remoteBuildCode: 4,
          currentVersion: '1.1.0',
          currentBuildCode: 3,
        ),
        isTrue,
      );
    });

    test('Correctly identifies newer minor version (1.2.0 > 1.1.9)', () {
      expect(UpdateService.compareVersions('1.2.0', '1.1.9'), greaterThan(0));
      expect(
        UpdateService.isVersionNewer(
          remoteVersion: 'v1.2.0',
          remoteBuildCode: 10,
          currentVersion: '1.1.9',
          currentBuildCode: 9,
        ),
        isTrue,
      );
    });

    test('Correctly identifies newer major version (2.0.0 > 1.9.9)', () {
      expect(UpdateService.compareVersions('2.0.0', '1.9.9'), greaterThan(0));
      expect(
        UpdateService.isVersionNewer(
          remoteVersion: '2.0.0',
          remoteBuildCode: 20,
          currentVersion: '1.9.9',
          currentBuildCode: 15,
        ),
        isTrue,
      );
    });

    test('Identifies older or equal versions as not newer', () {
      expect(UpdateService.compareVersions('1.1.0', '1.1.1'), lessThan(0));
      expect(
        UpdateService.isVersionNewer(
          remoteVersion: '1.1.0',
          remoteBuildCode: 3,
          currentVersion: '1.1.1',
          currentBuildCode: 4,
        ),
        isFalse,
      );

      // Same version and same build code
      expect(
        UpdateService.isVersionNewer(
          remoteVersion: '1.1.1',
          remoteBuildCode: 4,
          currentVersion: '1.1.1',
          currentBuildCode: 4,
        ),
        isFalse,
      );
    });

    test('Identifies same version with higher build number as newer', () {
      expect(
        UpdateService.isVersionNewer(
          remoteVersion: '1.1.1',
          remoteBuildCode: 5,
          currentVersion: '1.1.1',
          currentBuildCode: 4,
        ),
        isTrue,
      );
    });
  });

  group('GitHub Release Parser', () {
    test('Parses GitHub Release API response accurately', () {
      final mockGitHubJson = {
        'tag_name': 'v1.1.1',
        'name': 'MyDay v1.1.1 - Live Budget & UI Refinements',
        'published_at': '2026-10-10T19:49:55Z',
        'html_url': 'https://github.com/VTN02/My-Day/releases/tag/v1.1.1',
        'body':
            '## What\'s New in v1.1.1 🎉\r\n\r\n- ⚡ Live Budget Usage Updates\r\n- 📄 Professional Accounting PDF Export\r\n- 📌 Pinned Sticky Headers\r\n',
        'assets': [
          {
            'name': 'myday-v1.1.1.apk',
            'size': 75972230,
            'browser_download_url':
                'https://github.com/VTN02/My-Day/releases/download/v1.1.1/myday-v1.1.1.apk',
          },
        ],
      };

      final info = AppUpdateInfo.fromGitHubRelease(mockGitHubJson);

      expect(info.latestVersion, equals('1.1.1'));
      expect(
        info.apkDownloadUrl,
        equals(
          'https://github.com/VTN02/My-Day/releases/download/v1.1.1/myday-v1.1.1.apk',
        ),
      );
      expect(info.fileSize, equals('72 MB'));
      expect(info.releaseNotes.length, equals(3));
      expect(info.releaseNotes[0], contains('Live Budget Usage Updates'));
    });
  });
}
