import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:permission_handler/permission_handler.dart';

class BeaconDetector extends StatefulWidget {
  @override
  _BeaconDetectorState createState() => _BeaconDetectorState();
}

class _BeaconDetectorState extends State<BeaconDetector> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devicesList = [];
  List<bool> isConnecting = [];
  List<bool> isConnected = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (await Permission.location.request().isGranted) {
      if (await Permission.bluetoothScan.request().isGranted &&
          await Permission.bluetoothConnect.request().isGranted) {
        _startScanning();
      } else {
        print("Bluetooth permissions are not granted");
      }
    } else {
      print("Location permission is not granted");
    }
  }

  void _startScanning() {
    flutterBlue.startScan(timeout: Duration(seconds: 10));
    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        print('Device found: ${r.device.name} - ${r.device.id}');
        setState(() {
          if (!devicesList.contains(r.device)) {
            devicesList.add(r.device);
            isConnecting.add(false);
            isConnected.add(false);
          }
        });
      }
    });
  }

  Future<void> _connectToDevice(int index) async {
    try {
      setState(() {
        isConnecting[index] = true;
      });

      await devicesList[index].connect();
      devicesList[index].state.listen((state) {
        if (state == BluetoothDeviceState.connected) {
          setState(() {
            isConnected[index] = true;
            isConnecting[index] = false;
          });
          print('Connected to ${devicesList[index].name}');
        } else if (state == BluetoothDeviceState.disconnected) {
          setState(() {
            isConnected[index] = false;
          });
          print('${devicesList[index].name} is disconnected');
        }
      });

      await devicesList[index].discoverServices();
    } catch (e) {
      setState(() {
        isConnecting[index] = false;
      });
      print('Error connecting to device: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bluetooth Beacon Detector"),
      ),
      body: ListView.builder(
        itemCount: devicesList.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  devicesList[index].name.isNotEmpty
                      ? devicesList[index].name
                      : "Unnamed Device",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  "ID: ${devicesList[index].id}",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.0,
                  ),
                ),
                SizedBox(height: 8.0),
                if (isConnecting[index])
                  Center(child: CircularProgressIndicator())
                else ...[
                  if (isConnected[index])
                    Text(
                      "Connected",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  Center(
                    child: Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!isConnected[index]) {
                            _connectToDevice(index);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(isConnected[index] ? "Connected" : "Connect"),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          width: double.infinity,
          child: FloatingActionButton(
            onPressed: () {
              devicesList.clear();
              isConnecting.clear();
              isConnected.clear();
              _startScanning();
            },
            backgroundColor: Colors.yellow,
            child: Icon(Icons.wifi_find),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
