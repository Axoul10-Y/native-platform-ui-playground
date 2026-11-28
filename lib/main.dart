import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme, ThemeData;
import 'package:flutter/services.dart';
import 'package:native_platform_ui/native_platform_ui.dart';
import 'package:sf_symbols/sf_symbols.dart';

void main() => runApp(const PlaygroundApp());

class PlaygroundApp extends StatelessWidget {
  const PlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) => CupertinoApp(
    debugShowCheckedModeBanner: false,
    title: 'Playground',
    home: Builder(
      builder: (context) {
        final dark =
            MediaQuery.platformBrightnessOf(context) == Brightness.dark;
        return Theme(
          data: dark ? ThemeData.dark() : ThemeData.light(),
          child: const ControlsPage(),
        );
      },
    ),
  );
}

class ControlsPage extends StatefulWidget {
  const ControlsPage({super.key});
  @override
  State<ControlsPage> createState() => _ControlsPageState();
}

class _ControlsPageState extends State<ControlsPage> {
  static const channel = MethodChannel('dev.componentstudio/playground');
  static const effects = <SfSymbolEffect, (String, String)>{
    SfSymbolEffect.bounce: ('Bounce', 'bell.fill'),
    SfSymbolEffect.pulse: ('Pulse', 'heart.fill'),
    SfSymbolEffect.variableColor: ('Variable color', 'wifi'),
    SfSymbolEffect.scale: ('Scale', 'star.fill'),
    SfSymbolEffect.wiggle: ('Wiggle', 'bell.fill'),
    SfSymbolEffect.rotate: ('Rotate', 'gearshape.fill'),
    SfSymbolEffect.breathe: ('Breathe', 'flower.fill'),
  };

  bool grouped = true;
  bool vertical = false;
  int previewTab = 0;
  int value = 0;
  int replay = 0;
  SfSymbolEffect effect = SfSymbolEffect.bounce;
  bool playing = false;

  void reset() => setState(() {
    value = 0;
    effect = SfSymbolEffect.bounce;
    playing = false;
    vertical = false;
  });

  Future<void> confirmReset() => showIosAlert(
    context: context,
    title: 'Reset preview?',
    message: 'Restore the counter, button layout and symbol effect.',
    barrierDismissible: false,
    cancelButton: const IosAlertButton(
      text: 'Cancel',
      style: IosAlertButtonStyle.cancel,
    ),
    primaryButton: IosAlertButton(
      text: 'Reset',
      style: IosAlertButtonStyle.destructive,
      onTap: reset,
    ),
  );

  Widget section(BuildContext context, String title, List<Widget> rows) =>
      CupertinoListSection.insetGrouped(
        header: Text(title),
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
          context,
        ),
        children: rows,
      );

  Widget toggle({required bool value, required ValueChanged<bool> onChanged}) =>
      isNativeUiSupported
      ? NativeUi.switchWidget(value: value, onChanged: onChanged)
      : CupertinoSwitch(value: value, onChanged: onChanged);

  Widget nativeButton(
    String title,
    VoidCallback action, {
    double width = 108,
  }) => NativeUi.button(
    title: title,
    onPressed: action,
    options: IosButtonOptions(width: width, height: 44),
  );

  @override
  Widget build(BuildContext context) {
    final blue = CupertinoColors.activeBlue.resolveFrom(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final descriptor = effects[effect]!;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 4, bottom: 24),
          children: [
            section(context, 'Linked buttons', [
              CupertinoListTile(
                title: const Text('Counter'),
                additionalInfo: Text('$value', semanticsLabel: 'Count $value'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: NativeUi.button(
                    linkedButtonsAxis: vertical
                        ? IosLinkedButtonsAxis.column
                        : IosLinkedButtonsAxis.row,
                    linkedButtons: [
                      IosLinkedButtonItem(
                        title: '−',
                        enabled: value > 0,
                        onPressed: () => setState(() => value--),
                      ),
                      IosLinkedButtonItem(
                        title: '+',
                        onPressed: () => setState(() => value++),
                      ),
                    ],
                    options: IosButtonOptions(
                      width: vertical ? 52 : 124,
                      height: vertical ? 98 : 46,
                    ),
                  ),
                ),
              ),
              CupertinoListTile(
                title: const Text('Vertical layout'),
                trailing: toggle(
                  value: vertical,
                  onChanged: (v) => setState(() => vertical = v),
                ),
              ),
              CupertinoListTile(
                title: const Text('Group toolbar actions'),
                trailing: toggle(
                  value: grouped,
                  onChanged: (v) async {
                    await channel.invokeMethod<void>('groupToolbar', v);
                    if (mounted) setState(() => grouped = v);
                  },
                ),
              ),
            ]),
            section(context, 'SF Symbols', [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    NativeUi.glassContainer(
                      isCircle: true,
                      width: 82,
                      height: 82,
                      child: Center(
                        child: SfSymbol(
                          key: ValueKey((effect, replay)),
                          name: descriptor.$2,
                          size: 36,
                          color: blue,
                          effect: playing && !reduced ? effect : null,
                          semanticLabel: descriptor.$1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        NativeUi.button(
                          title: descriptor.$1,
                          options: const IosButtonOptions(
                            width: 133,
                            height: 44,
                          ),
                          actions: [
                            for (final entry in effects.values)
                              IosPopoverAction(
                                title: entry.$1,
                                systemImage: entry.$2,
                              ),
                          ],
                          onPopoverSelected: (i) => setState(() {
                            effect = effects.keys.elementAt(i);
                            replay++;
                          }),
                        ),
                        nativeButton(
                          playing ? 'Stop' : 'Play',
                          () => setState(() {
                            playing = !playing;
                            replay++;
                          }),
                          width: 76,
                        ),
                      ],
                    ),
                    if (reduced)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text('Reduce Motion is on.'),
                      ),
                  ],
                ),
              ),
            ]),
            section(context, 'Tab bar preview', [
              CupertinoListTile(
                title: const Text('Selected tab'),
                additionalInfo: Text(['Map', 'Saved', 'Recent'][previewTab]),
              ),
              NativeUi.bottomNavigationBar(
                items: const [
                  IOSNavItem(icon: 'map', title: 'Map'),
                  IOSNavItem(icon: 'bookmark', title: 'Saved'),
                  IOSNavItem(icon: 'clock', title: 'Recent'),
                ],
                selectedIndex: previewTab,
                onChanged: (index) => setState(() => previewTab = index),
              ),
            ]),
            section(context, 'More controls', [
              CupertinoListTile(
                leading: NativeUi.sfSymbol(SfSymbols.pencil, color: blue),
                title: const Text('Text & Values'),
                trailing: const CupertinoListTileChevron(),
                onTap: () => channel.invokeMethod<void>('openInputs'),
              ),
              CupertinoListTile(
                leading: NativeUi.sfSymbol(
                  SfSymbols.arrowClockwise,
                  color: blue,
                ),
                title: const Text('Reset preview…'),
                onTap: confirmReset,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
