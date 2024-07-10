// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:permission_handler/permission_handler.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) => MaterialApp(
//         title: 'Golf Launch Monitor',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//         ),
//         home: MyHomePage(title: 'Golf Launch Monitor'),
//       );
// }

// class MyHomePage extends StatefulWidget {
//   MyHomePage({Key? key, required this.title}) : super(key: key);

//   final String title;
//   final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
//   final Map<Guid, List<int>> readValues = <Guid, List<int>>{};

//   @override
//   MyHomePageState createState() => MyHomePageState();
// }

// class MyHomePageState extends State<MyHomePage> {
//   final _writeController = TextEditingController();
//   BluetoothDevice? _connectedDevice;
//   List<BluetoothService> _services = [];

//   final scaffoldKey = GlobalKey<ScaffoldState>();
//   BluetoothCharacteristic? swingSpeedCharacteristic;
//   BluetoothCharacteristic? ballSpeedCharacteristic;

//   String swingSpeed = "78 mph";
//   String ballSpeed = "100 mph";

//   _addDeviceTolist(final BluetoothDevice device) {
//     if (!widget.devicesList.contains(device)) {
//       setState(() {
//         widget.devicesList.add(device);
//       });
//     }
//   }

//   _initBluetooth() async {
//     var subscription = FlutterBluePlus.onScanResults.listen(
//       (results) {
//         if (results.isNotEmpty) {
//           for (ScanResult result in results) {
//             _addDeviceTolist(result.device);
//           }
//         }
//       },
//       onError: (e) => ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(e.toString()),
//         ),
//       ),
//     );

//     FlutterBluePlus.cancelWhenScanComplete(subscription);

//     await FlutterBluePlus.adapterState
//         .where((val) => val == BluetoothAdapterState.on)
//         .first;

//     await FlutterBluePlus.startScan();

//     await FlutterBluePlus.isScanning.where((val) => val == false).first;
//     FlutterBluePlus.connectedDevices.map((device) {
//       _addDeviceTolist(device);
//     });
//   }

//   @override
//   void initState() {
//     () async {
//       print("hello");
//       var status = await Permission.location.status;
//       if (status.isDenied) {
//         final status = await Permission.location.request();
//         if (status.isGranted || status.isLimited) {
//           _initBluetooth();
//         }
//       } else if (status.isGranted || status.isLimited) {
//         _initBluetooth();
//       }

//       if (await Permission.location.status.isPermanentlyDenied) {
//         openAppSettings();
//       }
//     }();
//     super.initState();
//   }

//   ListView _buildListViewOfDevices() {
//     List<Widget> containers = <Widget>[];
//     for (BluetoothDevice device in widget.devicesList) {
//       containers.add(
//         SizedBox(
//           height: 50,
//           child: Row(
//             children: <Widget>[
//               Expanded(
//                 child: Column(
//                   children: <Widget>[
//                     Text(device.platformName == ''
//                         ? '(unknown device)'
//                         : device.advName),
//                     Text(device.remoteId.toString()),
//                   ],
//                 ),
//               ),
//               TextButton(
//                 child: const Text(
//                   'Connect',
//                   style: TextStyle(color: Colors.black),
//                 ),
//                 onPressed: () async {
//                   FlutterBluePlus.stopScan();
//                   try {
//                     await device.connect(mtu: null, autoConnect: true);
//                   } on PlatformException catch (e) {
//                     if (e.code != 'already_connected') {
//                       rethrow;
//                     }
//                   } finally {
//                     _services = await device.discoverServices();
//                   }
//                   setState(() {
//                     _connectedDevice = device;
//                   });
//                 },
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return ListView(
//       padding: const EdgeInsets.all(8),
//       children: <Widget>[
//         ...containers,
//       ],
//     );
//   }

//   List<ButtonTheme> _buildReadWriteNotifyButton(
//       BluetoothCharacteristic characteristic) {
//     List<ButtonTheme> buttons = <ButtonTheme>[];

//     if (characteristic.properties.read) {
//       buttons.add(
//         ButtonTheme(
//           minWidth: 10,
//           height: 20,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: TextButton(
//               child: const Text('READ', style: TextStyle(color: Colors.black)),
//               onPressed: () async {
//                 var sub = characteristic.lastValueStream.listen((value) {
//                   setState(() {
//                     widget.readValues[characteristic.uuid] = value;
//                   });
//                 });
//                 await characteristic.read();
//                 sub.cancel();
//               },
//             ),
//           ),
//         ),
//       );
//     }
//     if (characteristic.properties.write) {
//       buttons.add(
//         ButtonTheme(
//           minWidth: 10,
//           height: 20,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: ElevatedButton(
//               child: const Text('WRITE', style: TextStyle(color: Colors.black)),
//               onPressed: () async {
//                 await showDialog(
//                     context: context,
//                     builder: (BuildContext context) {
//                       return AlertDialog(
//                         title: const Text("Write"),
//                         content: Row(
//                           children: <Widget>[
//                             Expanded(
//                               child: TextField(
//                                 controller: _writeController,
//                               ),
//                             ),
//                           ],
//                         ),
//                         actions: <Widget>[
//                           TextButton(
//                             child: const Text("Send"),
//                             onPressed: () {
//                               characteristic.write(
//                                   utf8.encode(_writeController.value.text));
//                               Navigator.pop(context);
//                             },
//                           ),
//                           TextButton(
//                             child: const Text("Cancel"),
//                             onPressed: () {
//                               Navigator.pop(context);
//                             },
//                           ),
//                         ],
//                       );
//                     });
//               },
//             ),
//           ),
//         ),
//       );
//     }
//     if (characteristic.properties.notify) {
//       buttons.add(
//         ButtonTheme(
//           minWidth: 10,
//           height: 20,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: ElevatedButton(
//               child:
//                   const Text('NOTIFY', style: TextStyle(color: Colors.black)),
//               onPressed: () async {
//                 characteristic.lastValueStream.listen((value) {
//                   setState(() {
//                     widget.readValues[characteristic.uuid] = value;
//                   });
//                 });
//                 await characteristic.setNotifyValue(true);
//               },
//             ),
//           ),
//         ),
//       );
//     }

//     return buttons;
//   }

//   Widget _buildConnectDeviceView() {
//     List<Widget> containers = <Widget>[];
//     // for (BluetoothService service in _services) {
//     //   List<Widget> characteristicsWidget = <Widget>[];

//     //   for (BluetoothCharacteristic characteristic in service.characteristics) {
//     //     characteristicsWidget.add(
//     //       Align(
//     //         alignment: Alignment.centerLeft,
//     //         child: Column(
//     //           children: <Widget>[
//     //             Row(
//     //               children: <Widget>[
//     //                 Text(characteristic.uuid.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
//     //               ],
//     //             ),
//     //             Row(
//     //               children: <Widget>[
//     //                 ..._buildReadWriteNotifyButton(characteristic),
//     //               ],
//     //             ),
//     //             Row(
//     //               children: <Widget>[
//     //                 Expanded(child: Text('Value: ${widget.readValues[characteristic.uuid]}')),
//     //               ],
//     //             ),
//     //             const Divider(),
//     //           ],
//     //         ),
//     //       ),
//     //     );
//     //   }
//     //   containers.add(
//     //     ExpansionTile(title: Text(service.uuid.toString()), children: characteristicsWidget),
//     //   );
//     // }

//     // return ListView(
//     //   padding: const EdgeInsets.all(8),
//     //   children: <Widget>[
//     //     ...containers,
//     //   ],
//     // );

//     for (var service in _services) {
//       if (service.uuid.toString() == '181A') {
//         print('Found 181A service');
//         for (var characteristic in service.characteristics) {
//           if (characteristic.uuid.toString() == '2A6E') {
//             swingSpeedCharacteristic = characteristic;
//             readSwingSpeed();
//             characteristic.setNotifyValue(true);
//             characteristic.value.listen((value) {
//               setState(() {
//                 swingSpeed = "${value[0]} mph";
//               });
//             });
//           }
//           if (characteristic.uuid.toString() == '2A6F') {
//             ballSpeedCharacteristic = characteristic;
//             readBallSpeed();
//             characteristic.setNotifyValue(true);
//             characteristic.value.listen((value) {
//               setState(() {
//                 ballSpeed = "${value[0]} mph";
//               });
//             });
//           }
//         }
//       }
//     }
//     return getView();
//   }

//   Widget _buildView() {
//     // return _buildConnectDeviceView();
//     if (_connectedDevice != null) {
//       return _buildConnectDeviceView();
//     }
//     return _buildListViewOfDevices();
//   }

//   Widget getView() {
//     return Scaffold(
//       key: scaffoldKey,
//       backgroundColor: const Color(0xFFF1F4F8),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF1F4F8),
//         automaticallyImplyLeading: false,
//         title: Text("Golf Launch Monitor",
//             style: GoogleFonts.getFont(
//               'Lexend',
//               color: const Color(0xFF111417), // primary text color
//               fontWeight: FontWeight.w300,
//               fontSize: 32.0,
//             )),
//         actions: [],
//         centerTitle: false,
//         elevation: 0.0,
//       ),
//       body: SafeArea(
//           top: true,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.max,
//               children: [
//                 Padding(
//                   padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.max,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: MediaQuery.sizeOf(context).width * 0.92,
//                         decoration: BoxDecoration(
//                           boxShadow: [
//                             BoxShadow(
//                               blurRadius: 6.0,
//                               color: Color(0x4B1A1F24),
//                               offset: Offset(
//                                 0.0,
//                                 2.0,
//                               ),
//                             )
//                           ],
//                           gradient: LinearGradient(
//                             colors: [Color(0xFF00968A), Color(0xFFF2A384)],
//                             stops: [0.0, 1.0],
//                             begin: AlignmentDirectional(0.94, -1.0),
//                             end: AlignmentDirectional(-0.94, 1.0),
//                           ),
//                           borderRadius: BorderRadius.circular(8.0),
//                         ),
//                         child: Padding(
//                           padding: EdgeInsetsDirectional.fromSTEB(
//                               0.0, 0.0, 0.0, 10.0),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.max,
//                             children: [
//                               Padding(
//                                 padding: EdgeInsetsDirectional.fromSTEB(
//                                     20.0, 20.0, 20.0, 0.0),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.max,
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Image.asset(
//                                       'assets/images/icons8-golfer-50.png',
//                                       width: 47.0,
//                                       height: 49.0,
//                                       fit: BoxFit.cover,
//                                     ),
//                                     Image.asset(
//                                       'assets/images/icons8-golf-ball-50.png',
//                                       width: 47.0,
//                                       height: 49.0,
//                                       fit: BoxFit.cover,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               Padding(
//                                 padding: EdgeInsetsDirectional.fromSTEB(
//                                     20.0, 10.0, 20.0, 0.0),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.max,
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text("Swing Speed",
//                                         style: GoogleFonts.getFont(
//                                           'Lexend',
//                                           color: const Color(0xFF111417),
//                                           fontWeight: FontWeight.normal,
//                                           fontSize: 14.0,
//                                         )),
//                                     Text("BallSpeed",
//                                         textAlign: TextAlign.end,
//                                         style: GoogleFonts.getFont(
//                                           'Lexend',
//                                           color: const Color(0xFF111417),
//                                           fontWeight: FontWeight.normal,
//                                           fontSize: 14.0,
//                                         )),
//                                   ],
//                                 ),
//                               ),
//                               Padding(
//                                 padding: EdgeInsetsDirectional.fromSTEB(
//                                     20.0, 8.0, 20.0, 0.0),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.max,
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(swingSpeed,
//                                         textAlign: TextAlign.start,
//                                         style: GoogleFonts.getFont(
//                                           'Lexend',
//                                           color: const Color(0xFF111417),
//                                           fontWeight: FontWeight.w300,
//                                           fontSize: 32.0,
//                                         )),
//                                     Text(ballSpeed,
//                                         textAlign: TextAlign.end,
//                                         style: GoogleFonts.getFont(
//                                           'Lexend',
//                                           color: const Color(0xFF111417),
//                                           fontWeight: FontWeight.w300,
//                                           fontSize: 32.0,
//                                         )),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               ],
//             ),
//           )),
//     );
//   }

//   void readSwingSpeed() async {
//     if (swingSpeedCharacteristic != null) {
//       try {
//         var value = await swingSpeedCharacteristic?.read();
//         if (value != null && value.isNotEmpty) {
//           setState(() {
//             swingSpeed = "${value[0]} mph";
//           });
//         } else {
//           print('Swing Speed value is null or empty');
//         }
//       } catch (e) {
//         print('Error reading Swing Speed: $e');
//       }
//     } else {
//       print('Swing Speed characteristic is null');
//     }
//   }

//   void readBallSpeed() async {
//     if (ballSpeedCharacteristic != null) {
//       try {
//         var value = await ballSpeedCharacteristic?.read();
//         if (value != null && value.isNotEmpty) {
//           setState(() {
//             ballSpeed = "${value[0]} mph";
//           });
//         } else {
//           print('Ball Speed value is null or empty');
//         }
//       } catch (e) {
//         print('Error reading Ball Speed: $e');
//       }
//     } else {
//       print('Ball Speed characteristic is null');
//     }
//   }

//   @override
//   Widget build(BuildContext context) => Scaffold(
//         appBar: AppBar(
//           title: Text(widget.title),
//         ),
//         body: _buildView(),
//       );
// }

// my version
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:permission_handler/permission_handler.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) => MaterialApp(
//         title: 'Golf Launch Monitor',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//         ),
//         home: MyHomePage(title: 'Golf Launch Monitor'),
//       );
// }

// class MyHomePage extends StatefulWidget {
//   MyHomePage({Key? key, required this.title}) : super(key: key);

//   final String title;
//   final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
//   final Map<Guid, List<int>> readValues = <Guid, List<int>>{};

//   @override
//   MyHomePageState createState() => MyHomePageState();
// }

// class MyHomePageState extends State<MyHomePage> {
//   final _writeController = TextEditingController();
//   BluetoothDevice? _connectedDevice;
//   List<BluetoothService> _services = [];

//   final scaffoldKey = GlobalKey<ScaffoldState>();
//   BluetoothCharacteristic? swingSpeedCharacteristic;
//   BluetoothCharacteristic? ballSpeedCharacteristic;

//   String swingSpeed = "78 mph";
//   String ballSpeed = "100 mph";

//   final BluetoothController _bluetoothController = BluetoothController();

//   @override
//   void initState() {
//     super.initState();
//     requestPermissions();
//     _bluetoothController.initBluetooth();
//     _bluetoothController.deviceStream.listen((devices) {
//       setState(() {
//         widget.devicesList.clear();
//         widget.devicesList.addAll(devices);
//       });
//     });
//   }

//   Future<void> requestPermissions() async {
//     Map<Permission, PermissionStatus> statuses = await [
//       Permission.bluetooth,
//       Permission.bluetoothScan,
//       Permission.bluetoothConnect,
//       Permission.bluetoothAdvertise,
//       Permission.location,
//     ].request();

//     if (statuses.values.every((status) => status.isGranted)) {
//       print("All permissions granted");
//     } else {
//       print("Permissions not granted");
//     }
//   }

//   ListView _buildListViewOfDevices() {
//     List<Widget> containers = <Widget>[];
//     for (BluetoothDevice device in widget.devicesList) {
//       containers.add(
//         SizedBox(
//           height: 50,
//           child: Row(
//             children: <Widget>[
//               Expanded(
//                 child: Column(
//                   children: <Widget>[
//                     Text(device.name == '' ? '(unknown device)' : device.name),
//                     Text(device.remoteId.toString()),
//                   ],
//                 ),
//               ),
//               TextButton(
//                 child: const Text(
//                   'Connect',
//                   style: TextStyle(color: Colors.black),
//                 ),
//                 onPressed: () async {
//                   await _bluetoothController.connectToDevice(device);
//                   setState(() {
//                     _connectedDevice = device;
//                     _services = _bluetoothController.services;
//                   });
//                 },
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return ListView(
//       padding: const EdgeInsets.all(8),
//       children: <Widget>[
//         ...containers,
//       ],
//     );
//   }

//   List<ButtonTheme> _buildReadWriteNotifyButton(
//       BluetoothCharacteristic characteristic) {
//     List<ButtonTheme> buttons = <ButtonTheme>[];

//     if (characteristic.properties.read) {
//       buttons.add(
//         ButtonTheme(
//           minWidth: 10,
//           height: 20,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: TextButton(
//               child: const Text('READ', style: TextStyle(color: Colors.black)),
//               onPressed: () async {
//                 var sub = characteristic.lastValueStream.listen((value) {
//                   setState(() {
//                     widget.readValues[characteristic.uuid] = value;
//                   });
//                 });
//                 await characteristic.read();
//                 sub.cancel();
//               },
//             ),
//           ),
//         ),
//       );
//     }
//     if (characteristic.properties.write) {
//       buttons.add(
//         ButtonTheme(
//           minWidth: 10,
//           height: 20,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: ElevatedButton(
//               child: const Text('WRITE', style: TextStyle(color: Colors.black)),
//               onPressed: () async {
//                 await showDialog(
//                     context: context,
//                     builder: (BuildContext context) {
//                       return AlertDialog(
//                         title: const Text("Write"),
//                         content: Row(
//                           children: <Widget>[
//                             Expanded(
//                               child: TextField(
//                                 controller: _writeController,
//                               ),
//                             ),
//                           ],
//                         ),
//                         actions: <Widget>[
//                           TextButton(
//                             child: const Text("Send"),
//                             onPressed: () {
//                               characteristic.write(
//                                   utf8.encode(_writeController.value.text));
//                               Navigator.pop(context);
//                             },
//                           ),
//                           TextButton(
//                             child: const Text("Cancel"),
//                             onPressed: () {
//                               Navigator.pop(context);
//                             },
//                           ),
//                         ],
//                       );
//                     });
//               },
//             ),
//           ),
//         ),
//       );
//     }
//     if (characteristic.properties.notify) {
//       buttons.add(
//         ButtonTheme(
//           minWidth: 10,
//           height: 20,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: ElevatedButton(
//               child:
//                   const Text('NOTIFY', style: TextStyle(color: Colors.black)),
//               onPressed: () async {
//                 characteristic.lastValueStream.listen((value) {
//                   setState(() {
//                     widget.readValues[characteristic.uuid] = value;
//                   });
//                 });
//                 await characteristic.setNotifyValue(true);
//               },
//             ),
//           ),
//         ),
//       );
//     }

//     return buttons;
//   }

//   Widget _buildConnectDeviceView() {
//     List<Widget> containers = <Widget>[];

//     for (var service in _services) {
//       if (service.uuid.toString() == '181A') {
//         print('Found 181A service');
//         for (var characteristic in service.characteristics) {
//           if (characteristic.uuid.toString() == '2A6E') {
//             swingSpeedCharacteristic = characteristic;
//             readSwingSpeed();
//             characteristic.setNotifyValue(true);
//             characteristic.value.listen((value) {
//               setState(() {
//                 swingSpeed = "${value[0]} mph";
//               });
//             });
//           }
//           if (characteristic.uuid.toString() == '2A6F') {
//             ballSpeedCharacteristic = characteristic;
//             readBallSpeed();
//             characteristic.setNotifyValue(true);
//             characteristic.value.listen((value) {
//               setState(() {
//                 ballSpeed = "${value[0]} mph";
//               });
//             });
//           }
//         }
//       }
//     }
//     return getView();
//   }

//   Widget _buildView() {
//     if (_connectedDevice != null) {
//       return _buildConnectDeviceView();
//     }
//     return _buildListViewOfDevices();
//   }

//   Widget getView() {
//     return Scaffold(
//       key: scaffoldKey,
//       backgroundColor: const Color(0xFFF1F4F8),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF1F4F8),
//         automaticallyImplyLeading: false,
//         title: Text("Golf Launch Monitor",
//             style: GoogleFonts.getFont(
//               'Lexend',
//               color: const Color(0xFF111417), // primary text color
//               fontWeight: FontWeight.w300,
//               fontSize: 32.0,
//             )),
//         actions: [],
//         centerTitle: false,
//         elevation: 0.0,
//       ),
//       body: SafeArea(
//           top: true,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.max,
//               children: [
//                 Padding(
//                   padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.max,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: MediaQuery.sizeOf(context).width * 0.92,
//                         decoration: BoxDecoration(
//                           boxShadow: [
//                             BoxShadow(
//                               blurRadius: 6.0,
//                               color: Color(0x4B1A1F24),
//                               offset: Offset(
//                                 0.0,
//                                 2.0,
//                               ),
//                             )
//                           ],
//                           gradient: LinearGradient(
//                             colors: [Color(0xFF00968A), Color(0xFFF2A384)],
//                             stops: [0.0, 1.0],
//                             begin: AlignmentDirectional(0.94, -1.0),
//                             end: AlignmentDirectional(-0.94, 1.0),
//                           ),
//                           borderRadius: BorderRadius.circular(8.0),
//                         ),
//                         child: Padding(
//                           padding: EdgeInsetsDirectional.fromSTEB(
//                               0.0, 0.0, 0.0, 10.0),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.max,
//                             children: [
//                               Padding(
//                                 padding: EdgeInsetsDirectional.fromSTEB(
//                                     20.0, 20.0, 20.0, 0.0),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.max,
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Image.asset(
//                                       'assets/images/icons8-golfer-50.png',
//                                       width: 47.0,
//                                       height: 49.0,
//                                       fit: BoxFit.cover,
//                                     ),
//                                     Image.asset(
//                                       'assets/images/icons8-golf-ball-50.png',
//                                       width: 47.0,
//                                       height: 49.0,
//                                       fit: BoxFit.cover,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               Padding(
//                                 padding: EdgeInsetsDirectional.fromSTEB(
//                                     20.0, 10.0, 20.0, 0.0),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.max,
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text("Swing Speed",
//                                         style: GoogleFonts.getFont(
//                                           'Lexend',
//                                           color: const Color(0xFF111417),
//                                           fontWeight: FontWeight.normal,
//                                           fontSize: 14.0,
//                                         )),
//                                     Text("BallSpeed",
//                                         textAlign: TextAlign.end,
//                                         style: GoogleFonts.getFont(
//                                           'Lexend',
//                                           color: const Color(0xFF111417),
//                                           fontWeight: FontWeight.normal,
//                                           fontSize: 14.0,
//                                         )),
//                                   ],
//                                 ),
//                               ),
//                               Padding(
//                                 padding: EdgeInsetsDirectional.fromSTEB(
//                                     20.0, 8.0, 20.0, 0.0),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.max,
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     Text(swingSpeed,
//                                         textAlign: TextAlign.start,
//                                         style: GoogleFonts.getFont(
//                                           'Lexend',
//                                           color: const Color(0xFF111417),
//                                           fontWeight: FontWeight.w300,
//                                           fontSize: 32.0,
//                                         )),
//                                     Text(ballSpeed,
//                                         textAlign: TextAlign.end,
//                                         style: GoogleFonts.getFont(
//                                           'Lexend',
//                                           color: const Color(0xFF111417),
//                                           fontWeight: FontWeight.w300,
//                                           fontSize: 32.0,
//                                         )),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 )
//               ],
//             ),
//           )),
//     );
//   }

//   void readSwingSpeed() async {
//     if (swingSpeedCharacteristic != null) {
//       try {
//         var value = await swingSpeedCharacteristic?.read();
//         if (value != null && value.isNotEmpty) {
//           setState(() {
//             swingSpeed = "${value[0]} mph";
//           });
//         } else {
//           print('Swing Speed value is null or empty');
//         }
//       } catch (e) {
//         print('Error reading Swing Speed: $e');
//       }
//     } else {
//       print('Swing Speed characteristic is null');
//     }
//   }

//   void readBallSpeed() async {
//     if (ballSpeedCharacteristic != null) {
//       try {
//         var value = await ballSpeedCharacteristic?.read();
//         if (value != null && value.isNotEmpty) {
//           setState(() {
//             ballSpeed = "${value[0]} mph";
//           });
//         } else {
//           print('Ball Speed value is null or empty');
//         }
//       } catch (e) {
//         print('Error reading Ball Speed: $e');
//       }
//     } else {
//       print('Ball Speed characteristic is null');
//     }
//   }

//   @override
//   Widget build(BuildContext context) => Scaffold(
//         appBar: AppBar(
//           title: Text(widget.title),
//         ),
//         body: _buildView(),
//       );
// }

// class BluetoothController {
//   final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
//   final Map<Guid, List<int>> readValues = <Guid, List<int>>{};
//   BluetoothDevice? connectedDevice;
//   List<BluetoothService> services = [];
//   final StreamController<List<BluetoothDevice>> _deviceStreamController =
//       StreamController<List<BluetoothDevice>>.broadcast();
//   Stream<List<BluetoothDevice>> get deviceStream =>
//       _deviceStreamController.stream;

//   void dispose() {
//     _deviceStreamController.close();
//   }

//   Future<void> initBluetooth() async {
//     await requestPermissions();

//     var subscription = FlutterBluePlus.onScanResults.listen(
//       (results) {
//         print("Scan results received: ${results.length} devices found.");
//         if (results.isNotEmpty) {
//           for (ScanResult result in results) {
//             print(
//                 "Device found: ${result.device.advName} - ${result.device.mtu}");
//             _addDeviceTolist(result.device);
//           }
//         }
//       },
//       onError: (e) {
//         print("Error while scanning: $e");
//       },
//     );

//     FlutterBluePlus.cancelWhenScanComplete(subscription);
//     await FlutterBluePlus.adapterState
//         .where((val) => val == BluetoothAdapterState.on)
//         .first;
//     await FlutterBluePlus.startScan();
//     await FlutterBluePlus.isScanning.where((val) => val == false).first;

//     for (BluetoothDevice device in await FlutterBluePlus.connectedDevices) {
//       _addDeviceTolist(device);
//     }
//   }

//   Future<void> requestPermissions() async {
//     var status = await Permission.location.status;
//     if (status.isDenied) {
//       await Permission.location.request();
//     }
//     if (await Permission.location.status.isPermanentlyDenied) {
//       openAppSettings();
//     }
//   }

//   void _addDeviceTolist(final BluetoothDevice device) {
//     if (!devicesList.contains(device)) {
//       devicesList.add(device);
//       _deviceStreamController.add(devicesList);
//     }
//   }

//   Future<void> connectToDevice(BluetoothDevice device) async {
//     try {
//       await FlutterBluePlus.stopScan();
//       await device.connect();
//       services = await device.discoverServices();
//       connectedDevice = device;
//     } on PlatformException catch (e) {
//       if (e.code != 'already_connected') {
//         rethrow;
//       }
//     }
//   }

//   Future<void> disconnectFromDevice() async {
//     if (connectedDevice != null) {
//       await connectedDevice!.disconnect();
//       connectedDevice = null;
//     }
//   }
// }

//next version

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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
  final _writeController = TextEditingController();
  BluetoothDevice? _connectedDevice;
  List<BluetoothService> _services = [];

  final scaffoldKey = GlobalKey<ScaffoldState>();
  BluetoothCharacteristic? swingSpeedCharacteristic;
  BluetoothCharacteristic? ballSpeedCharacteristic;

  String swingSpeed = "78 mph";
  String ballSpeed = "100 mph";

  final BluetoothController _bluetoothController = BluetoothController();

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _bluetoothController.initBluetooth();
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
    ].request();

    if (statuses.values.every((status) => status.isGranted)) {
      print("All permissions granted");
    } else {
      print("Permissions not granted");
    }
  }

  ListView _buildListViewOfDevices() {
    List<Widget> containers = <Widget>[];
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        SizedBox(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? '(unknown device)' : device.name),
                    Text(device.remoteId.toString()),
                  ],
                ),
              ),
              TextButton(
                child: const Text(
                  'Connect',
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () async {
                  await _bluetoothController.connectToDevice(device);
                  setState(() {
                    _connectedDevice = device;
                    _services = _bluetoothController.services;
                  });
                },
              ),
            ],
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

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = <ButtonTheme>[];

    if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              child: const Text('READ', style: TextStyle(color: Colors.black)),
              onPressed: () async {
                var sub = characteristic.lastValueStream.listen((value) {
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                  });
                });
                await characteristic.read();
                sub.cancel();
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child: const Text('WRITE', style: TextStyle(color: Colors.black)),
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Write"),
                        content: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _writeController,
                              ),
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text("Send"),
                            onPressed: () {
                              characteristic.write(
                                  utf8.encode(_writeController.value.text));
                              Navigator.pop(context);
                            },
                          ),
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              child:
                  const Text('NOTIFY', style: TextStyle(color: Colors.black)),
              onPressed: () async {
                characteristic.lastValueStream.listen((value) {
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                  });
                });
                await characteristic.setNotifyValue(true);
              },
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  Widget _buildConnectDeviceView() {
    List<Widget> containers = <Widget>[];

    for (var service in _services) {
      if (service.uuid.toString() == '181A') {
        print('Found 181A service');
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == '2A6E') {
            swingSpeedCharacteristic = characteristic;
            readSwingSpeed();
            characteristic.setNotifyValue(true);
            characteristic.value.listen((value) {
              setState(() {
                swingSpeed = "${value[0]} mph";
              });
            });
          }
          if (characteristic.uuid.toString() == '2A6F') {
            ballSpeedCharacteristic = characteristic;
            readBallSpeed();
            characteristic.setNotifyValue(true);
            characteristic.value.listen((value) {
              setState(() {
                ballSpeed = "${value[0]} mph";
              });
            });
          }
        }
      }
    }
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
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
                            colors: [Color(0xFF00968A), Color(0xFFF2A384)],
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
                                    Text("BallSpeed",
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
                                  child: const Text('Disconnect and Go Back'),
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
          )),
    );
  }

  void readSwingSpeed() async {
    if (swingSpeedCharacteristic != null) {
      try {
        var value = await swingSpeedCharacteristic?.read();
        if (value != null && value.isNotEmpty) {
          setState(() {
            swingSpeed = "${value[0]} mph";
          });
        } else {
          print('Swing Speed value is null or empty');
        }
      } catch (e) {
        print('Error reading Swing Speed: $e');
      }
    } else {
      print('Swing Speed characteristic is null');
    }
  }

  void readBallSpeed() async {
    if (ballSpeedCharacteristic != null) {
      try {
        var value = await ballSpeedCharacteristic?.read();
        if (value != null && value.isNotEmpty) {
          setState(() {
            ballSpeed = "${value[0]} mph";
          });
        } else {
          print('Ball Speed value is null or empty');
        }
      } catch (e) {
        print('Error reading Ball Speed: $e');
      }
    } else {
      print('Ball Speed characteristic is null');
    }
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
    } on PlatformException catch (e) {
      if (e.code != 'already_connected') {
        rethrow;
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
