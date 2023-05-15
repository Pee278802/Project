import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:route_planner/constants/places.dart';
import 'package:route_planner/helpers/commons.dart';
import 'package:route_planner/helpers/shared_prefs.dart';
import 'package:route_planner/widgets/carousel_card.dart';

class placesMap extends StatefulWidget {
  final int selectedIndex;

  const placesMap({Key? key, required this.selectedIndex}) : super(key: key);

  @override
  State<placesMap> createState() => _placesMapState();
}

class _placesMapState extends State<placesMap> {
  // Mapbox related
  LatLng latLng = getLatLngFromSharedPrefs();
  late CameraPosition _initialCameraPosition;
  late MapboxMapController controller;
  late List<CameraPosition> _kplaceList;

  List<Map> carouselData = [];

  // Carousel related
  int pageIndex = 0;
  late List<Widget> carouselItems;

  @override
  void initState() {
    super.initState();
    _initialCameraPosition = CameraPosition(
      target: getLatLngFromplaceData(widget.selectedIndex),
      zoom: 15,
    );

    // Calculate the distance and time from data in SharedPreferences
    for (int index = 0; index < places.length; index++) {
      num distance = getDistanceFromSharedPrefs(index) / 1000;
      num duration = getDurationFromSharedPrefs(index) / 60;
      carouselData
          .add({'index': index, 'distance': distance, 'duration': duration});
    }
    // carouselData.sort((a, b) => a['duration'] < b['duration'] ? 0 : 1);

    // Generate the list of carousel widgets
    carouselItems = List<Widget>.generate(
        places.length,
        (index) => carouselCard(carouselData[index]['index'],
            carouselData[index]['distance'], carouselData[index]['duration']));

    // initialize map symbols in the same order as carousel widgets
    _kplaceList = List<CameraPosition>.generate(
        places.length,
        (index) => CameraPosition(
            target: getLatLngFromplaceData(carouselData[index]['index']),
            zoom: 15));
  }

  _addSourceAndLineLayer(int index, bool removeLayer) async {
    // Can animate camera to focus on the item
    controller
        .animateCamera(CameraUpdate.newCameraPosition(_kplaceList[index]));

    // Add a polyLine between source and destination
    Map geometry = getGeometryFromSharedPrefs(carouselData[index]['index']);
    final _fills = {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "id": 0,
          "properties": <String, dynamic>{},
          "geometry": geometry,
        },
      ]
    };

    // Remove lineLayer and source if it exists
    if (removeLayer == true) {
      await controller.removeLayer("lines");
      await controller.removeSource("fills");
    }
    // Add new source and lineLayer
    await controller.addSource("fills", GeojsonSourceProperties(data: _fills));
    await controller.addLineLayer(
        "fills",
        "lines",
        LineLayerProperties(
            lineColor: Colors.green.toHexStringRGB(),
            lineCap: "round",
            lineJoin: "round",
            lineWidth: 2));
  }

  _onMapCreated(MapboxMapController controller) async {
    this.controller = controller;
  }

  _onStyleLoadedCallback() async {
    for (CameraPosition _kplace in _kplaceList) {
      await controller.addSymbol(SymbolOptions(
          geometry: _kplace.target,
          iconSize: 0.10,
          iconImage: "assets/icon/dkg.png"));
    }
    _addSourceAndLineLayer(0, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ROUTE PLANNER UUM'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: MapboxMap(
                accessToken: dotenv.env['MAPBOX_ACCESS_TOKEN'],
                initialCameraPosition: _initialCameraPosition,
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: _onStyleLoadedCallback,
                myLocationEnabled: true,
                myLocationTrackingMode: MyLocationTrackingMode.TrackingGPS,
                minMaxZoomPreference: const MinMaxZoomPreference(14, 17),
              ),
            ),
            CarouselSlider(
                items: carouselItems,
                options: CarouselOptions(
                    height: 100,
                    viewportFraction: 0.6,
                    initialPage: 0,
                    enableInfiniteScroll: false,
                    scrollDirection: Axis.horizontal,
                    onPageChanged:
                        (int index, CarouselPageChangedReason reason) {
                      setState(() {
                        pageIndex = index;
                      });
                      _addSourceAndLineLayer(index, true);
                    })),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.animateCamera(
              CameraUpdate.newCameraPosition(_initialCameraPosition));
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}




// If later the route cannot be displayed properly, 
// KINDLY CHANGE THE COORDINATE OF THE place!!
