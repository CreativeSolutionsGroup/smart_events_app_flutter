import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//import 'package:cached_network_image/cached_network_image.dart';

import 'package:smart_events_app_flutter/utils/app_constants.dart';
import 'package:smart_events_app_flutter/utils/strings.dart';

class AttractionData {
  final String id;
  final String event_id;
  final String name;
  final String description;
  final String image_url;
  final String start_time;
  final String end_time;
  final String location;
  final bool hidden;

  AttractionData({
    required this.id,
    required this.event_id,
    required this.name,
    required this.description,
    required this.image_url,
    required this.start_time,
    required this.end_time,
    required this.location,
    required this.hidden
  });

  factory AttractionData.fromJson(Map<String, dynamic> json) {
    return AttractionData(
      id: json['_id'],
      event_id: json['event_id'],
      name: json['name'],
      description: json['description'],
      image_url: json['image_url'],
      start_time: json['start_time'],
      end_time: json['end_time'],
      location: json['location'],
      hidden: json['hidden'],
    );
  }
}

class SlotData {
  final String id;
  final String attraction_id;
  final String label;
  final int ticket_capacity;
  final String hide_time;

  SlotData({
    required this.id,
    required this.attraction_id,
    required this.label,
    required this.ticket_capacity,
    required this.hide_time
  });

  factory SlotData.fromJson(Map<String, dynamic> json) {
    return SlotData(
      id: json['_id'],
      attraction_id: json['attraction_id'],
      label: json['label'],
      ticket_capacity: json['ticket_capacity'],
      hide_time: json['hide_time']
    );
  }
}

class AttractionList extends StatefulWidget {
  const AttractionList({ Key? key }) : super(key: key);

  @override
  State<AttractionList> createState() => _AttractionListState();
}

class DataRequiredForBuild {
  List<AttractionData> attractions;
  Map<String, SlotData> slots;

  DataRequiredForBuild({
    required this.attractions,
    required this.slots,
  });
}

class _AttractionListState extends State<AttractionList> {
  late Future <DataRequiredForBuild> futureData;

  @override
  void initState() {
    super.initState();
    futureData = _fetchDataForBuild();
  }

  Future<DataRequiredForBuild> _fetchDataForBuild() async {
    return DataRequiredForBuild(
      attractions: await fetchAttractionData(),
      slots: await fetchSlotData(),
    );
  }

  Future <List<AttractionData>> fetchAttractionData() async {
    final response =
    await http.get(Uri.parse(AppConstants.API_URL + '/attractions'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<AttractionData> map = data["data"].map((data) =>
          AttractionData.fromJson(data)
        ).toList().cast<AttractionData>();
      return map;
    } else {
      throw Exception('Unexpected error occured!');
    }
  }

  Future <Map<String, SlotData>> fetchSlotData() async {
    final response =
    await http.get(Uri.parse(AppConstants.API_URL + '/slots'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<SlotData> list = data["data"].map((data) =>
        (
          SlotData.fromJson(data)
        )
      ).toList().cast<SlotData>();
      Map<String, SlotData> map = Map<String, SlotData>.fromIterable(list, key: (e) => e.attraction_id, value: (e) => e);
      return map;
    } else {
      throw Exception('Unexpected error occured [Slots]!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder <DataRequiredForBuild>(
      future: futureData,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          List<AttractionData>? attractionList = snapshot.data!.attractions;
          List<AttractionData> filteredData = attractionList.where((i) => i.hidden == false).toList();

          Map<String, SlotData>? slotMap = snapshot.data!.slots;
          return
            ListView.builder(
                itemCount: filteredData.length,
                itemBuilder: (BuildContext context, int index) {
                  AttractionData attraction = filteredData[index];
                  DateTime startDate = DateTime.parse(attraction.start_time);
                  DateTime endDate = DateTime.parse(attraction.end_time);
                  String startTimeString = Strings.displayDate(startDate);
                  String endTimeString = Strings.displayDate(endDate);

                  bool hasSlots = slotMap.containsKey(attraction.id);
                  int ticketCap = hasSlots ? slotMap[attraction.id]!.ticket_capacity : 0;
                  return Card(
                    color: AppConstants.COLOR_CEDARVILLE_BLUE,
                    child:
                      InkWell(
                          onTap: () {
                            _displayDialog(context, attraction);
                          },
                        child: Container(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                /*CachedNetworkImage(
                                  placeholder: (context, url) => const CircularProgressIndicator(),
                                  imageUrl: attraction.image_url,
                                ),*/
                                Image.network(attraction.image_url),
                                Container(
                                  margin: const EdgeInsets.all(5),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children:[
                                            Text(
                                              attraction.name,
                                              textAlign: TextAlign.left,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                                            ),
                                            Visibility(
                                                visible: hasSlots,
                                                child: Icon(Icons.local_activity, color: Colors.white,)
                                            )
                                          ]
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        attraction.description,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      //Slot Tickets
                                      Visibility(
                                          visible: hasSlots,
                                          child: Row(
                                            children: [
                                              Icon(Icons.local_activity, color: Colors.white),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              Text("?", style: const TextStyle(color: Colors.white)),
                                              Text(" / ", style: const TextStyle(color: Colors.white)),
                                              Text('${ticketCap}', style: const TextStyle(color: Colors.white)),
                                            ],
                                          )
                                      ),
                                      //Time Info Row
                                      Container(
                                          child: Row(
                                            children: [
                                              Icon(Icons.schedule, color: Colors.white),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              Text(startTimeString, style: const TextStyle(color: Colors.white)),
                                              Text(" - ", style: const TextStyle(color: Colors.white)),
                                              Text(endTimeString, style: const TextStyle(color: Colors.white)),
                                            ],
                                          )
                                      ),
                                      //Location Info
                                      Visibility(
                                          visible: attraction.location != "N/A",
                                          child: Row(
                                            children: [
                                              Icon(Icons.place, color: Colors.white),
                                              SizedBox(
                                                width: 2,
                                              ),
                                              Text(attraction.location, style: const TextStyle(color: Colors.white))
                                            ],
                                          )
                                      )
                                    ],
                                  )
                                )

                              ],
                            ),
                        )
                      )
                  );
                }
            );
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        // By default show a loading spinner.
        return CircularProgressIndicator();
      },
    );
  }

  _displayDialog(BuildContext context, AttractionData attraction) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
            children:[
              Image.network(attraction.image_url),
              Text(attraction.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              Text(attraction.description)
            ],
            elevation: 10,
            //backgroundColor: Colors.green,
          );
      },
    );
  }
}