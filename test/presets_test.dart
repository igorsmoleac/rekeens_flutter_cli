import 'package:rekeens_flutter_cli/config/presets.dart';
import 'package:test/test.dart';

void main() {
  group('presets map', () {
    test('contains minimal, mobile, and full presets', () {
      expect(presets.keys, containsAll(['minimal', 'mobile', 'full']));
    });

    test('has exactly three presets', () {
      expect(presets.length, 3);
    });
  });

  group('minimal preset', () {
    final preset = presets['minimal']!;

    test('has correct name', () {
      expect(preset.name, 'minimal');
    });

    test('targets android and ios only', () {
      expect(preset.platforms, ['android', 'ios']);
    });

    test('uses feature-first architecture', () {
      expect(preset.architecture, 'feature-first');
    });

    test('has no state management', () {
      expect(preset.stateManagement, 'none');
    });

    test('has no router', () {
      expect(preset.router, 'none');
    });

    test('has no networking', () {
      expect(preset.networking, 'none');
    });

    test('disables localization', () {
      expect(preset.localization, isFalse);
    });

    test('uses material3 theme', () {
      expect(preset.theme, 'material3');
    });

    test('disables codegen by default', () {
      expect(preset.codegen, isFalse);
    });
  });

  group('mobile preset', () {
    final preset = presets['mobile']!;

    test('has correct name', () {
      expect(preset.name, 'mobile');
    });

    test('targets android and ios', () {
      expect(preset.platforms, ['android', 'ios']);
    });

    test('uses riverpod state management', () {
      expect(preset.stateManagement, 'riverpod');
    });

    test('uses go_router', () {
      expect(preset.router, 'go_router');
    });

    test('uses dio networking', () {
      expect(preset.networking, 'dio');
    });

    test('enables localization', () {
      expect(preset.localization, isTrue);
    });

    test('disables codegen', () {
      expect(preset.codegen, isFalse);
    });
  });

  group('full preset', () {
    final preset = presets['full']!;

    test('has correct name', () {
      expect(preset.name, 'full');
    });

    test('targets all six platforms', () {
      expect(preset.platforms, [
        'android',
        'ios',
        'windows',
        'linux',
        'macos',
        'web',
      ]);
    });

    test('uses riverpod state management', () {
      expect(preset.stateManagement, 'riverpod');
    });

    test('uses go_router', () {
      expect(preset.router, 'go_router');
    });

    test('uses dio networking', () {
      expect(preset.networking, 'dio');
    });

    test('enables localization', () {
      expect(preset.localization, isTrue);
    });

    test('enables codegen', () {
      expect(preset.codegen, isTrue);
    });
  });

  group('Preset.toOptions', () {
    test('returns a map with all expected keys', () {
      final options = presets['mobile']!.toOptions();

      expect(options.keys, containsAll([
        'platforms',
        'architecture',
        'state_management',
        'router',
        'networking',
        'localization',
        'theme',
        'codegen',
      ]));
    });

    test('platforms is a List', () {
      final options = presets['full']!.toOptions();
      expect(options['platforms'], isA<List>());
    });

    test('state_management matches preset', () {
      final options = presets['minimal']!.toOptions();
      expect(options['state_management'], 'none');
    });

    test('codegen reflects preset value', () {
      expect(presets['minimal']!.toOptions()['codegen'], isFalse);
      expect(presets['full']!.toOptions()['codegen'], isTrue);
    });

    test('localization reflects preset value', () {
      expect(presets['minimal']!.toOptions()['localization'], isFalse);
      expect(presets['mobile']!.toOptions()['localization'], isTrue);
    });
  });
}
