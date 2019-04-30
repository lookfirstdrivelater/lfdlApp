import 'package:flutter_map/flutter_map.dart';
import 'package:lfdl_app/gps.dart';
import 'package:flutter/widgets.dart';
import 'package:lfdl_app/events.dart';
import 'package:flutter/material.dart';
import '../drawer.dart';
import 'package:latlong/latlong.dart';
import 'package:lfdl_app/server.dart';

//Map display page
class MapPage extends StatefulWidget {
  @override
  State createState() => MapPageState();

  static const route = "/";
}

class MapPageState extends State<MapPage> {
  final mapController = MapController();
  final mapPolylines = List<Polyline>();
  final circles = List<CircleMarker>();

  @override
  void initState() {
    super.initState();
    centerMapOnLocation();
  }

  void centerMapOnLocation() async {
    final position = await GPS.location();
    mapController.move(position, 15.0);
  }

  void addRoadEvents(List<RoadEvent> events) {
    setState(() {
      for (RoadEvent event in events) {
        mapPolylines.add(Polyline(
          points: event.points,
          color: eventColors[event.type],
          strokeWidth: 2.0,
        ));
      }
    });
  }

  ReportEvent reportEvent;

  void onTap(LatLng latLgn) {
    if (reportEvent != null) {
      setState(() {
        reportEvent.points.add(latLgn);
      });
    }
  }

  void onStartRoadPressed() {
    if (reportEvent == null) {
      reportEvent = ReportEvent(
        points: List(),
        type: EventType.snow,
      );
      mapPolylines.add(reportEvent.polyline);
    }
  }

  void onEndRoadPressed() {
    if (reportEvent != null) {
      setState(() {
        reportEvent = null;
      });
    }
  }

  void onUndoPressed() {
    if (reportEvent != null) {
      setState(() {
//        circles.removeLast();
        reportEvent.points.removeLast();
      });
    } else if(mapPolylines.length != 0){
      mapPolylines.removeLast();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Map")),
      drawer: buildDrawer(context, MapPage.route),
      body: Scrollbar(
          child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Column(children: [
                  FlatButton(
                      onPressed: onStartRoadPressed,
                      child: Text("Start Road Event")),
                  FlatButton(
                      onPressed: onEndRoadPressed,
                      child: Text("End Road Event")),
                  FlatButton(
                    onPressed: onUndoPressed,
                    child: Text("Undo"),
                  ),
                  FlatButton(
                    onPressed: centerMapOnLocation,
                    child: Text("Center Around Person"),
                  ),
                ])),
            Flexible(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(onTap: onTap),
                layers: [
                  TileLayerOptions(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c']),
                  PolylineLayerOptions(
                    polylines:
                        mapPolylines,
                  ),
                  CircleLayerOptions(
                      circles: reportEvent?.points
                          ?.map((point) =>
                          CircleMarker(point: point, radius: 10.0))
                          ?.toList() ?? List()
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }
}