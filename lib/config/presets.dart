class Preset {
  const Preset({
    required this.name,
    required this.platforms,
    required this.architecture,
    required this.stateManagement,
    required this.router,
    required this.networking,
    required this.storage,
    required this.localization,
    required this.theme,
    this.codegen = false,
  });
  final String name;
  final List<String> platforms;
  final String architecture;
  final String stateManagement;
  final String router;
  final String networking;
  final String storage;
  final bool localization;
  final String theme;
  final bool codegen;

  Map<String, dynamic> toOptions() {
    return {
      'platforms': platforms,
      'architecture': architecture,
      'state_management': stateManagement,
      'router': router,
      'networking': networking,
      'storage': storage,
      'localization': localization,
      'theme': theme,
      'codegen': codegen,
    };
  }
}

const presets = <String, Preset>{
  'minimal': Preset(
    name: 'minimal',
    platforms: ['android', 'ios'],
    architecture: 'feature-first',
    stateManagement: 'none',
    router: 'none',
    networking: 'none',
    storage: 'none',
    localization: false,
    theme: 'material3',
  ),
  'mobile': Preset(
    name: 'mobile',
    platforms: ['android', 'ios'],
    architecture: 'feature-first',
    stateManagement: 'riverpod',
    router: 'go_router',
    networking: 'dio',
    storage: 'shared_preferences',
    localization: true,
    theme: 'material3',
  ),
  'full': Preset(
    name: 'full',
    platforms: ['android', 'ios', 'windows', 'linux', 'macos', 'web'],
    architecture: 'feature-first',
    stateManagement: 'riverpod',
    router: 'go_router',
    networking: 'dio',
    storage: 'secure_storage',
    localization: true,
    theme: 'material3',
    codegen: true,
  ),
};
