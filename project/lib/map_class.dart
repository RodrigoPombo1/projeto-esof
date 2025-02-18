import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapClass extends StatefulWidget {
  @override
  _MapState createState() => _MapState();
}

enum BinType {
  Black,
  Green,
  Yellow,
  Blue,
}

class StructMarkerItem {
  final String id; // needed to keep track of the bin that was selected in the search page
  final BinType bintype;
  final double latitude;
  final double longitude;
  final int distance;
  final bool is_favorite;

  StructMarkerItem(this.id, this.bintype, this.latitude, this.longitude, this.distance, this.is_favorite);
}


class _MapState extends State<MapClass> {
  final database = FirebaseDatabase.instance.ref();
  String user_id = FirebaseAuth.instance.currentUser!.uid!;

  // Variables to store the toggle state of each type of bin
  bool displayBlackBins = true;
  bool displayGreenBins = true;
  bool displayYellowBins = true;
  bool displayBlueBins = true;

  bool activated_display_black_bins_button = false;
  bool activated_display_green_bins_button = false;
  bool activated_display_yellow_bins_button = false;
  bool activated_display_blue_bins_button = false;

  List<StructMarkerItem> searchResults = [];
  // List<StructMarkerItem> searchResults = [
  //   new StructMarkerItem(1, BinType.Black, 41.173000, -8.599700, 20, 10, 2, false, true, false),
  //   new StructMarkerItem(2, BinType.Green, 41.165000, -8.599700, 30, 5, 1, true, true, false),
  //   new StructMarkerItem(3, BinType.Yellow, 41.178000, -8.586700, 40, 3, 0, false, false, false),
  //   new StructMarkerItem(4, BinType.Blue, 41.172000, -8.594700, 50, 1, 0, false, false, false),
  //   new StructMarkerItem(5, BinType.Black, 41.177000, -8.569700, 70, 15, 7, false, false, true),
  //   new StructMarkerItem(6, BinType.Green, 41.171000, -8.596700, 80, 20, 5, false, false, false),
  //   new StructMarkerItem(7, BinType.Yellow, 41.172000, -8.597700, 90, 25, 3, false, true, false),
  //   new StructMarkerItem(8, BinType.Blue, 41.173000, -8.599200, 100, 30, 2, false, false, false),
  //   new StructMarkerItem(9, BinType.Black, 41.174000, -8.593700, 120, 35, 10, false, false, false),
  //   new StructMarkerItem(10, BinType.Green, 41.175000, -8.594700, 130, 40, 8, false, false, false),
  //   new StructMarkerItem(11, BinType.Yellow, 41.176000, -8.598700, 140, 45, 5, false, true, false),
  //   new StructMarkerItem(12, BinType.Black, 41.177000, -8.591700, 150, 50, 3, false, false, false),
  //   new StructMarkerItem(13, BinType.Black, 41.178000, -8.559700, 170, 55, 15, false, false, true),
  //   new StructMarkerItem(14, BinType.Blue, 41.179000, -8.569700, 180, 60, 12, false, false, false),
  //   new StructMarkerItem(15, BinType.Green, 41.174000, -8.579700, 190, 65, 10, false, false, false),
  //   // Add search results here
  // ];


  // LocationPermission permission = await Geolocator.checkPermission();
  // if (permission == LocationPermission.denied) {
  //   permission = await Geolocator.requestPermission();
  // }

  // Future<Stream<LocationMarkerPosition>> _initPositionStream() async {
  //   bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   while (!serviceEnabled) {
  //     // Force them to enable location services
  //     serviceEnabled = await Geolocator.openLocationSettings();
  //     serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   }
  //
  //   LocationPermission permission = await Geolocator.checkPermission();
  //   while(permission != LocationPermission.always &&
  //         permission != LocationPermission.whileInUse) {
  //     // Request permission to access the device's location
  //     permission = await Geolocator.requestPermission();
  //   }
  //   // Get a stream of the device's location
  //   Stream<LocationMarkerPosition?> aux = const LocationMarkerDataStreamFactory()
  //       .fromGeolocatorPositionStream(
  //     stream: Geolocator.getPositionStream(
  //       locationSettings: const LocationSettings(
  //         accuracy: LocationAccuracy.best,
  //         distanceFilter: 5,
  //       ),
  //     ),
  //   );
  //   // _positionStream = await aux.map((e) => e!); // _positionStream = await aux.where((element) => element != null).map((e) => e!);
  //   return aux.map((e) => e!);
  // }

  double initial_latitude = 0;
  double initial_longitude = 0;

  Future<void> _initSearchResults() async {
    searchResults = [];
    final snapshot = await database.child('/bins_coordinates/').get();
    final data = snapshot.value as Map<dynamic, dynamic>;
    data.forEach((key, value) {
      int distance = Geolocator.distanceBetween(initial_latitude, initial_longitude, value['latitude'], value['longitude']).toInt();
      searchResults.add(StructMarkerItem(key, value['type'] == 'black' ? BinType.Black : value['type'] == 'green' ? BinType.Green : value['type'] == 'yellow' ? BinType.Yellow : BinType.Blue, value['latitude'], value['longitude'], distance, false));
    });
  }

  Future<Stream<Position>> _initPositionStream() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    while (!serviceEnabled) {
      // Force them to enable location services
      serviceEnabled = await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    while (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      // Request permission to access the device's location
      permission = await Geolocator.requestPermission();
    }
    // Get a stream of the device's location
    Stream<Position?> aux = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    );
    // _positionStream = await aux.map((e) => e!); // _positionStream = await aux.where((element) => element != null).map((e) => e!);
    Position aux_position = await Geolocator.getCurrentPosition();
    initial_latitude = aux_position.latitude;
    initial_longitude = aux_position.longitude;

    // [TODO] get the bin positions and which bins are favorites
    await _initSearchResults();

    return aux.map((e) => e!);
  }

  final MapController customMapController = MapController();

  Marker getMarkerWhereIdMatch(List<Marker> markers) {
    Marker marker_result = Marker(point: LatLng(0, 0), width: 0, height: 0, child: Container());
    for (int i = 0; i < markers.length; i++) {
      if (markers[i].point.latitude == searchResults.firstWhere((element) => element.id == popup_id_to_show_for_popup).latitude && markers[i].point.longitude == searchResults.firstWhere((element) => element.id == popup_id_to_show_for_popup).longitude) {
        marker_result = markers[i];
        break;
      }
    }
    // if (marker_result.point.latitude != 0 && marker_result.point.longitude != 0) {
    //   customMapController.move(LatLng(marker_result.point.latitude, marker_result.point.longitude), 16.0);
    // }
    popup_id_to_show_for_popup = "";
    return marker_result;
  }

  List<Marker> markerBuilder() {
    return <Marker>[
      for (var item in searchResults)
        if ((item.bintype == BinType.Black &&
            displayBlackBins) ||
            (item.bintype == BinType.Green &&
                displayGreenBins) ||
            (item.bintype == BinType.Yellow &&
                displayYellowBins) ||
            (item.bintype == BinType.Blue && displayBlueBins))
          Marker(
            point: LatLng(item.latitude, item.longitude),
            width: 40,
            height: 40,
            child: Stack(
              children: [
                Positioned(
                  child: Icon(
                    Icons.delete,
                    size: 40,
                    color: item.is_favorite
                        ? Colors.amber[700]
                        : Colors.black,
                  ),
                ),
                Positioned(
                  top: 2.5,
                  left: 2.5,
                  child: Icon(
                    Icons.delete,
                    size: 35,
                    color: item.bintype == BinType.Black
                        ? Colors.black
                        : item.bintype == BinType.Green
                        ? Colors.green
                        : item.bintype == BinType.Yellow
                        ? Colors.yellow
                        : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
    ];
  }
  final PopupController _popupLayerController = PopupController();

  Map data = {};
  late String popup_id_to_show_for_popup;
  late String popup_id_to_show_for_map;

  void _openMaps(double latitude, double longitude) async {
    final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude');

    // check google maps is installed
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // error message: google maps is not installed
      throw 'Could not launch $url';
    }
  }

  bool is_first_time_building = true;

  @override
  Widget build(BuildContext context) {

    if (is_first_time_building) {
      try {
        data = ModalRoute
            .of(context)!
            .settings
            .arguments as Map;
        popup_id_to_show_for_popup = data['bin_id'];
        popup_id_to_show_for_map = data['bin_id'];
      } catch (e) {
        popup_id_to_show_for_popup = "";
        popup_id_to_show_for_map = "";
      }
    }
    is_first_time_building = false;

    return Scaffold(
      /////////
      // BODY
      /////////
      body: FutureBuilder(
        future: _initPositionStream(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (!snapshot.hasData) {
              return Center(
                child: Text("Couldn't get access to the device's location. Please enable location services and try again.", textAlign: TextAlign.center, style: TextStyle(color: Colors.red)),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            List<Marker> markers = markerBuilder();
            return FlutterMap(
              mapController: customMapController,
              options: MapOptions(
                initialCenter: LatLng(initial_latitude, initial_longitude),
                initialZoom: 16.0,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (_, __) => _popupLayerController.hideAllPopups(),
                onMapReady: () {
                  if (popup_id_to_show_for_map != "") {
                    customMapController.move(LatLng(searchResults.firstWhere((element) => element.id == popup_id_to_show_for_map).latitude, searchResults.firstWhere((element) => element.id == popup_id_to_show_for_map).longitude), 16.0);
                    popup_id_to_show_for_map = "";
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'BinFinder',
                ),
                CurrentLocationLayer(
                  positionStream: LocationMarkerDataStreamFactory()
                      .fromGeolocatorPositionStream(stream: snapshot.data),
                  alignPositionOnUpdate: AlignOnUpdate.never,
                  alignDirectionOnUpdate: AlignOnUpdate.never,
                  style: LocationMarkerStyle(
                    marker: const DefaultLocationMarker(
                      color: Colors.green,
                    ),
                    accuracyCircleColor: Colors.green.withOpacity(0.1),
                    headingSectorColor: Colors.green.withOpacity(0.8),
                    markerSize: const Size(20, 20),
                    markerDirection: MarkerDirection.heading,
                  ),
                ),
                PopupMarkerLayer(
                  options: PopupMarkerLayerOptions(
                    markers: markers,
                    popupController: _popupLayerController,
                    popupDisplayOptions: PopupDisplayOptions(
                      builder: (_, Marker marker) {
                        final StructMarkerItem item = searchResults.firstWhere(
                              (element) =>
                          element.latitude == marker.point.latitude &&
                              element.longitude == marker.point.longitude,
                        );
                        return Container(
                          width: 4 / 9 * MediaQuery
                              .of(context)
                              .size
                              .width,
                          height: 3 / 11 * MediaQuery
                              .of(context)
                              .size
                              .height,
                          child: Card(
                            margin: EdgeInsets.all(0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete,
                                  color: item.bintype == BinType.Black
                                      ? Colors.black
                                      : item.bintype == BinType.Green
                                      ? Colors.green
                                      : item.bintype == BinType.Yellow
                                      ? Colors.yellow
                                      : Colors.blue,
                                ),
                                Text('Distance: ${item.distance}m'),
                                ElevatedButton(
                                  child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceEvenly,
                                      children: [
                                        Icon(Icons.directions),
                                        Text('Directions')
                                      ]
                                  ),
                                  onPressed: () {
                                    _openMaps(item.latitude, item.longitude);
                                  },
                                ),
                                ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all<
                                        Color>(item.is_favorite
                                        ? Colors.amber[700]!
                                        : Colors.white),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceEvenly,
                                    children: [
                                      Icon(Icons.star, color: item.is_favorite
                                          ? Colors.white
                                          : Colors.amber[700]),
                                      Text('Favorites', style: TextStyle(
                                          color: item.is_favorite
                                              ? Colors.white
                                              : Colors.amber[700])),
                                    ],
                                  ),
                                  onPressed: () {
                                    // [TODO] add or remove the bin to/from the favorites
                                    // [TODO] and set this popup to be opened in the map the next time the map loads in
                                  },
                                ),
                                StreamBuilder(
                                  stream: database.child('bins_votes').child(item.id).onValue,
                                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.active) {
                                      final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value);
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .spaceEvenly,
                                        children: [
                                          Expanded(
                                            child: MaterialButton(
                                              color: (data['user_votes']?[user_id]?? null) == 1
                                                  ? Colors.green
                                                  : Colors.white,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .spaceEvenly,
                                                children: [
                                                  Icon(Icons.thumb_up,
                                                      color: (data['user_votes']?[user_id]?? null) == 1
                                                          ? Colors
                                                          .white
                                                          : Colors.green),
                                                  Text('${data['likes']}',
                                                      style: TextStyle(
                                                          color: (data['user_votes']?[user_id]?? null) == 1
                                                              ? Colors.white
                                                              : Colors.green)),
                                                ],
                                              ),
                                              onPressed: () async {
                                                // showDialog(
                                                //   context:context,
                                                //   barrierDismissible: false,
                                                //   builder: (context) => Center(
                                                //     child: CircularProgressIndicator(
                                                //       valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                                //     ),
                                                //   ),
                                                // );
                                                String bin_type_string = item.bintype == BinType.Black ? 'black_bins' : item.bintype == BinType.Green ? 'green_bins' : item.bintype == BinType.Yellow ? 'yellow_bins' : 'blue_bins';
                                                int? user_vote = data['user_votes']?[user_id]?? null;
                                                // caso em que user não tinha like nem dislike
                                                if (user_vote == null) {
                                                  await database.update({
                                                    '/users_info/${user_id}/${bin_type_string}/liked': ServerValue
                                                        .increment(1),
                                                    '/bins_votes/${item
                                                        .id}/likes': ServerValue
                                                        .increment(1),
                                                    '/bins_votes/${item
                                                        .id}/user_votes/${user_id}': 1,
                                                  });
                                                };
                                                // caso em que user tinha like
                                                if (user_vote == 1) {
                                                  await database.update({
                                                    '/users_info/${user_id}/${bin_type_string}/liked': ServerValue
                                                        .increment(-1),
                                                    '/bins_votes/${item
                                                        .id}/likes': ServerValue
                                                        .increment(-1),
                                                    '/bins_votes/${item
                                                        .id}/user_votes/${user_id}': null,
                                                  });
                                                };
                                                // caso em que user tinha dislike
                                                if (user_vote == 0) {
                                                  await database.update({
                                                    '/users_info/${user_id}/${bin_type_string}/liked': ServerValue
                                                        .increment(1),
                                                    '/users_info/${user_id}/${bin_type_string}/disliked': ServerValue
                                                        .increment(-1),
                                                    '/bins_votes/${item
                                                        .id}/likes': ServerValue
                                                        .increment(1),
                                                    '/bins_votes/${item
                                                        .id}/dislikes': ServerValue
                                                        .increment(-1),
                                                    '/bins_votes/${item
                                                        .id}/user_votes/${user_id}': 1,
                                                  });
                                                };
                                                // Navigator.of(context).pop();
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            child: MaterialButton(
                                              color: (data['user_votes']?[user_id]?? null) == 0
                                                  ? Colors.red
                                                  : Colors.white,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .spaceEvenly,
                                                children: [
                                                  Icon(Icons.thumb_down,
                                                      color: (data['user_votes']?[user_id]?? null) == 0
                                                          ? Colors
                                                          .white
                                                          : Colors.red),
                                                  Text('${data['dislikes']}',
                                                      style: TextStyle(
                                                          color: (data['user_votes']?[user_id]?? null) == 0
                                                              ? Colors.white
                                                              : Colors.red)),
                                                ],
                                              ),
                                              onPressed: () async {
                                                // showDialog(
                                                //   context:context,
                                                //   barrierDismissible: false,
                                                //   builder: (context) => Center(
                                                //     child: CircularProgressIndicator(
                                                //       valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                                //     ),
                                                //   ),
                                                // );
                                                String bin_type_string = item.bintype == BinType.Black ? 'black_bins' : item.bintype == BinType.Green ? 'green_bins' : item.bintype == BinType.Yellow ? 'yellow_bins' : 'blue_bins';
                                                int? user_vote = data['user_votes']?[user_id]?? null;
                                                // caso em que user não tinha like nem dislike
                                                if (user_vote == null) {
                                                  await database.update({
                                                    '/users_info/${user_id}/${bin_type_string}/disliked': ServerValue
                                                        .increment(1),
                                                    '/bins_votes/${item
                                                        .id}/dislikes': ServerValue
                                                        .increment(1),
                                                    '/bins_votes/${item
                                                        .id}/user_votes/${user_id}': 0,
                                                  });
                                                };
                                                // caso em que user tinha dislike
                                                if (user_vote == 0) {
                                                  await database.update({
                                                    '/users_info/${user_id}/${bin_type_string}/dislikes': ServerValue
                                                        .increment(-1),
                                                    '/bins_votes/${item
                                                        .id}/dislikes': ServerValue
                                                        .increment(-1),
                                                    '/bins_votes/${item
                                                        .id}/user_votes/${user_id}': null,
                                                  });
                                                };
                                                // caso em que user tinha like
                                                if (user_vote == 1) {
                                                  await database.update({
                                                    '/users_info/${user_id}/${bin_type_string}/disliked': ServerValue
                                                        .increment(1),
                                                    '/users_info/${user_id}/${bin_type_string}/liked': ServerValue
                                                        .increment(-1),
                                                    '/bins_votes/${item
                                                        .id}/dislikes': ServerValue
                                                        .increment(1),
                                                    '/bins_votes/${item
                                                        .id}/likes': ServerValue
                                                        .increment(-1),
                                                    '/bins_votes/${item
                                                        .id}/user_votes/${user_id}': 0,
                                                  });
                                                };
                                                // Navigator.of(context).pop();
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    else {
                                      return Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<
                                              Color>(Colors.green),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    markerCenterAnimation: MarkerCenterAnimation(
                      curve: Curves.ease,
                      duration: const Duration(milliseconds: 500),
                    ),
                    initiallySelected: <PopupSpec>[
                      if (popup_id_to_show_for_popup != "")
                        PopupSpec(marker: getMarkerWhereIdMatch(markers)),
                    ],
                  ),
                ),
              ],
            );
          }
          else {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            );
          };
        },
      ),

      ///////////
      // FLOATING ACTION BUTTON
      ///////////
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 56,
                height: 56,
              ),
              SizedBox(
                width: 56,
                height: 56,
              ),
              SizedBox(
                width: 56,
                height: 56,
              ),
              FloatingActionButton(
                onPressed: () async {
                  Position current_position = await Geolocator.getCurrentPosition();
                  customMapController.move(LatLng(current_position.latitude, current_position.longitude), 16.0);
                },
                child: Icon(Icons.gps_fixed),
                backgroundColor: Colors.white,
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.width * 1 / 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 56,
                height: 56,
              ),
              SizedBox(
                width: 56,
                height: 56,
              ),
              SizedBox(
                width: 56,
                height: 56,
              ),
              FloatingActionButton(
                onPressed: () {
                  // open dialog box with the 4 bin types so the person choses one
                  AlertDialog alert = AlertDialog(
                    title: Text("Choose the bin type"),
                    content: Table(
                      children: [
                        TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: FloatingActionButton(
                                    backgroundColor: Colors.white,
                                    onPressed: () async {
                                      showDialog(
                                        context:context,
                                        barrierDismissible: false,
                                        builder: (context) => Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                          ),
                                        ),
                                      );

                                      var binsCoordinatesRef = database.child('bins_coordinates').push();
                                      var key = binsCoordinatesRef.key!;
                                      await database.update({
                                        '/users_info/${user_id}/black_bins/added': ServerValue.increment(1),
                                        '/bins_coordinates/${key}': {
                                          'latitude': await Geolocator.getCurrentPosition().then((value) => value.latitude),
                                          'longitude': await Geolocator.getCurrentPosition().then((value) => value.longitude),
                                          'type': 'black',
                                        },
                                        '/bins_votes/${key}': {
                                          'likes': 0,
                                          'dislikes': 0,
                                        },
                                      });

                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                      setState(() {});
                                    },
                                    child: Icon(Icons.delete, color: Colors.black, size: 36),
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: FloatingActionButton(
                                    backgroundColor: Colors.white,
                                    onPressed: () async {
                                      showDialog(
                                        context:context,
                                        barrierDismissible: false,
                                        builder: (context) => Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                          ),
                                        ),
                                      );
                                      var binsCoordinatesRef = database.child('bins_coordinates').push();
                                      var key = binsCoordinatesRef.key!;
                                      await database.update({
                                        '/users_info/${user_id}/green_bins/added': ServerValue.increment(1),
                                        '/bins_coordinates/${key}': {
                                          'latitude': await Geolocator.getCurrentPosition().then((value) => value.latitude),
                                          'longitude': await Geolocator.getCurrentPosition().then((value) => value.longitude),
                                          'type': 'green',
                                        },
                                        '/bins_votes/${key}': {
                                          'likes': 0,
                                          'dislikes': 0,
                                        },
                                      });
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                      setState(() {});
                                    },
                                    child: Icon(Icons.delete, color: Colors.green, size: 36),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: FloatingActionButton(
                                    backgroundColor: Colors.white,
                                    onPressed: () async {
                                      showDialog(
                                        context:context,
                                        barrierDismissible: false,
                                        builder: (context) => Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                          ),
                                        ),
                                      );
                                      var binsCoordinatesRef = database.child('bins_coordinates').push();
                                      var key = binsCoordinatesRef.key!;
                                      await database.update({
                                        '/users_info/${user_id}/yellow_bins/added': ServerValue.increment(1),
                                        '/bins_coordinates/${key}': {
                                          'latitude': await Geolocator.getCurrentPosition().then((value) => value.latitude),
                                          'longitude': await Geolocator.getCurrentPosition().then((value) => value.longitude),
                                          'type': 'yellow',
                                        },
                                        '/bins_votes/${key}': {
                                          'likes': 0,
                                          'dislikes': 0,
                                        },
                                      });
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                      setState(() {});
                                    },
                                    child: Icon(Icons.delete, color: Colors.yellow, size: 36),
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: FloatingActionButton(
                                    backgroundColor: Colors.white,
                                    onPressed: () async {
                                      showDialog(
                                        context:context,
                                        barrierDismissible: false,
                                        builder: (context) => Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                          ),
                                        ),
                                      );

                                      var binsCoordinatesRef = database.child('bins_coordinates').push();
                                      var key = binsCoordinatesRef.key!;
                                      await database.update({
                                        '/users_info/${user_id}/blue_bins/added': ServerValue.increment(1),
                                        '/bins_coordinates/${key}': {
                                          'latitude': await Geolocator.getCurrentPosition().then((value) => value.latitude),
                                          'longitude': await Geolocator.getCurrentPosition().then((value) => value.longitude),
                                          'type': 'blue',
                                        },
                                        '/bins_votes/${key}': {
                                          'likes': 0,
                                          'dislikes': 0,
                                        },
                                      });
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                      setState(() {});
                                    },
                                    child: Icon(Icons.delete, color: Colors.blue, size: 36),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  );
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return alert;
                    },
                  );
                },
                child: Icon(Icons.add),
                backgroundColor: Colors.white,
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.width * 1 / 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    activated_display_black_bins_button = !activated_display_black_bins_button;
                    // case where this is the only one that is activated
                    if (activated_display_black_bins_button && !activated_display_green_bins_button && !activated_display_yellow_bins_button && !activated_display_blue_bins_button) {
                      displayBlackBins = true;
                      displayGreenBins = false;
                      displayYellowBins = false;
                      displayBlueBins = false;
                    }
                    else if (activated_display_black_bins_button) {
                      displayBlackBins = true;
                    }
                    else { // case where activated_display_black_bins_button is false
                      displayBlackBins = false;
                    }
                    // case where all the buttons are deactivated
                    if (!activated_display_black_bins_button && !activated_display_green_bins_button && !activated_display_yellow_bins_button && !activated_display_blue_bins_button) {
                      displayBlackBins = true;
                      displayGreenBins = true;
                      displayYellowBins = true;
                      displayBlueBins = true;
                    }
                  });
                },
                child: Icon(Icons.delete, color: !activated_display_black_bins_button ? Colors.black : Colors.white),
                backgroundColor: !activated_display_black_bins_button ? Colors.white : Colors.black,
              ),
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    activated_display_green_bins_button = !activated_display_green_bins_button;
                    // case where this is the only one that is activated
                    if (!activated_display_black_bins_button && activated_display_green_bins_button && !activated_display_yellow_bins_button && !activated_display_blue_bins_button) {
                      displayBlackBins = false;
                      displayGreenBins = true;
                      displayYellowBins = false;
                      displayBlueBins = false;
                    }
                    else if (activated_display_green_bins_button) {
                      displayGreenBins = true;
                    }
                    else { // case where activated_display_green_bins_button is false
                      displayGreenBins = false;
                    }
                    // case where all the buttons are deactivated
                    if (!activated_display_black_bins_button && !activated_display_green_bins_button && !activated_display_yellow_bins_button && !activated_display_blue_bins_button) {
                      displayBlackBins = true;
                      displayGreenBins = true;
                      displayYellowBins = true;
                      displayBlueBins = true;
                    }
                  });
                },
                child: Icon(Icons.delete, color: !activated_display_green_bins_button ? Colors.green : Colors.white),
                backgroundColor: !activated_display_green_bins_button ? Colors.white : Colors.green,
              ),
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    activated_display_yellow_bins_button = !activated_display_yellow_bins_button;
                    // case where this is the only one that is activated
                    if (!activated_display_black_bins_button && !activated_display_green_bins_button && activated_display_yellow_bins_button && !activated_display_blue_bins_button) {
                      displayBlackBins = false;
                      displayGreenBins = false;
                      displayYellowBins = true;
                      displayBlueBins = false;
                    }
                    else if (activated_display_yellow_bins_button) {
                      displayYellowBins = true;
                    }
                    else { // case where activated_display_yellow_bins_button is false
                      displayYellowBins = false;
                    }
                    // case where all the buttons are deactivated
                    if (!activated_display_black_bins_button && !activated_display_green_bins_button && !activated_display_yellow_bins_button && !activated_display_blue_bins_button) {
                      displayBlackBins = true;
                      displayGreenBins = true;
                      displayYellowBins = true;
                      displayBlueBins = true;
                    }
                  });
                },
                child: Icon(Icons.delete, color: !activated_display_yellow_bins_button ? Colors.yellow : Colors.white),
                backgroundColor: !activated_display_yellow_bins_button ? Colors.white : Colors.yellow,
              ),
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    activated_display_blue_bins_button = !activated_display_blue_bins_button;
                    // case where this is the only one that is activated
                    if (!activated_display_black_bins_button && !activated_display_green_bins_button && !activated_display_yellow_bins_button && activated_display_blue_bins_button) {
                      displayBlackBins = false;
                      displayGreenBins = false;
                      displayYellowBins = false;
                      displayBlueBins = true;
                    }
                    else if (activated_display_blue_bins_button) {
                      displayBlueBins = true;
                    }
                    else { // case where activated_display_blue_bins_button is false
                      displayBlueBins = false;
                    }
                    // case where all the buttons are deactivated
                    if (!activated_display_black_bins_button && !activated_display_green_bins_button && !activated_display_yellow_bins_button && !activated_display_blue_bins_button) {
                      displayBlackBins = true;
                      displayGreenBins = true;
                      displayYellowBins = true;
                      displayBlueBins = true;
                    }
                  });
                },
                child: Icon(Icons.delete, color: !activated_display_blue_bins_button ? Colors.blue : Colors.white),
                backgroundColor: !activated_display_blue_bins_button ? Colors.white : Colors.blue,
              ),
            ],
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      ////////
      // BOTTOM NAVIGATION BAR
      ////////
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
            backgroundColor: Color(0xFF81C784),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
            backgroundColor: Color(0xFF81C784),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'List',
            backgroundColor: Color(0xFF81C784),
          ),
        ],
        currentIndex: 1,
        selectedItemColor: Colors.white,
        onTap: (int index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/profile');
          } else if (index == 1) {
            // do nothing, already on the map screen
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/search');
          }
        },
      ),
    );
  }
}
