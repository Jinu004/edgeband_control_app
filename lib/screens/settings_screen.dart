// ============= screens/settings_screen.dart =============
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<BleService>(
        builder: (context, bleService, child) {
          final status = bleService.deviceStatus;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSettingCard(
                context,
                title: 'Roller Diameter',
                subtitle: 'Current: ${status?.diameter ?? 0} cm',
                icon: Icons.circle_outlined,
                onTap: () => _showDiameterDialog(context, bleService),
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                context,
                title: 'Motor Speed',
                subtitle: 'Current: ${status?.motorSpeed ?? 0}',
                icon: Icons.speed,
                onTap: () => _showSpeedDialog(context, bleService),
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                context,
                title: 'Offset Length',
                subtitle: 'Current: ${status?.offset ?? 0} cm',
                icon: Icons.straighten,
                onTap: () => _showOffsetDialog(context, bleService),
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                context,
                title: 'Min Start Speed',
                subtitle: 'Current: ${status?.minStartSpeed ?? 0}',
                icon: Icons.play_arrow,
                onTap: () => _showMinStartSpeedDialog(context, bleService),
              ),
              const SizedBox(height: 12),
              _buildSettingCard(
                context,
                title: 'Min Stop Speed',
                subtitle: 'Current: ${status?.minStopSpeed ?? 0}',
                icon: Icons.stop,
                onTap: () => _showMinStopSpeedDialog(context, bleService),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Device Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _infoRow('Firmware', status?.firmwareVersion ?? 'Unknown'),
                      _infoRow('WiFi Status',
                          status?.wifiConnected ?? false ? 'Connected' : 'Disconnected'),
                      _infoRow('Encoder Errors', '${status?.encoderErrors ?? 0}'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.edit),
        onTap: onTap,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showDiameterDialog(BuildContext context, BleService bleService) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Roller Diameter'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Diameter (cm)',
            hintText: 'e.g., 5.7',
            suffixText: 'cm',
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
              if (value != null && value > 0.1 && value <= 50) {
                bleService.setDiameter(value);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Diameter set to ${value}cm'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid diameter (0.1-50cm)'),
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

  void _showSpeedDialog(BuildContext context, BleService bleService) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Motor Speed'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Speed (50-255)',
            hintText: 'e.g., 150',
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
              final value = int.tryParse(controller.text);
              if (value != null && value >= 50 && value <= 255) {
                bleService.setSpeed(value);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Motor speed set to $value'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid speed (50-255)'),
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

  void _showOffsetDialog(BuildContext context, BleService bleService) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Offset Length'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Offset (cm)',
            hintText: 'e.g., 5.0',
            suffixText: 'cm',
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
              if (value != null && value >= 0 && value <= 200) {
                bleService.setOffset(value);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Offset set to ${value}cm'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid offset (0-200cm)'),
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

  void _showMinStartSpeedDialog(BuildContext context, BleService bleService) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Min Start Speed'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Speed (50-255)',
            hintText: 'e.g., 150',
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
              final value = int.tryParse(controller.text);
              if (value != null && value >= 50 && value <= 255) {
                bleService.setMinStartSpeed(value);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Min start speed set to $value'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid speed (50-255)'),
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

  void _showMinStopSpeedDialog(BuildContext context, BleService bleService) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Min Stop Speed'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Speed (20-200)',
            hintText: 'e.g., 30',
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
              final value = int.tryParse(controller.text);
              if (value != null && value >= 20 && value <= 200) {
                bleService.setMinStopSpeed(value);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Min stop speed set to $value'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid speed (20-200)'),
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
}