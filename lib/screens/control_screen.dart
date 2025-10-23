// ============= screens/control_screen.dart =============
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import 'cutting_screen.dart';
import 'settings_screen.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edge Band Cutter'),
        actions: [
          Consumer<BleService>(
            builder: (context, bleService, child) {
              return Row(
                children: [
                  if (bleService.deviceStatus?.wifiConnected ?? false)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.wifi, color: Colors.green),
                    ),
                  IconButton(
                    icon: const Icon(Icons.bluetooth_connected),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Disconnect'),
                          content: const Text(
                            'Are you sure you want to disconnect from the device?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                bleService.disconnect();
                                Navigator.pop(context);
                              },
                              child: const Text('Disconnect'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<BleService>(
        builder: (context, bleService, child) {
          final status = bleService.deviceStatus;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Device Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Connected',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Firmware: ${status?.firmwareVersion ?? 'Unknown'}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        if (status != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'State: ${status.state}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Main Action Buttons
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildActionCard(
                        context,
                        icon: Icons.straighten,
                        title: 'Set Length',
                        subtitle: 'Enter target length',
                        color: Colors.blue,
                        onTap: () => _showSetLengthDialog(context),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.play_arrow,
                        title: 'Start Cutting',
                        subtitle: 'Begin operation',
                        color: Colors.green,
                        onTap: () {
                          if ((status?.targetLength ?? 0) > 0) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CuttingScreen(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please set length first'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.settings,
                        title: 'Settings',
                        subtitle: 'Configure device',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.info,
                        title: 'Device Info',
                        subtitle: 'View details',
                        color: Colors.purple,
                        onTap: () => _showDeviceInfo(context, status),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetLengthDialog(BuildContext context) {
    final controller = TextEditingController();
    final bleService = context.read<BleService>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Target Length'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Length (meters)',
            hintText: 'e.g., 2.5',
            suffixText: 'm',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0 && value <= 100) {
                bleService.setLength(value);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Target length set to ${value}m'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid length (0.1-100m)'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showDeviceInfo(BuildContext context, status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow('Firmware', status?.firmwareVersion ?? 'Unknown'),
              _infoRow('Diameter', '${status?.diameter ?? 0} cm'),
              _infoRow('Motor Speed', '${status?.motorSpeed ?? 0}'),
              _infoRow('Offset', '${status?.offset ?? 0} cm'),
              _infoRow('Min Start Speed', '${status?.minStartSpeed ?? 0}'),
              _infoRow('Min Stop Speed', '${status?.minStopSpeed ?? 0}'),
              _infoRow('WiFi', status?.wifiConnected ?? false ? 'Connected' : 'Disconnected'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}