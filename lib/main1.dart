import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Golf Launch Monitor',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Golf Launch Monitor'),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _services = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  BluetoothDevice? _connectingDevice;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  BluetoothCharacteristic? swingSpeedCharacteristic;
  BluetoothCharacteristic? ballSpeedCharacteristic;
  BluetoothCharacteristic? strokeCountCharacteristic;

  String swingSpeed = "0 mph";
  String ballSpeed = "0 mph";
  String strokeCount = "0";

  final BluetoothController _bluetoothController = BluetoothController();

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _bluetoothController.deviceStream.listen((devices) {
      setState(() {
        widget.devicesList.clear();
        widget.devicesList.addAll(devices);
      });
    });
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
      // Optional: If your app requires background location
      Permission.locationAlways,
    ].request();

    if (statuses.values.every((status) => status.isGranted)) {
      print("All permissions granted");
    } else {
      print("Permissions not granted");
    }
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
    });
    await _bluetoothController.startScan();
    setState(() {
      _isScanning = false;
    });
  }

  ListView _buildListViewOfDevices() {
    List<Widget> containers = <Widget>[];
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              title: Text(
                device.platformName == ''
                    ? '(unknown device)'
                    : device.platformName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              subtitle: Text(device.remoteId.toString()),
              trailing: _isConnecting && _connectingDevice == device
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            Colors.blueAccent, // foreground (text) color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Connect'),
                      onPressed: () async {
                        setState(() {
                          _isConnecting = true;
                          _connectingDevice = device;
                        });
                        await _connectToDevice(device);
                        setState(() {
                          _isConnecting = false;
                          _connectingDevice = null;
                        });
                      },
                    ),
            ),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await _bluetoothController.connectToDevice(device);
      setState(() {
        _connectedDevice = device;
        _services = _bluetoothController.services;
      });
      print("Connected to device: ${device.name}");
      await _setupNotifications();
    } catch (e) {
      print("Error connecting to device: $e");
      // Proceed with service discovery and notifications setup even if MTU request fails
      setState(() {
        _connectedDevice = device;
        _services = _bluetoothController.services;
      });
      await _setupNotifications();
    }
  }

  Future<void> _setupNotifications() async {
    for (var service in _services) {
      if (service.uuid.toString() == '181A') {
        print('Found 181A service');
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == '2A6E') {
            swingSpeedCharacteristic = characteristic;
            await _subscribeToCharacteristic(swingSpeedCharacteristic!);
          }
          if (characteristic.uuid.toString() == '2A6F') {
            ballSpeedCharacteristic = characteristic;
            await _subscribeToCharacteristic(ballSpeedCharacteristic!);
          }
          if (characteristic.uuid.toString() == '2A6D') {
            strokeCountCharacteristic = characteristic;
            await _subscribeToCharacteristic(strokeCountCharacteristic!);
          }
        }
      }
    }
  }

  Future<void> _subscribeToCharacteristic(
      BluetoothCharacteristic characteristic) async {
    try {
      print("Attempting to subscribe to ${characteristic.uuid}");
      await characteristic.setNotifyValue(true);
      print("Subscribed to ${characteristic.uuid}");
      characteristic.value.listen((value) {
        print("Received data from ${characteristic.uuid}: $value");
        final parsedValue = _parseCharacteristicValue(value);
        setState(() {
          if (characteristic == swingSpeedCharacteristic) {
            swingSpeed = parsedValue;
            print("Swing Speed: $parsedValue");
          } else if (characteristic == ballSpeedCharacteristic) {
            ballSpeed = parsedValue;
            print("Ball Speed: $parsedValue");
          } else if (characteristic == strokeCountCharacteristic) {
            strokeCount = value[0].toString();
            print("Stroke Count: $strokeCount");
          }
        });
      });
    } catch (e) {
      print("Error subscribing to characteristic: $e");
    }
  }

  String _parseCharacteristicValue(List<int> value) {
    if (value.length >= 4) {
      final byteData = Uint8List.fromList(value).buffer.asByteData();
      final floatValue = byteData.getFloat32(0, Endian.little);
      return "${floatValue.toStringAsFixed(1)} mph";
    }
    return "0 mph";
  }

  Widget _buildConnectDeviceView() {
    return getView();
  }

  Widget _buildView() {
    if (_connectedDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();
  }

  Widget getView() {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F4F8),
        automaticallyImplyLeading: false,
        title: Text("Golf Launch Monitor",
            style: GoogleFonts.getFont(
              'Lexend',
              color: const Color(0xFF111417), // primary text color
              fontWeight: FontWeight.w300,
              fontSize: 32.0,
            )),
        actions: [],
        centerTitle: false,
        elevation: 0.0,
      ),
      body: SafeArea(
          top: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _isScanning ? null : _startScan,
                  child: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: MediaQuery.sizeOf(context).width * 0.92,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 6.0,
                                    color: Color(0x4B1A1F24),
                                    offset: Offset(
                                      0.0,
                                      2.0,
                                    ),
                                  )
                                ],
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF00968A),
                                    Color(0xFFF2A384)
                                  ],
                                  stops: [0.0, 1.0],
                                  begin: AlignmentDirectional(0.94, -1.0),
                                  end: AlignmentDirectional(-0.94, 1.0),
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 10.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          20.0, 20.0, 20.0, 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Image.asset(
                                            'assets/images/icons8-golfer-50.png',
                                            width: 47.0,
                                            height: 49.0,
                                            fit: BoxFit.cover,
                                          ),
                                          Image.asset(
                                            'assets/images/icons8-golf-ball-50.png',
                                            width: 47.0,
                                            height: 49.0,
                                            fit: BoxFit.cover,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          20.0, 10.0, 20.0, 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("Swing Speed",
                                              style: GoogleFonts.getFont(
                                                'Lexend',
                                                color: const Color(0xFF111417),
                                                fontWeight: FontWeight.normal,
                                                fontSize: 14.0,
                                              )),
                                          Text("Ball Speed",
                                              textAlign: TextAlign.end,
                                              style: GoogleFonts.getFont(
                                                'Lexend',
                                                color: const Color(0xFF111417),
                                                fontWeight: FontWeight.normal,
                                                fontSize: 14.0,
                                              )),
                                          Text("Stroke",
                                              textAlign: TextAlign.end,
                                              style: GoogleFonts.getFont(
                                                'Lexend',
                                                color: const Color(0xFF111417),
                                                fontWeight: FontWeight.normal,
                                                fontSize: 14.0,
                                              )),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          20.0, 8.0, 20.0, 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(swingSpeed,
                                              textAlign: TextAlign.start,
                                              style: GoogleFonts.getFont(
                                                'Lexend',
                                                color: const Color(0xFF111417),
                                                fontWeight: FontWeight.w300,
                                                fontSize: 32.0,
                                              )),
                                          Text(ballSpeed,
                                              textAlign: TextAlign.end,
                                              style: GoogleFonts.getFont(
                                                'Lexend',
                                                color: const Color(0xFF111417),
                                                fontWeight: FontWeight.w300,
                                                fontSize: 32.0,
                                              )),
                                          Text(strokeCount,
                                              textAlign: TextAlign.end,
                                              style: GoogleFonts.getFont(
                                                'Lexend',
                                                color: const Color(0xFF111417),
                                                fontWeight: FontWeight.w300,
                                                fontSize: 32.0,
                                              )),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await _bluetoothController
                                              .disconnectFromDevice();
                                          setState(() {
                                            _connectedDevice = null;
                                            _services = [];
                                          });
                                        },
                                        child: const Text(
                                            'Disconnect and Go Back'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _buildView(),
      );
}

class BluetoothController {
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};
  BluetoothDevice? connectedDevice;
  List<BluetoothService> services = [];
  final StreamController<List<BluetoothDevice>> _deviceStreamController =
      StreamController<List<BluetoothDevice>>.broadcast();
  Stream<List<BluetoothDevice>> get deviceStream =>
      _deviceStreamController.stream;

  void dispose() {
    _deviceStreamController.close();
  }

  Future<void> initBluetooth() async {
    await requestPermissions();
  }

  Future<void> startScan() async {
    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        print("Scan results received: ${results.length} devices found.");
        if (results.isNotEmpty) {
          for (ScanResult result in results) {
            print(
                "Device found: ${result.device.advName} - ${result.device.mtu}");
            _addDeviceTolist(result.device);
          }
        }
      },
      onError: (e) {
        print("Error while scanning: $e");
      },
    );

    FlutterBluePlus.cancelWhenScanComplete(subscription);
    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;
    await FlutterBluePlus.startScan();
    await FlutterBluePlus.isScanning.where((val) => val == false).first;

    for (BluetoothDevice device in await FlutterBluePlus.connectedDevices) {
      _addDeviceTolist(device);
    }
  }

  Future<void> requestPermissions() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      await Permission.location.request();
    }
    if (await Permission.location.status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _addDeviceTolist(final BluetoothDevice device) {
    if (!devicesList.contains(device)) {
      devicesList.add(device);
      _deviceStreamController.add(devicesList);
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await FlutterBluePlus.stopScan();
      await device.connect();
      services = await device.discoverServices();
      connectedDevice = device;
      // Request MTU size but don't let it block the connection
      await _requestMtuWithRetry(device, 512, 3);
    } catch (e) {
      if (e.toString() != 'already_connected') {
        rethrow;
      }
    }
  }

  Future<void> _requestMtuWithRetry(
      BluetoothDevice device, int mtu, int retries) async {
    for (int i = 0; i < retries; i++) {
      try {
        await device.requestMtu(mtu);
        break;
      } catch (e) {
        if (i == retries - 1) {
          print("Failed to request MTU after $retries retries: $e");
        } else {
          await Future.delayed(Duration(seconds: 5));
        }
      }
    }
  }

  Future<void> disconnectFromDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
    }
  }
}
