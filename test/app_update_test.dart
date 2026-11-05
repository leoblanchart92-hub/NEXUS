import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:nexus/app_update.dart';

void main() {
  test('les versions se comparent du plus ancien au plus récent', () {
    expect(compareVersions('0.10.0', '0.9.0'), greaterThan(0));
    expect(compareVersions('0.9.0', '0.10.0'), lessThan(0));
    expect(compareVersions('0.10.0', '0.10.0'), 0);
    expect(compareVersions('0.10.0', '0.10.0+12'), 0);
    expect(compareVersions('0.10.1', '0.10.0'), greaterThan(0));
    expect(compareVersions('1.0.0', '0.99.99'), greaterThan(0));
  });

  test('la signature correspond exactement à celle calculée par la CI', () {
    // Même commande que le workflow :
    // printf '%s' "0.10.0|https://example.com/nexus.apk|<sha>" \
    //   | openssl dgst -sha256 -hmac "cle-de-test" -hex
    expect(
      signManifest(
        key: 'cle-de-test',
        version: '0.10.0',
        url: 'https://example.com/nexus.apk',
        sha256: 'a' * 64,
      ),
      'f959e8a3ef943d2effb43c1be05263aad38cb38a461ff03a72f2142b90f8cd55',
    );
  });

  test('nexusVersion reste aligné sur pubspec.yaml', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final RegExpMatch? match =
        RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)', multiLine: true)
            .firstMatch(pubspec);
    expect(match, isNotNull, reason: 'version: introuvable dans pubspec.yaml');
    expect(
      match!.group(1),
      nexusVersion,
      reason: 'mets à jour nexusVersion dans lib/app_update.dart',
    );
  });
}
