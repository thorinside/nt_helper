This is the nt_helper project. It is a flutter app that supports Linux, MacOS, iOS, Android and Windows.
Desktop versions of the app have some features that iOS and Android don't, like backup and drag and drop install.
There is a MIDI SysEX implementation in lib/domain/ as well as a main driver cubit lib/disting_cubit.dart.
Most of the UI is rendered in lib/synchronized_screen.dart
There are three modes of running the app, Demo mode, Offline mode, and connected mode (the default). 
lib/domain/i_disting_midi_manager.dart is the main interface for all of the implementations. Some implementations 
have empty implementations for some commands, because they aren't needed in that mode.
An mcp service exists in the app.
A Drift database is in the app, to keep track of offline algorithm information.

## MCP Service
- The MCP service handles communication and synchronization between different parts of the application
- It likely manages the state and interactions for the MIDI device connections and data transfer
- The MCP service uses a controller to abstract and hide the implementation details of how the Disting cubit works, providing a clean separation of concerns and encapsulation of the underlying device interaction logic

## Synchronization
- New location of synchronized_screen.dart is lib/synchronized_screen.dart

## Preset Export
- The preset export feature allows users to save and transfer the configuration and settings of a device
- Implementation involves serializing the current device state and parameters into a portable format
- Supports exporting presets to a file that can be imported later or shared between devices
- Likely uses the Drift database to manage and store preset information
- The export process is abstracted through the MIDI manager interface to support different modes of operation (demo, offline, connected)