import 'dart:async';

import 'dart:io';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:get/get.dart';
import 'package:smart_events_app_flutter/utils/app_constants.dart';

import '../controller/requirement_state_controller.dart';

class BeaconScanner extends StatefulWidget {
  const BeaconScanner({Key? key}) : super(key: key);

  @override
  _BeaconScannerState createState() => _BeaconScannerState();
}

class _BeaconScannerState extends State<BeaconScanner> with WidgetsBindingObserver {
  StreamSubscription<RangingResult>? _streamRanging;
  final _regionBeacons = <Region, List<Beacon>>{};
  final _beacons = <Beacon>[];
  final controller = Get.find<RequirementStateController>();
  StreamSubscription<BluetoothState>? _streamBluetooth;

  @override
  void initState() {
    print("Init");

    WidgetsBinding.instance?.addObserver(this);

    super.initState();

    listeningState();

    controller.startStream.listen((flag) {
      if (flag == true) {
        initScanBeacon();
      }
    });

    controller.pauseStream.listen((flag) {
      if (flag == true) {
        pauseScanBeacon();
      }
    });
  }

  listeningState() async {
    print('Listening to bluetooth state');
    _streamBluetooth = flutterBeacon
        .bluetoothStateChanged()
        .listen((BluetoothState state) async {
      controller.updateBluetoothState(state);
      await checkAllRequirements();
    });
  }

  checkAllRequirements() async {
    final bluetoothState = await flutterBeacon.bluetoothState;
    controller.updateBluetoothState(bluetoothState);
    print('BLUETOOTH $bluetoothState');

    final authorizationStatus = await flutterBeacon.authorizationStatus;
    controller.updateAuthorizationStatus(authorizationStatus);
    print('AUTHORIZATION $authorizationStatus');

    final locationServiceEnabled =
    await flutterBeacon.checkLocationServicesIfEnabled;
    controller.updateLocationService(locationServiceEnabled);
    print('LOCATION SERVICE $locationServiceEnabled');

    if (controller.bluetoothEnabled &&
        controller.authorizationStatusOk &&
        controller.locationServiceEnabled) {
      print('STATE READY');
      print('SCANNING');
      controller.startScanning();
    } else {
      print('STATE NOT READY');
      controller.pauseScanning();
    }
  }

  /*@override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print('AppLifecycleState = $state');
    if (state == AppLifecycleState.resumed) {
      if (_streamBluetooth != null) {
        if (_streamBluetooth!.isPaused) {
          _streamBluetooth?.resume();
        }
      }
      await checkAllRequirements();
    } else if (state == AppLifecycleState.paused) {
      _streamBluetooth?.pause();
    }
  }*/

  initScanBeacon() async {
    print("Init Scan");

    await flutterBeacon.initializeScanning;
    if (!controller.authorizationStatusOk ||
        !controller.locationServiceEnabled ||
        !controller.bluetoothEnabled) {
      print(
          'RETURNED, authorizationStatusOk=${controller.authorizationStatusOk}, '
              'locationServiceEnabled=${controller.locationServiceEnabled}, '
              'bluetoothEnabled=${controller.bluetoothEnabled}');
      return;
    }
    //"Alec iPhone Beacon", "715b00d1-6f35-510a-a219-f56661916498"
    final regions = <Region>[
      Region(
        identifier: 'Alec iPhone Beacon',
        proximityUUID: '715b00d1-6f35-510a-a219-f56661916498',
      ),
      Region(
        identifier: 'Alec Pixel 3XL',
        proximityUUID: 'ec266c73-95ce-4dbd-a46b-512a7da721d5',
      ),
      Region(
        identifier: 'SmartEvents#1',
        proximityUUID: '56ad5235-0a79-4931-b1dd-5d16c5334c20',
      ),
      Region(
        identifier: 'SmartEvents#2',
        proximityUUID: 'aa9e6759-47b8-4bd1-8bf2-76b289d46760',
      ),
      Region(
        identifier: 'SmartEvents#3',
        proximityUUID: '8940b363-00c4-433e-818b-cca6f0949645',
      ),
      Region(
        identifier: 'SmartEvents#4',
        proximityUUID: '83c51e77-8859-4cc6-a959-b237cd213264',
      ),
    ];

    if (_streamRanging != null) {
      if (_streamRanging!.isPaused) {
        _streamRanging?.resume();
        return;
      }
    }

    _streamRanging =
        flutterBeacon.ranging(regions).listen((RangingResult result) {
          print(result);
          if (mounted) {
            setState(() {
              _regionBeacons[result.region] = result.beacons;
              _beacons.clear();
              _regionBeacons.values.forEach((list) {
                _beacons.addAll(list);
              });
              _beacons.sort(_compareParameters);
            });
          }
        });
  }

  pauseScanBeacon() async {
    _streamRanging?.pause();
    if (_beacons.isNotEmpty) {
      setState(() {
        _beacons.clear();
      });
    }
  }

  int _compareParameters(Beacon a, Beacon b) {
    int compare = a.proximityUUID.compareTo(b.proximityUUID);

    if (compare == 0) {
      compare = a.major.compareTo(b.major);
    }

    if (compare == 0) {
      compare = a.minor.compareTo(b.minor);
    }

    return compare;
  }

  @override
  void dispose() {
    print("Dispose");
    _streamRanging?.cancel();
    _streamBluetooth?.cancel();
    controller.pauseScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text("Check In Scanner"),
      children:[
        Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(() {
                    if (!controller.locationServiceEnabled) {
                      return IconButton(
                        tooltip: 'Not Determined',
                        icon: const Icon(Icons.portable_wifi_off),
                        color: Colors.grey,
                        onPressed: () {},
                      );
                    }

                    if (!controller.authorizationStatusOk) {
                      return IconButton(
                        tooltip: 'Not Authorized',
                        icon: const Icon(Icons.portable_wifi_off),
                        color: Colors.red,
                        onPressed: () async {
                          await flutterBeacon.requestAuthorization;
                        },
                      );
                    }

                    return IconButton(
                      tooltip: 'Authorized',
                      icon: const Icon(Icons.wifi_tethering),
                      color: Colors.green,
                      onPressed: () async {
                        await flutterBeacon.requestAuthorization;
                      },
                    );
                  }),
                  Obx(() {
                    return IconButton(
                      tooltip: controller.locationServiceEnabled
                          ? 'Location Service ON'
                          : 'Location Service OFF',
                      icon: Icon(
                        controller.locationServiceEnabled
                            ? Icons.location_on
                            : Icons.location_off,
                      ),
                      color:
                      controller.locationServiceEnabled ? Colors.green : Colors.red,
                      onPressed: controller.locationServiceEnabled
                          ? () {}
                          : handleOpenLocationSettings,
                    );
                  }),
                  Obx(() {
                    final state = controller.bluetoothState.value;

                    if (state == BluetoothState.stateOn) {
                      return IconButton(
                        tooltip: 'Bluetooth ON',
                        icon: const Icon(Icons.bluetooth_connected),
                        onPressed: () {},
                        color: Colors.green,
                      );
                    }

                    if (state == BluetoothState.stateOff) {
                      return IconButton(
                        tooltip: 'Bluetooth OFF',
                        icon: const Icon(Icons.bluetooth),
                        onPressed: handleOpenBluetooth,
                        color: Colors.red,
                      );
                    }

                    return IconButton(
                      icon: const Icon(Icons.bluetooth_disabled),
                      tooltip: 'Bluetooth State Unknown',
                      onPressed: () {},
                      color: Colors.grey,
                    );
                  }),
                ],
              ),
              Visibility(
                  visible: !controller.locationServiceEnabled,
                  child: const Text("Location Permission Denied", style: TextStyle(color: Colors.red))
              ),
              Visibility(
                  visible: !controller.authorizationStatusOk,
                  child: const Text("Bluetooth Scanning Permission Disabled", style: TextStyle(color: Colors.red))
              ),
              Visibility(
                  visible: !controller.bluetoothEnabled,
                  child: const Text("Bluetooth is Off", style: TextStyle(color: Colors.red))
              ),
              Visibility(
                  visible: controller.bluetoothEnabled &&
                      controller.authorizationStatusOk &&
                      controller.locationServiceEnabled,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 10.0, left: 16.0, right: 16.0),
                    child: LinearProgressIndicator(
                      semanticsLabel: 'Linear progress indicator',
                    )
                  )
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //BeaconScannerTest()
                  SizedBox(
                      height: 200,
                      width: 300,
                      child: Visibility(
                        visible: _beacons.isNotEmpty,
                        child: ListView.builder(
                          itemCount: _beacons.length,
                          itemBuilder: (context, index) {
                            final Beacon item = _beacons[index];

                            return ListTile(
                              title: Text(item.proximityUUID),
                              subtitle: Text('${item.accuracy}m'),
                            );
                          },
                        ),
                      ),
                    )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: const Text('Check In', style: TextStyle(fontSize: 20.0),),
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(_beacons.isEmpty ? Colors.grey : AppConstants.COLOR_CEDARVILLE_YELLOW)),
                    onPressed: () {
                      if(_beacons.isNotEmpty){

                      }
                    },
                  ),
                ],
              )
            ]
        )
      ],
      elevation: 10,
    );
  }

  handleOpenLocationSettings() async {
    if (Platform.isAndroid) {
      await flutterBeacon.openLocationSettings;
    } else if (Platform.isIOS) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Location Services Off'),
            content: const Text(
              'Please enable Location Services on Settings > Privacy > Location Services.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  handleOpenBluetooth() async {
    if (Platform.isAndroid) {
      try {
        await flutterBeacon.openBluetoothSettings;
      } on PlatformException catch (e) {
        print(e);
      }
    } else if (Platform.isIOS) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Bluetooth is Off'),
            content: const Text('Please enable Bluetooth on Settings > Bluetooth.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}