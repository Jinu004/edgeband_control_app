// ============= screens/cutting_screen.dart =============
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';

class CuttingScreen extends StatefulWidget {
  const CuttingScreen({super.key});

  @override
  State<CuttingScreen> createState() => _CuttingScreenState();
}

class _CuttingScreenState extends State<CuttingScreen> {
  Timer? _statusTimer;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    // Poll for status updates every 500ms during cutting
    _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        context.read<BleService>().sendCommand('get_status');
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cutting Operation'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<BleService>(
        builder: (context, bleService, child) {
          final status = bleService.deviceStatus;

          if (status == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Auto-navigate back on completion
          if (status.state == 'CUTTING_COMPLETE' && _hasStarted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showCompletionDialog(context, status);
              }
            });
          }

          final isCutting = status.state == 'CUTTING_PROGRESS' && status.motorRunning;
          final isComplete = status.state == 'CUTTING_COMPLETE';
          final isStopped = status.state == 'EMERGENCY_STOPPED';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          isCutting
                              ? 'Cutting in Progress'
                              : isComplete
                              ? 'Cutting Complete'
                              : isStopped
                              ? 'Emergency Stopped'
                              : 'Ready to Start',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isCutting
                                ? Colors.blue
                                : isComplete
                                ? Colors.green
                                : isStopped
                                ? Colors.red
                                : Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Progress Circle
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  value: status.progress / 100,
                                  strokeWidth: 12,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isCutting
                                        ? Colors.blue
                                        : isComplete
                                        ? Colors.green
                                        : isStopped
                                        ? Colors.red
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${status.progress.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${status.currentLength.toStringAsFixed(2)}m / ${status.targetLength.toStringAsFixed(2)}m',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Info Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Current Speed',
                        '${status.currentMotorSpeed}',
                        Icons.speed,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        'Remaining',
                        status.remainingCm != null
                            ? '${status.remainingCm!.toStringAsFixed(1)}cm'
                            : 'N/A',
                        Icons.straighten,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (status.estimatedSecondsRemaining != null && isCutting)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Est. Time: ${_formatTime(status.estimatedSecondsRemaining!)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),

                // Control Buttons
                if (!isCutting && !isComplete && !isStopped) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      bleService.startCutting();
                      setState(() => _hasStarted = true);
                    },
                    icon: const Icon(Icons.play_arrow, size: 28),
                    label: const Text(
                      'START CUTTING',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],

                if (isCutting) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => bleService.speedIncrease(),
                          icon: const Icon(Icons.arrow_upward),
                          label: const Text('Speed +'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => bleService.speedDecrease(),
                          icon: const Icon(Icons.arrow_downward),
                          label: const Text('Speed -'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showStopConfirmation(context, bleService),
                    icon: const Icon(Icons.stop, size: 28),
                    label: const Text(
                      'EMERGENCY STOP',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],

                if (isStopped) ...[
                  ElevatedButton.icon(
                    onPressed: () => bleService.resumeCutting(),
                    icon: const Icon(Icons.play_arrow, size: 28),
                    label: const Text(
                      'RESUME CUTTING',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Menu'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }

  void _showStopConfirmation(BuildContext context, BleService bleService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Stop'),
        content: const Text(
          'Are you sure you want to stop the cutting operation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              bleService.stopCutting();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('STOP'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 32),
            const SizedBox(width: 12),
            const Text('Cutting Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target: ${status.targetLength.toStringAsFixed(3)}m'),
            Text('Actual: ${status.currentLength.toStringAsFixed(3)}m'),
            const SizedBox(height: 8),
            Text(
              'Accuracy: ${status.progress.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to control screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}