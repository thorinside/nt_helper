import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nt_helper/services/mcp_server_service.dart';
import 'package:nt_helper/services/settings_service.dart';

/// Small round LED indicator for MCP server status with tooltip
class McpStatusIndicator extends StatelessWidget {
  static const int mcpPort = 3847;

  const McpStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService(); // Get SettingsService instance
    final mcpInstance =
        McpServerService.instance; // Get McpServerService instance
    final mcpService = context.watch<McpServerService>();
    final isRunning = mcpService.isRunning;
    final hasError = mcpService.hasError;
    final lastError = mcpService.lastError;

    // Determine color based on state: green=running, red=error, grey=disabled
    final Color baseColor;
    final Color highlightColor;
    final Color shadowColor;

    if (isRunning) {
      baseColor = Colors.green.shade600;
      highlightColor = Colors.green.shade300;
      shadowColor = Colors.green.shade800;
    } else if (hasError) {
      baseColor = Colors.red.shade600;
      highlightColor = Colors.red.shade300;
      shadowColor = Colors.red.shade800;
    } else {
      baseColor = Colors.grey.shade600;
      highlightColor = Colors.grey.shade400;
      shadowColor = Colors.grey.shade800;
    }

    // Build tooltip message based on state
    final String tooltip;
    if (isRunning) {
      tooltip = 'MCP server running at http://localhost:$mcpPort (Tap to disable)';
    } else if (hasError) {
      tooltip = 'MCP server failed: $lastError (Tap to retry)';
    } else {
      tooltip = 'MCP server is disabled (Tap to enable)';
    }

    return GestureDetector(
      onTap: () async {
        // Check if on supported platform first
        if (!(Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "MCP Service can only be toggled on desktop platforms.",
              ),
            ),
          );
          return;
        }

        // If there's an error, tapping retries without toggling the setting
        if (mcpInstance.hasError) {
          await mcpInstance.start();
          return;
        }

        final bool currentMcpSetting = settings.mcpEnabled;
        final newMcpSetting = !currentMcpSetting;
        await settings.setMcpEnabled(newMcpSetting);

        // Now apply the logic to start/stop the server
        final bool isServerCurrentlyRunning = mcpInstance.isRunning;

        if (newMcpSetting) {
          // Try to turn ON
          if (!isServerCurrentlyRunning) {
            await mcpInstance.start();
          }
        } else {
          // Try to turn OFF
          if (isServerCurrentlyRunning) {
            await mcpInstance.stop();
          }
        }
        // McpServerService.notifyListeners() is called by start()/stop(), which Consumer listens to.
      },
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 16, // Slightly larger for better effect
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(
                -0.3,
                -0.4,
              ), // Offset center for top-right light source
              radius: 0.9,
              colors: [highlightColor, baseColor, shadowColor],
              stops: const [0.0, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(77),
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: Center(
            // For specular highlight
            child: Container(
              width: 5, // Size of specular highlight
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(179),
              ),
              margin: const EdgeInsets.only(
                right: 3,
                bottom: 3,
              ), // Position highlight
            ),
          ),
        ),
      ),
    );
  }
}
