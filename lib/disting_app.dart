import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/synchronized_screen.dart';

class DistingApp extends StatelessWidget {
  DistingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) {
          final cubit = DistingCubit();
          cubit.initialize(); // Load settings and auto-connect if possible
          return cubit;
        },
        child: DistingPage(),
      ),
    );
  }
}

class DistingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DistingCubit, DistingState>(
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
              devices: state.devices,
              onDeviceSelected: (device, sysExId) {
                context.read<DistingCubit>().connectToDevice(device, sysExId);
              },
            );
          } else if (state is DistingStateConnected) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Connected to: ${state.device.name}"),
                  ElevatedButton(
                    onPressed: () {
                      context.read<DistingCubit>().synchronizeDevice();
                    },
                    child: Text("Synchronize Device"),
                  ),
                ],
              ),
            );
          } else if (state is DistingStateSynchronized && state.complete == true) {
            return SynchronizedScreen(
              slots: state.slots,
              algorithms: state.algorithms,
            );
          } else if (state is DistingStateSynchronized) {
            return Center(child: CircularProgressIndicator());
          } else {
            return Center(child: Text("Unknown State"));
          }
        },
      ),
    );
  }
}

class _DeviceSelectionView extends StatefulWidget {
  final List<MidiDevice> devices;
  final Function(MidiDevice, int) onDeviceSelected;

  const _DeviceSelectionView({
    Key? key,
    required this.devices,
    required this.onDeviceSelected,
  }) : super(key: key);

  @override
  State<_DeviceSelectionView> createState() => _DeviceSelectionViewState();
}

class _DeviceSelectionViewState extends State<_DeviceSelectionView> {
  MidiDevice? selectedDevice;
  int? selectedSysExId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Dropdown for selecting the MIDI device
          DropdownButton<MidiDevice>(
            value: selectedDevice,
            hint: Text("Select MIDI Device"),
            items: widget.devices.map((device) {
              return DropdownMenuItem(
                value: device,
                child: Text(device.name),
              );
            }).toList(),
            onChanged: (device) {
              setState(() {
                selectedDevice = device;
              });
            },
          ),
          const SizedBox(height: 16),
          // Dropdown for selecting the SysEx ID
          DropdownButton<int>(
            value: selectedSysExId,
            hint: Text("Select SysEx ID"),
            items: List.generate(128, (index) => index).map((id) {
              return DropdownMenuItem(
                value: id,
                child: Text(id.toString()),
              );
            }).toList(),
            onChanged: (id) {
              setState(() {
                selectedSysExId = id;
              });
            },
          ),
          const SizedBox(height: 32),
          // Button to confirm selection
          ElevatedButton(
            onPressed: (selectedDevice != null && selectedSysExId != null)
                ? () {
                    widget.onDeviceSelected(selectedDevice!, selectedSysExId!);
                  }
                : null,
            child: Text("Connect to Device"),
          ),
        ],
      ),
    );
  }
}
