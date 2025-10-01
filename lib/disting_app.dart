import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/services/mcp_server_service.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:nt_helper/ui/synchronized_screen.dart';
import 'package:nt_helper/ui/midi_listener/midi_listener_cubit.dart';

class DistingApp extends StatefulWidget {
  const DistingApp({super.key});

  @override
  State<DistingApp> createState() => _DistingAppState();
}

class _DistingAppState extends State<DistingApp> {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Delay slightly to ensure the window is shown and initial rendering attempted
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {}); // Trigger a rebuild to force repaint
          }
        });
      });
    }
  }

  ThemeData buildThemeData(ColorScheme baseColorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme,
      appBarTheme: AppBarTheme(
        elevation: 4.0,
        shadowColor: baseColorScheme.shadow,
        backgroundColor: baseColorScheme.surface,
        foregroundColor: baseColorScheme.onSurface,
      ),
      tabBarTheme: TabBarThemeData(
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: baseColorScheme.secondary, width: 2.0),
        ),
        labelColor: baseColorScheme.secondary,
        unselectedLabelColor: baseColorScheme.secondary.withAlpha(170),
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: baseColorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: baseColorScheme.onInverseSurface),
        actionTextColor: baseColorScheme.inversePrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = buildThemeData(
      ColorScheme.fromSeed(
        seedColor: Colors.tealAccent.shade700,
        dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
        brightness: Brightness.light,
      ).copyWith(surfaceTint: Colors.transparent),
    );

    final darkTheme = buildThemeData(
      ColorScheme.fromSeed(
        seedColor: Colors.tealAccent.shade100,
        dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
        brightness: Brightness.dark,
      ).copyWith(surfaceTint: Colors.transparent),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      // Light theme
      darkTheme: darkTheme,
      // Dark theme using copyWith
      themeMode: ThemeMode.system,
      // Follow system settings
      initialRoute: '/',
      routes: {
        '/': (context) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) {
                // Get the AppDatabase instance from the context
                final database = context.read<AppDatabase>();

                // Create DistingCubit and pass the database instance
                final cubit = DistingCubit(database); // Pass database here
                cubit
                    .initialize(); // Load settings and auto-connect if possible
                return cubit;
              },
            ),
          ],
          child: Material(child: DistingPage()),
        ),
      },
    );
  }
}

class DistingPage extends StatefulWidget {
  const DistingPage({super.key});

  @override
  State<DistingPage> createState() => _DistingPageState();
}

class _DistingPageState extends State<DistingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          final distingCubit = context.read<DistingCubit>();
          McpServerService.initialize(distingCubit: distingCubit);
          final settings = SettingsService();
          debugPrint(
            "[InitState] Initializing MCP Server. MCP Enabled Setting: ${settings.mcpEnabled}, IsMacOS: ${Platform.isMacOS}, IsWindows: ${Platform.isWindows}",
          );
          if ((Platform.isMacOS || Platform.isWindows) && settings.mcpEnabled) {
            if (!McpServerService.instance.isRunning) {
              await McpServerService.instance.start().catchError((e) {
                debugPrint('[InitState] Error starting MCP Server: $e');
              });
              debugPrint(
                "[InitState] MCP Server Initialized and Started. Now Running: ${McpServerService.instance.isRunning}",
              );
            } else {
              debugPrint(
                "[InitState] MCP Server was already running (unexpected). Running: ${McpServerService.instance.isRunning}",
              );
            }
          } else {
            debugPrint(
              "[InitState] MCP Server not started (setting disabled or wrong platform).",
            );
          }
        } catch (e) {
          debugPrint('[InitState] Error in MCP Server setup: $e');
        }
      }
    });
  }

  Future<void> _handleSettingsDialog(BuildContext context) async {
    final settings = SettingsService();
    final mcpInstance = McpServerService.instance;

    final bool wasMcpEnabledBeforeDialog = settings.mcpEnabled;
    final bool wasServerRunningBeforeDialog = mcpInstance.isRunning;
    debugPrint(
      "[HandleSettings] Before dialog: MCP Setting: $wasMcpEnabledBeforeDialog, Server Running: $wasServerRunningBeforeDialog",
    );

    final result = await context.showSettingsDialog();

    if (result == true) {
      // Settings were saved
      final bool isMcpEnabledAfterDialog = settings.mcpEnabled;
      final bool isServerStillRunningBeforeAction = mcpInstance
          .isRunning; // Check state *before* explicitly starting/stopping

      debugPrint(
        "[HandleSettings] After dialog saved: New MCP Setting: $isMcpEnabledAfterDialog, Server Currently Running (before action): $isServerStillRunningBeforeAction",
      );

      if (Platform.isMacOS || Platform.isWindows) {
        if (isMcpEnabledAfterDialog) {
          if (!isServerStillRunningBeforeAction) {
            debugPrint(
              "[HandleSettings] MCP Setting is ON, Server is OFF. Attempting to START server.",
            );
            await mcpInstance.start().catchError((e) {
              debugPrint('[HandleSettings] Error starting MCP Server: $e');
            });
            debugPrint(
              "[HandleSettings] MCP Server START attempt finished. Now Running: ${mcpInstance.isRunning}",
            );
          } else {
            debugPrint(
              "[HandleSettings] MCP Setting is ON, Server is ALREADY ON. No action taken. Running: ${mcpInstance.isRunning}",
            );
          }
        } else {
          // MCP Setting is OFF
          if (isServerStillRunningBeforeAction) {
            debugPrint(
              "[HandleSettings] MCP Setting is OFF, Server is ON. Attempting to STOP server.",
            );
            await mcpInstance.stop().catchError((e) {
              debugPrint('[HandleSettings] Error stopping MCP Server: $e');
            });
            debugPrint(
              "[HandleSettings] MCP Server STOP attempt finished. Now Running: ${mcpInstance.isRunning}",
            );
          } else {
            debugPrint(
              "[HandleSettings] MCP Setting is OFF, Server is ALREADY OFF. No action taken. Running: ${mcpInstance.isRunning}",
            );
          }
        }
      } else {
        debugPrint(
          "[HandleSettings] Not on MacOS/Windows. No MCP server action taken.",
        );
      }
    } else {
      debugPrint(
        "[HandleSettings] Settings dialog cancelled or no changes saved. No MCP server action taken. MCP Setting: ${settings.mcpEnabled}, Server Running: ${mcpInstance.isRunning}",
      );
    }
  }

  @override
  void dispose() {
    // Stop the MCP server when the widget is disposed
    if ((Platform.isMacOS || Platform.isWindows) &&
        McpServerService.instance.isRunning) {
      McpServerService.instance.stop().catchError((e) {
        debugPrint('Error stopping MCP Server: $e');
      });
      debugPrint("MCP Server Stopped");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => MidiListenerCubit(),
        child: BlocBuilder<DistingCubit, DistingState>(
          builder: (context, state) {
            if (state is DistingStateInitial) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<DistingCubit>().loadDevices();
                  },
                  child: Text("Load Devices"),
                ),
              );
            } else if (state is DistingStateSelectDevice) {
              return _DeviceSelectionView(
                inputDevices: state.inputDevices,
                outputDevices: state.outputDevices,
                onDeviceSelected: (inputDevice, outputDevice, sysExId) {
                  context.read<DistingCubit>().connectToDevices(
                    inputDevice,
                    outputDevice,
                    sysExId,
                  );
                },
                onRefresh: () {
                  context.read<DistingCubit>().loadDevices();
                },
                onSettingsPressed: () async {
                  await _handleSettingsDialog(context);
                },
                onDemoPressed: () async {
                  context.read<DistingCubit>().onDemo();
                },
                onOfflinePressed: () async {
                  context.read<DistingCubit>().goOffline();
                },
                canWorkOffline: state.canWorkOffline,
              );
            } else if (state is DistingStateConnected) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Synchronizing...",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        context.read<DistingCubit>().cancelSync();
                      },
                      child: Text("Cancel"),
                    ),
                  ],
                ),
              );
            } else if (state is DistingStateSynchronized) {
              return SynchronizedScreen(
                slots: state.slots,
                algorithms: state.algorithms,
                units: state.unitStrings,
                distingVersion: state.distingVersion,
                presetName: state.presetName,
                screenshot: state.screenshot,
                loading: state.loading,
                firmwareVersion: state.firmwareVersion,
              );
            } else {
              // Simple fallback - just restart the device selection
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.read<DistingCubit>().loadDevices();
                }
              });
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

class _DeviceSelectionView extends StatefulWidget {
  final List<MidiDevice> inputDevices;
  final List<MidiDevice> outputDevices;
  final Function(MidiDevice, MidiDevice, int) onDeviceSelected;
  final Function() onRefresh;
  final Function() onSettingsPressed;
  final Function() onDemoPressed;
  final Function() onOfflinePressed;
  final bool canWorkOffline;

  const _DeviceSelectionView({
    required this.inputDevices,
    required this.outputDevices,
    required this.onDeviceSelected,
    required this.onRefresh,
    required this.onSettingsPressed,
    required this.onDemoPressed,
    required this.onOfflinePressed,
    required this.canWorkOffline,
  });

  @override
  State<_DeviceSelectionView> createState() => _DeviceSelectionViewState();
}

class _DeviceSelectionViewState extends State<_DeviceSelectionView> {
  MidiDevice? selectedInputDevice;
  MidiDevice? selectedOutputDevice;
  int? selectedSysExId = 0;

  @override
  void initState() {
    selectFirstDisting();
    super.initState();
  }

  void selectFirstDisting() {
    selectedInputDevice = widget.inputDevices
        .where((element) => element.name.toLowerCase().contains('disting'))
        .firstOrNull;
    selectedOutputDevice = widget.outputDevices
        .where((element) => element.name.toLowerCase().contains('disting'))
        .firstOrNull;
  }

  @override
  void didUpdateWidget(covariant _DeviceSelectionView oldWidget) {
    if (oldWidget.inputDevices != widget.inputDevices ||
        oldWidget.outputDevices != widget.outputDevices) {
      selectFirstDisting();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title row with settings button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Select your Disting NT from the midi device list, or hit refresh to look for devices again.",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'Settings',
                    onPressed: widget.onSettingsPressed,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DropdownMenu<MidiDevice>(
                width: 250,
                initialSelection: selectedInputDevice,
                enabled: true,
                requestFocusOnTap: false,
                label: const Text("Input MIDI Device"),
                dropdownMenuEntries: widget.inputDevices.map((device) {
                  return DropdownMenuEntry<MidiDevice>(
                    value: device,
                    label: device.name,
                  );
                }).toList(),
                onSelected: (device) {
                  setState(() {
                    selectedInputDevice = device;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownMenu<MidiDevice>(
                width: 250,
                initialSelection: selectedOutputDevice,
                enabled: true,
                requestFocusOnTap: false,
                label: const Text("Output MIDI Device"),
                dropdownMenuEntries: widget.outputDevices.map((device) {
                  return DropdownMenuEntry<MidiDevice>(
                    value: device,
                    label: device.name,
                  );
                }).toList(),
                onSelected: (device) {
                  setState(() {
                    selectedOutputDevice = device;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Dropdown for selecting the SysEx ID
              DropdownMenu<int>(
                width: 250,
                initialSelection: selectedSysExId,
                requestFocusOnTap: false,
                label: const Text("Device ID"),
                dropdownMenuEntries: List.generate(128, (index) {
                  return DropdownMenuEntry<int>(
                    value: index,
                    label: index.toString(),
                  );
                }),
                onSelected: (id) {
                  setState(() {
                    selectedSysExId = id;
                  });
                },
              ),
              const SizedBox(height: 32),
              // Button row: Refresh, Work Offline, Connect
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Space buttons out
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Refresh"),
                    onPressed: widget.onRefresh,
                  ),
                  if (widget.canWorkOffline)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.cloud_off),
                      label: const Text("Offline"),
                      onPressed: widget.onOfflinePressed,
                    ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text("Connect"),
                    onPressed:
                        (selectedInputDevice != null &&
                            selectedOutputDevice != null &&
                            selectedSysExId != null)
                        ? () {
                            widget.onDeviceSelected(
                              selectedInputDevice!,
                              selectedOutputDevice!,
                              selectedSysExId!,
                            );
                          }
                        : null,
                  ),
                ],
              ),
              // Demo button section (if no device selected)
              if (selectedInputDevice == null ||
                  selectedOutputDevice == null ||
                  selectedSysExId == null)
                Column(
                  children: [
                    const SizedBox(height: 24),
                    const Text("No Disting? Try the demo:"),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: widget.onDemoPressed,
                      child: const Text("Demo"),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
