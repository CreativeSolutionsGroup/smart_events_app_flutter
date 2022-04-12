import 'dart:async';

import 'dart:io';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:get/get.dart';
import 'package:smart_events_app_flutter/utils/app_constants.dart';

import '../controller/requirement_state_controller.dart';
import '../utils/checkin.dart';

class BeaconScanner extends StatefulWidget {
  const BeaconScanner({Key? key}) : super(key: key);

  @override
  _BeaconScannerState createState() => _BeaconScannerState();
}

class DataRequiredForBuild {
  List<CheckIn> checkIns;
  Map<String, BeaconSE> beacons;

  DataRequiredForBuild({
    required this.checkIns,
    required this.beacons
  });
}

class _BeaconScannerState extends State<BeaconScanner> with WidgetsBindingObserver {
  StreamSubscription<RangingResult>? _streamRanging;
  final _regionBeacons = <Region, List<Beacon>>{};
  final _beacons = <Beacon>[];
  final controller = Get.find<RequirementStateController>();
  StreamSubscription<BluetoothState>? _streamBluetooth;

  late Future<List<CheckIn>> _checkIns;
  late Map<String, BeaconSE> seBeacons;
  CheckIn? selectedCheckIn;

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    _checkIns = _fetchActiveCheckins();

    super.initState();

    setupScanner();
  }

  Future<List<CheckIn>> _fetchActiveCheckins() async {
    List<CheckIn> checkIns = await CheckIn.fetchActiveCheckins();
    if(checkIns.isNotEmpty) {
      setState(() {
        selectedCheckIn = checkIns.elementAt(0);
      });
    }
    return checkIns;
  }

  setupScanner() async {
    List<BeaconSE> apiBeacons = await BeaconSE.fetchBeacons();
    Map<String, BeaconSE> seBeaconsMap = {};
    for(BeaconSE b in apiBeacons){
      seBeaconsMap.putIfAbsent(b.id, () => b);
    }
    setState(() {
      seBeacons = seBeaconsMap;
    });

    listeningState();

    controller.startStream.listen((flag) {
      if (flag == true) {
        initScanBeacon(seBeacons.values.toList());
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

  initScanBeacon(List<BeaconSE> seBeaconList) async {
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
    // final regions = <Region>[
    //   Region(
    //     identifier: 'Alec iPhone Beacon',
    //     proximityUUID: '715b00d1-6f35-510a-a219-f56661916498',
    //   ),
    //   // Region(
    //   //   identifier: 'Alec Pixel 3XL',
    //   //   proximityUUID: 'ec266c73-95ce-4dbd-a46b-512a7da721d5',
    //   // ),
    //   Region(
    //     identifier: 'SmartEvents#1',
    //     proximityUUID: '56ad5235-0a79-4931-b1dd-5d16c5334c20',
    //   ),
    //   Region(
    //     identifier: 'SmartEvents#2',
    //     proximityUUID: 'aa9e6759-47b8-4bd1-8bf2-76b289d46760',
    //   ),
    //   Region(
    //     identifier: 'SmartEvents#3',
    //     proximityUUID: '8940b363-00c4-433e-818b-cca6f0949645',
    //   ),
    //   Region(
    //     identifier: 'SmartEvents#4',
    //     proximityUUID: '83c51e77-8859-4cc6-a959-b237cd213264',
    //   ),
    // ];

    List<Region> regions = seBeaconList.map((e) => Region(identifier: e.identifier, proximityUUID: e.uuid)).toList();
    /*regions.add(Region(
        identifier: 'Alec iPhone Beacon',
        proximityUUID: '715b00d1-6f35-510a-a219-f56661916498',
    ));*/

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
      title: const Center(child: Text("Check In Scanner")),
      children:[
        FutureBuilder <List<CheckIn>>(
          future: _checkIns,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              List<CheckIn> checkIns = snapshot.data!;
              if(checkIns.isEmpty){
                return const Center(
                  child: Text("No events happening", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                );
              }
              return buildScanner(context, checkIns);
            }
            else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            // By default show a loading spinner.
            return const CircularProgressIndicator();
          }
        )
      ],
      elevation: 10,
    );
  }

  isCheckInValid(){
    if(_beacons.isEmpty){
      return false;
    }
    if(selectedCheckIn == null){
      return false;
    }

    //Check if the current selected check in has any of the beacons in range in its list
    List<String> beaconIds = selectedCheckIn!.beacon_ids;
    List<String> connectedUUIDs = _beacons.map((e) => e.proximityUUID.toLowerCase()).toList();

    for(String beacon in beaconIds){
      BeaconSE? beaconSE = seBeacons[beacon];
      if(beaconSE != null && connectedUUIDs.contains(beaconSE.uuid.toLowerCase())){
        return true;
      }
    }

    return false;
  }

  BeaconSE? findBeaconByUUID(String uuid){
    for(BeaconSE b in seBeacons.values){
      if(b.uuid.toLowerCase() == uuid.toLowerCase()){
        return b;
      }
    }
    return null;
  }

  Widget buildScanner(BuildContext context, List<CheckIn> checkIns){
    return Column(
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
                  padding: EdgeInsets.only(top: 10.0, left: 16.0, right: 16.0, bottom: 10),
                  child: LinearProgressIndicator(
                    semanticsLabel: 'Scanning Indicator',
                  )
              )
          ),
          const Text("Beacons", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 300,
                child: Visibility(
                  visible: _beacons.isNotEmpty,
                  child: ListView.builder(
                    itemCount: _beacons.length,
                    itemBuilder: (context, index) {
                      final Beacon item = _beacons[index];

                      BeaconSE? seBeacon = findBeaconByUUID(item.proximityUUID);

                      String name = seBeacon !=null ? seBeacon.name : "???";

                      return ListTile(
                        title: Text(name),
                        subtitle: Text('${item.accuracy}m'),
                      );
                    },
                  ),
                ),
              )
            ],
          ),
          const Text("Active Checkins", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 150,
                width: 300,
                child: Visibility(
                  visible: checkIns.isNotEmpty,
                  child: ListView.builder(
                    itemCount: checkIns.length,
                    itemBuilder: (context, index) {
                      final CheckIn item = checkIns[index];

                      return ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Visibility(
                              visible: selectedCheckIn != null && selectedCheckIn!.id == item.id,
                              child: const Icon(Icons.check_circle, color: AppConstants.COLOR_CEDARVILLE_YELLOW),
                            ),
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
                          ]
                        ),
                        subtitle: Column(
                          children: [
                            Text(item.description)
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            selectedCheckIn = item;
                          });
                        },
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
                style: ButtonStyle(backgroundColor: MaterialStateProperty.all(!isCheckInValid() ? Colors.grey : AppConstants.COLOR_CEDARVILLE_YELLOW)),
                onPressed: () {
                  if(isCheckInValid()){

                  }
                },
              ),
            ],
          )
        ]
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