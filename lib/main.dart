import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' as Math;

import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as toolkit;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

enum mapMode {
  point,
  continu,
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Free Hand Polygon Drawing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class RadioButton extends StatefulWidget {
  final Function(mapMode) onButtonSelected;
  const RadioButton({Key? key, required this.onButtonSelected})
      : super(key: key);

  @override
  State<RadioButton> createState() => _RadioButtonState();
}

class _RadioButtonState extends State<RadioButton> {
  bool mode = false;
  var radioTileValue;
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          Expanded(
            child: RadioListTile(
                subtitle: const Text('continues'),
                value: mapMode.continu,
                groupValue: radioTileValue,
                onChanged: (check) {
                  setState(() {
                    radioTileValue = check;
                    if (check != null) {
                      widget.onButtonSelected(mapMode.continu);
                    }
                  });
                }),
          ),
          Expanded(
            child: RadioListTile(
                subtitle: const Text('point to point'),
                value: mapMode.point,
                groupValue: radioTileValue,
                onChanged: (check) {
                  setState(() {
                    radioTileValue = check;
                    if (check != null) {
                      widget.onButtonSelected(mapMode.point);
                    }
                  });
                }),
          ),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  final Set<Polygon> _polygons = HashSet<Polygon>();
  final Set<Polyline> _polyLines = HashSet<Polyline>();

  mapMode? mode;
  bool _drawPolygonEnabled = false;
  List<LatLng> _firstPolyLinesLatLngList = [];
  List<LatLng> _secondPolyLinesLatLngList = [];
  List<toolkit.LatLng> _firstPolyLinesLatLngListForToolkit = [];
  List<toolkit.LatLng> _secondtPolyLinesLatLngListForToolkit = [];
  bool _clearDrawing = false;
  int? _lastXCoordinate, _lastYCoordinate;
  // bool inPolygonDetected = false;
  ValueNotifier<bool> inPolygonDetected = ValueNotifier<bool>(false);
  Location location = new Location();
  String txt = 'disabled';

  String status = 'nothing';
  int i = 0, j = 0, k = 0, l = 0;
  bool firstPolyFinished = false, secondPoyFinished = false;

  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  late LocationData _locationData;

  void _getPermission() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
  }

  @override
  void initState() {
    super.initState();
    _getPermission();
    inPolygonDetected.addListener(() {
      null;
    });
  }

  @override
  Widget build(BuildContext context) {
    location.onLocationChanged.listen((LocationData currentLocation) {
      toolkit.LatLng _userCurrentLoc =
          toolkit.LatLng(currentLocation.latitude!, currentLocation.longitude!);
      // print(currentLocation);
      if (_firstPolyLinesLatLngList.isNotEmpty && secondPoyFinished) {
        inPolygonDetected.value = toolkit.PolygonUtil.containsLocation(
            // toolkit.LatLng(37.43858045026685, -122.09189560264349),
            _userCurrentLoc,
            _firstPolyLinesLatLngListForToolkit,
            false);
        print(inPolygonDetected.value);
        if (inPolygonDetected.value == true) {
          i++;
          j = 0;
          status = 'inside';
          print('inside');
        } else {
          j++;
          i = 0;
          status = 'outside';
          print('outside');
        }
        if (i == 1 || j == 1) {
          ElegantNotification.info(
                  title: Text("Info 1"), description: Text(status))
              .show(context);
        }
      } else {
        status = 'no poly';
        print('no poly');
      }

      if (_secondPolyLinesLatLngList.isNotEmpty && secondPoyFinished) {
        inPolygonDetected.value = toolkit.PolygonUtil.containsLocation(
            // toolkit.LatLng(37.43858045026685, -122.09189560264349),
            _userCurrentLoc,
            _secondtPolyLinesLatLngListForToolkit,
            false);
        print(inPolygonDetected.value);
        if (inPolygonDetected.value == true) {
          k++;
          l = 0;
          status = 'inside';
          print('inside');
        } else {
          l++;
          k = 0;
          status = 'outside';
          print('outside');
        }
        if (k == 1 || l == 1) {
          ElegantNotification.info(
                  title: Text("Info 2"), description: Text(status))
              .show(context);
        }
      } else {
        status = 'no poly';
        print('no poly');
      }
    });
    return Scaffold(
      bottomNavigationBar: RadioButton(
        onButtonSelected: (p0) {
          setState(() {
            mode = p0;
            _clearPolygons();
          });
        },
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (argument) async =>
                (_drawPolygonEnabled == true && mode == mapMode.point)
                    ? _clearDrawing
                        ? _clearPolygons()
                        : await _onTapUpdate(argument)
                    : null,

            behavior: _drawPolygonEnabled
                ? HitTestBehavior.translucent
                : HitTestBehavior.opaque,

            onPanUpdate: (argument) async =>
                (_drawPolygonEnabled == true && mode == mapMode.continu)
                    ? _clearDrawing
                        ? _clearPolygons()
                        : await _onPanUpdate(argument)
                    : null,

            // onPanEnd: (_drawPolygonEnabled) ? _onPanEnd : null,
            child: GoogleMap(
                // tiltGesturesEnabled: true,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                // onTap: (argument) => _onPanUpdate(argument),
                mapType: MapType.normal,
                initialCameraPosition: _kGooglePlex,
                polygons: _polygons,
                polylines: _polyLines,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                gestureRecognizers: _drawPolygonEnabled
                    ? (Set()
                      ..remove(Factory<PanGestureRecognizer>(
                          () => PanGestureRecognizer())))
                    : (Set()
                      ..add(Factory<PanGestureRecognizer>(
                          () => PanGestureRecognizer())))
                // gestureRecognizers:
                //     <Factory<OneSequenceGestureRecognizer>>[
                //         new Factory<OneSequenceGestureRecognizer>(
                //           () =>
                //           new EagerGestureRecognizer(),
                //         ),
                //       ].toSet(),
                ),
          ),
          Positioned(
            top: 475,
            left: 300,
            child: ElevatedButton(
              onPressed: () async {
                await _clearPolygons();
              },
              child: Text('clear'),
            ),
          ),
          Positioned(
            top: 475,
            left: 200,
            child: ElevatedButton(
              onPressed: () async {
                await _onPanEnd();
              },
              child: Text('finish'),
            ),
          ),
          Positioned(
            top: 475,
            left: 100,
            child: ElevatedButton(
              onPressed: () async {
                await _onPanEnd1();
              },
              child: Text('finish1'),
            ),
          ),
          Positioned(
            top: 475,
            child: ElevatedButton(
              onPressed: () {
                _toggleDrawing();
              },
              child: Text('$txt'),
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _onPanEnd,
      //   tooltip: 'Drawing',
      //   child: Icon(
      //       Icons.check), //(_drawPolygonEnabled) ? Icons.check : Icons.edit),
      // ),
    );
  }

  _toggleDrawing() {
    // _clearPolygons();
    setState(() {
      _drawPolygonEnabled = !_drawPolygonEnabled;
      _drawPolygonEnabled ? txt = 'enabled' : txt = 'disabled';
    });
    print(_drawPolygonEnabled);
  }

  _onTapUpdate(TapDownDetails details) async {
    //DragUpdateDetails details

    // To start draw new polygon every time.
    // if (_clearDrawing) {
    //   _clearDrawing = false;
    //   await _clearPolygons();
    // }

    if (_drawPolygonEnabled) {
      double x = 0, y = 0;
      if (Platform.isAndroid) {
        // It times in 3 without any meaning,
        // We think it's an issue with GoogleMaps package.
        x = details.globalPosition.dx * 3;
        y = details.globalPosition.dy * 3;
      } else if (Platform.isIOS) {
        x = details.globalPosition.dx;
        y = details.globalPosition.dy;
      }

      // print(details.latitude);
      // print(details.longitude);

      // Round the x and y.
      int xCoordinate = x.round();
      int yCoordinate = y.round();

      // Check if the distance between last point is not too far.
      // to prevent two fingers drawing.
      // if (_lastXCoordinate != null && _lastYCoordinate != null) {
      //   var distance = Math.sqrt(Math.pow(xCoordinate - _lastXCoordinate!, 2) +
      //       Math.pow(yCoordinate - _lastYCoordinate!, 2));
      //   // Check if the distance of point and point is large.
      //   if (distance > 80.0) return;
      // }

      // Cached the coordinate.
      _lastXCoordinate = xCoordinate;
      _lastYCoordinate = yCoordinate;

      ScreenCoordinate screenCoordinate =
          ScreenCoordinate(x: xCoordinate, y: yCoordinate);
      // print(screenCoordinate);

      final GoogleMapController controller = await _controller.future;
      LatLng latLng = await controller.getLatLng(screenCoordinate);
      toolkit.LatLng latlang1 =
          toolkit.LatLng(latLng.latitude, latLng.longitude);

      print(latLng);

      try {
        // Add new point to list.
        if (!firstPolyFinished && !secondPoyFinished) {
          _firstPolyLinesLatLngListForToolkit.add(latlang1);

          _firstPolyLinesLatLngList.add(latLng);

          _polyLines.removeWhere(
              (polyline) => polyline.polylineId.value == 'user_polyline');
          _polyLines.add(
            Polyline(
              polylineId: PolylineId('user_polyline'),
              points: _firstPolyLinesLatLngList,
              width: 2,
              color: Colors.blue,
            ),
          );
        } else {
          _secondtPolyLinesLatLngListForToolkit.add(latlang1);

          _secondPolyLinesLatLngList.add(latLng);

          _polyLines.removeWhere(
              (polyline) => polyline.polylineId.value == 'user_polyline1');
          _polyLines.add(
            Polyline(
              polylineId: PolylineId('user_polyline1'),
              points: _secondPolyLinesLatLngList,
              width: 2,
              color: Colors.blue,
            ),
          );
        }
      } catch (e) {
        print(" error painting $e");
      }
      setState(() {
        // print(_firstPolyLinesLatLngList);
      });
    }
  }

  _onPanUpdate(DragUpdateDetails details) async {
    // To start draw new polygon every time.
    // if (_clearDrawing) {
    //   _clearDrawing = false;
    //   _clearPolygons();
    // }

    if (_drawPolygonEnabled) {
      double x = 0, y = 0;
      if (Platform.isAndroid) {
        // It times in 3 without any meaning,
        // We think it's an issue with GoogleMaps package.
        x = details.globalPosition.dx * 3;
        y = details.globalPosition.dy * 3;
      } else if (Platform.isIOS) {
        x = details.globalPosition.dx;
        y = details.globalPosition.dy;
      }

      // Round the x and y.
      int xCoordinate = x.round();
      int yCoordinate = y.round();

      // Check if the distance between last point is not too far.
      // to prevent two fingers drawing.
      if (_lastXCoordinate != null && _lastYCoordinate != null) {
        var distance = Math.sqrt(Math.pow(xCoordinate - _lastXCoordinate!, 2) +
            Math.pow(yCoordinate - _lastYCoordinate!, 2));
        // Check if the distance of point and point is large.
        if (distance > 80.0) return;
      }

      // Cached the coordinate.
      _lastXCoordinate = xCoordinate;
      _lastYCoordinate = yCoordinate;

      ScreenCoordinate screenCoordinate =
          ScreenCoordinate(x: xCoordinate, y: yCoordinate);
      // print(screenCoordinate);

      final GoogleMapController controller = await _controller.future;
      LatLng latLng = await controller.getLatLng(screenCoordinate);
      toolkit.LatLng latlang1 =
          toolkit.LatLng(latLng.latitude, latLng.longitude);
      print(latLng);

      try {
        // Add new point to list.
        if (!firstPolyFinished && !secondPoyFinished) {
          _firstPolyLinesLatLngListForToolkit.add(latlang1);

          _firstPolyLinesLatLngList.add(latLng);

          _polyLines.removeWhere(
              (polyline) => polyline.polylineId.value == 'user_polyline');
          _polyLines.add(
            Polyline(
              polylineId: PolylineId('user_polyline'),
              points: _firstPolyLinesLatLngList,
              width: 2,
              color: Colors.blue,
            ),
          );
        } else {
          _secondtPolyLinesLatLngListForToolkit.add(latlang1);
          _secondPolyLinesLatLngList.add(latLng);

          _polyLines.removeWhere(
              (polyline) => polyline.polylineId.value == 'user_polyline1');
          _polyLines.add(
            Polyline(
              polylineId: PolylineId('user_polyline1'),
              points: _secondPolyLinesLatLngList,
              width: 2,
              color: Colors.blue,
            ),
          );
        }
      } catch (e) {
        print(" error painting $e");
      }
      setState(() {});
    }
  }

  _onPanEnd() async {
    // print('end');
    // Reset last cached coordinate
    _lastXCoordinate = null;
    _lastYCoordinate = null;

    if (_drawPolygonEnabled) {
      _polygons
          .removeWhere((polygon) => polygon.polygonId.value == 'user_polygon');
      _polygons.add(
        Polygon(
          polygonId: PolygonId('user_polygon'),
          points: _firstPolyLinesLatLngList,
          strokeWidth: 2,
          strokeColor: Colors.blue,
          fillColor: Colors.blue.withOpacity(0.4),
        ),
      );

      setState(() {
        firstPolyFinished = true;
      });
    }
  }

  _onPanEnd1() async {
    // print('end');
    // Reset last cached coordinate
    _lastXCoordinate = null;
    _lastYCoordinate = null;

    if (_drawPolygonEnabled) {
      _polygons
          .removeWhere((polygon) => polygon.polygonId.value == 'user_polygon1');
      _polygons.add(
        Polygon(
          polygonId: PolygonId('user_polygon1'),
          points: _secondPolyLinesLatLngList,
          strokeWidth: 2,
          strokeColor: Colors.blue,
          fillColor: Colors.blue.withOpacity(0.4),
        ),
      );

      setState(() {
        secondPoyFinished = true;
      });
    }
  }

  _clearPolygons() async {
    firstPolyFinished = false;
    secondPoyFinished = false;
    _clearDrawing = false;
    try {
      _firstPolyLinesLatLngList.clear();
      _secondPolyLinesLatLngList.clear();
      _polyLines.clear();
      _polygons.clear();
    } catch (e) {
      print(" error painting $e");
    }
    setState(() {});
  }
}
