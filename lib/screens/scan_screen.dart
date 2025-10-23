// ============= screens/scan_screen.dart =============
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BleService>().startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan for Devices'),
        elevation: 0,
      ),
      body: Consumer<BleService>(
        builder: (context, bleService, child) {
          if (bleService.isScanning) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Scanning for EdgeBandCutter...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (bleService.discoveredDevices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bluetooth_disabled,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No devices found',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => bleService.startScan(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Scan Again'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bleService.discoveredDevices.length,
            itemBuilder: (context, index) {
              final device = bleService.discoveredDevices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.settings_input_antenna, size: 40),
                  title: Text(
                    device.platformName.isNotEmpty
                        ? device.platformName
                        : 'Unknown Device',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(device.remoteId.toString()),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Connecting...'),
                            ],
                          ),
                        ),
                      );

                      final success = await bleService.connectToDevice(device);

                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        if (success) {
                          Navigator.pop(context); // Go back to home
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                bleService.lastError ?? 'Connection failed',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Connect'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}