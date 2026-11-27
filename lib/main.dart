import 'package:flutter/material.dart';
import 'package:native_platform_ui/native_platform_ui.dart';

void main() => runApp(const PlaygroundApp());

class PlaygroundApp extends StatefulWidget {
  const PlaygroundApp({super.key});

  @override
  State<PlaygroundApp> createState() => _PlaygroundAppState();
}

class _PlaygroundAppState extends State<PlaygroundApp> {
  bool _dark = false; //false

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Native UI Playground',
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5277C3)),
        scaffoldBackgroundColor: const Color(0xFFF4F4F7),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8BA9E8),
          brightness: Brightness.dark,
        ),
      ),
      home: PlaygroundHome(
        dark: _dark,
        onThemeChanged: (value) => setState(() => _dark = value),
      ),
    );
  }
}

class PlaygroundHome extends StatefulWidget {
  const PlaygroundHome({
    super.key,
    required this.dark,
    required this.onThemeChanged,
  });

  final bool dark;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<PlaygroundHome> createState() => _PlaygroundHomeState();
}

class _PlaygroundHomeState extends State<PlaygroundHome> {
  int _tab = 0;
  bool _switchValue = true;
  bool _secondSwitch = false;
  int _pressCount = 0;

  static const _titles = ['Controls', 'Glass', 'System UI', 'Symbols'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _controlsPage(),
      _glassPage(),
      _systemPage(),
      _symbolsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Toggle appearance',
            onPressed: () => widget.onThemeChanged(!widget.dark),
            icon: Icon(widget.dark ? Icons.light_mode : Icons.dark_mode),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: NativeUi.bottomNavigationBar(
        items: const [
          IOSNavItem(icon: 'slider.horizontal.3', title: 'Controls'),
          IOSNavItem(icon: 'drop.halffull', title: 'Glass'),
          IOSNavItem(icon: 'rectangle.3.group', title: 'System'),
          IOSNavItem(icon: 'star', title: 'Symbols'),
        ],
        selectedIndex: _tab,
        onChanged: (index) => setState(() => _tab = index),
      ),
    );
  }

  Widget _section(String title, String subtitle, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _controlsPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        _intro('Native controls', 'UIKit controls embedded in a Flutter screen.'),
        _section(
          'Native buttons',
          'UIButton rendered by iOS. Tap to interact.',
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              NativeUi.button(
                title: 'Default',
                onPressed: () => setState(() => _pressCount++),
              ),
              NativeUi.button(
                title: 'Glass button',
                onPressed: () => setState(() => _pressCount++),
                options: const IosButtonOptions(cornerRadius: 18),
              ),
              NativeUi.button(
                title: 'Disabled',
                onPressed: null,
              ),
            ],
          ),
        ),
        _section(
          'Native switches',
          'UISwitch with live Dart state.',
          NativeUi.glassContainer(
            cornerRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Notifications')),
                    NativeUi.switchWidget(
                      value: _switchValue,
                      onChanged: (v) => setState(() => _switchValue = v),
                    ),
                  ],
                ),
                const Divider(height: 22),
                Row(
                  children: [
                    const Expanded(child: Text('Background refresh')),
                    NativeUi.switchWidget(
                      value: _secondSwitch,
                      onChanged: (v) => setState(() => _secondSwitch = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _section(
          'Interaction state',
          'The native button above has been pressed:',
          Text(
            '$_pressCount times',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ],
    );
  }

  Widget _glassPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        _intro('Glass materials', 'Native glass / blur containers where supported.'),
        _section(
          'Glass container',
          'A native platform container with rounded corners.',
          NativeUi.glassContainer(
            cornerRadius: 28,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NativeUi.sfSymbol(SfSymbols.starSquareFill, size: 34),
                const SizedBox(height: 14),
                Text('A native glass surface',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                const Text(
                  'On supported iOS versions, the package uses the system glass material. '
                  'The exact appearance depends on the simulator OS version.',
                ),
                const SizedBox(height: 18),
                NativeUi.button(
                  title: 'Try glass action',
                  onPressed: () => _showInfo('Glass action', 'Native button tapped.'),
                  options: const IosButtonOptions(cornerRadius: 16),
                ),
              ],
            ),
          ),
        ),
        _section(
          'Layered surface',
          'A second glass surface with a different radius.',
          NativeUi.glassContainer(
            cornerRadius: 18,
            padding: const EdgeInsets.all(18),
            child: const Row(
              children: [
                Icon(Icons.blur_on, size: 28),
                SizedBox(width: 12),
                Expanded(child: Text('Glass container preview')),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        _note('For the real Liquid Glass appearance, use an iOS 26+ simulator.'),
      ],
    );
  }

  Widget _systemPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        _intro('System UI', 'Native modal interfaces presented by iOS.'),
        _section(
          'UIAlertController',
          'Open a native iOS alert with cancel and destructive actions.',
          NativeUi.button(
            title: 'Show native alert',
            onPressed: () async {
              await showIosAlert(
                context: context,
                title: 'Delete item?',
                message: 'This is a native iOS alert presented by the package.',
                primaryButton: IosAlertButton(
                  text: 'Delete',
                  style: IosAlertButtonStyle.destructive,
                  onTap: () => _showInfo('Deleted', 'The demo action was selected.'),
                ),
                cancelButton: const IosAlertButton(
                  text: 'Cancel',
                  style: IosAlertButtonStyle.cancel,
                ),
              );
            },
          ),
        ),
        _section(
          'UIMenu popover',
          'Open a native popover menu anchored to this button.',
          NativeUi.button(
            title: 'Show popover menu',
            onPressed: () async {
              await showIosPopover(
                context: context,
                actions: const [
                  IosPopoverAction(title: 'Copy', systemImage: 'doc.on.doc'),
                  IosPopoverAction(title: 'Share', systemImage: 'square.and.arrow.up'),
                  IosPopoverAction(
                    title: 'Delete',
                    systemImage: 'trash',
                    isDestructive: true,
                  ),
                ],
                onSelect: (index) {
                  const names = ['Copy', 'Share', 'Delete'];
                  _showInfo('Selected', names[index]);
                },
              );
            },
          ),
        ),
        _note('Alerts and popovers are native iOS UI. They may use fallback behavior on other platforms.'),
      ],
    );
  }

  Widget _symbolsPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        _intro('SF Symbols', 'Symbols are rendered by the native iOS system.'),
        _section(
          'Typed symbol',
          'The package exposes a typed SfSymbols API.',
          NativeUi.glassContainer(
            cornerRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                NativeUi.sfSymbol(SfSymbols.starSquareFill, size: 42),
                const SizedBox(width: 18),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('star.square.fill'),
                      Text('Native SF Symbol'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _note('This starter playground includes a verified symbol from the package documentation. More enum values can be added from the package API.'),
      ],
    );
  }

  Widget _intro(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _note(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
