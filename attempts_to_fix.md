# Attempts to fix compilation errors

## Attempt 1: Add `cached_network_image` dependency

- Added `cached_network_image: ^3.3.1` to `pubspec.yaml`.
- Ran `flutter pub get`.

**Result:** The error `Error: Couldn't resolve the package 'cached_network_image' in 'package:cached_network_image/cached_network_image.dart'.` persisted.

## Attempt 2: Resolve `Position` import conflict

- In `lib/src/features/map/presentation/controllers/map_view_model.dart`:
  - Changed `import 'package:geolocator/geolocator.dart';` to `import 'package:geolocator/geolocator.dart' as geolocator;`.
  - Added `import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';`.
  - Changed `import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';` to `import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Position;`.
  - Changed `Position` to `geolocator.Position`.

**Result:** The error `Error: 'Position' is imported from both 'package:geolocator_platform_interface/src/models/position.dart' and 'package:geotypes/src/geojson.dart'.` persisted.

## Attempt 3: Fix camera change listener and `MapWidget` constructor

- In `lib/src/features/map/presentation/screens/map_screen.dart`:
  - Changed `_mapboxMap?.subscribe(_cameraChanged, [MapEvents.CAMERA_CHANGED]);` to `_mapboxMap?.onCameraChangeListener.add(_cameraChanged);`.
  - Changed `void _cameraChanged(Event event)` to `void _cameraChanged(CameraChangedEventData event)`.
  - Changed `_mapboxMap?.unsubscribe(_cameraChanged, [MapEvents.CAMERA_CHANGED]);` to `_mapboxMap?.onCameraChangeListener.remove(_cameraChanged);`.
  - Moved `resourceOptions: ResourceOptions(accessToken: token)` to the `MapWidget` constructor.

**Result:** The errors related to the camera change listener and the `MapWidget` constructor persisted.

## Attempt 4: Fix annotation click listener and `addStyleImage` method

- In `lib/src/features/map/presentation/controllers/map_view_model.dart`:
  - Changed `_pointAnnotationManager?.onPointAnnotationClickListener.add((annotation) {` to `manager.onPointAnnotationClickListener.add((annotation) {`.
  - Changed `_mapboxMap?.images.addStyleImage(...)` to `_mapboxMap?.style.addStyleImage(...)`.

**Result:** The errors related to the annotation click listener and the `addStyleImage` method persisted.

## Attempt 5: Fix `Position` class conflict

- In `lib/src/features/map/presentation/controllers/map_view_model.dart`:
  - Replaced `Position` with `Point` from `mapbox_maps_flutter`.

**Result:** The error `Error: 'Position' is imported from both 'package:geolocator_platform_interface/src/models/position.dart' and 'package:geotypes/src/geojson.dart'.` persisted.

## Attempt 6: Clean project and fetch dependencies again

- Ran `flutter clean && flutter pub get`.

**Result:** The errors persisted.

## Current errors

```
❯ flutter run -d chrome
Launching lib/main.dart on Chrome in debug mode...
lib/src/features/map/presentation/screens/map_screen.dart:55:40: Error: The method 'add' isn't defined for the class 'void Function(CameraChangedEventData)?'.
 - 'CameraChangedEventData' is from 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
 ('../../.pub-cache/hosted/pub.dev/mapbox_maps_flutter-1.1.0/lib/mapbox_maps_flutter.dart').
Try correcting the name to the name of an existing method, or defining a method named 'add'.
    _mapboxMap?.onCameraChangeListener.add(_cameraChanged);
                                       ^^^
lib/src/features/map/presentation/screens/map_screen.dart:103:40: Error: The method 'remove' isn't defined for the class 'void Function(CameraChangedEventData)?'.
 - 'CameraChangedEventData' is from 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
 ('../../.pub-cache/hosted/pub.dev/mapbox_maps_flutter-1.1.0/lib/mapbox_maps_flutter.dart').
Try correcting the name to the name of an existing method, or defining a method named 'remove'.
    _mapboxMap?.onCameraChangeListener.remove(_cameraChanged);
                                       ^^^^^^
lib/src/features/map/presentation/screens/map_screen.dart:129:13: Error: No named parameter with the name 'resourceOptions'.
            resourceOptions: ResourceOptions(accessToken: token),
            ^^^^^^^^^^^^^^^
../../.pub-cache/hosted/pub.dev/mapbox_maps_flutter-1.1.0/lib/src/map_widget.dart:42:3: Context: Found this candidate, but the arguments don't match.
  MapWidget({
  ^^^^^^^^^
lib/src/features/map/presentation/controllers/map_view_model.dart:48:13: Error: The getter 'onPointAnnotationClickListener' isn't defined for the class
'PointAnnotationManager'.
 - 'PointAnnotationManager' is from 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'
 ('../../.pub-cache/hosted/pub.dev/mapbox_maps_flutter-1.1.0/lib/mapbox_maps_flutter.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'onPointAnnotationClickListener'.
    manager.onPointAnnotationClickListener.add((annotation) {
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
lib/src/features/map/presentation/controllers/map_view_model.dart:99:46: Error: Too many positional arguments: 0 allowed, but 2 found.
Try removing the extra positional arguments.
        geometry: Point(coordinates: Position(field.longitude, field.latitude)).toJson(),
                                             ^
../../.pub-cache/hosted/pub.dev/geolocator_platform_interface-4.2.6/lib/src/models/position.dart:9:9: Context: Found this candidate, but the arguments don't match.
  const Position({
        ^^^^^^^^
lib/src/features/map/presentation/controllers/map_view_model.dart:194:44: Error: Too many positional arguments: 0 allowed, but 2 found.
Try removing the extra positional arguments.
      geometry: Point(coordinates: Position(_userPosition!.longitude, _userPosition!.latitude))
                                           ^
../../.pub-cache/hosted/pub.dev/geolocator_platform_interface-4.2.6/lib/src/models/position.dart:9:9: Context: Found this candidate, but the arguments don't match.
  const Position({
        ^^^^^^^^
lib/src/features/map/presentation/controllers/map_view_model.dart:204:44: Error: Too many positional arguments: 0 allowed, but 2 found.
Try removing the extra positional arguments.
        center: Point(coordinates: Position(field.longitude, field.latitude)).toJson(),
                                           ^
../../.pub-cache/hosted/pub.dev/geolocator_platform_interface-4.2.6/lib/src/models/position.dart:9:9: Context: Found this candidate, but the arguments don't match.
  const Position({
        ^^^^^^^^
lib/src/features/map/presentation/controllers/map_view_model.dart:221:46: Error: Too many positional arguments: 0 allowed, but 2 found.
Try removing the extra positional arguments.
          center: Point(coordinates: Position(avgLng, avgLat)).toJson(),
                                             ^
../../.pub-cache/hosted/pub.dev/geolocator_platform_interface-4.2.6/lib/src/models/position.dart:9:9: Context: Found this candidate, but the arguments don't match.
  const Position({
        ^^^^^^^^
lib/src/features/map/presentation/controllers/map_view_model.dart:234:46: Error: Too many positional arguments: 0 allowed, but 2 found.
Try removing the extra positional arguments.
          center: Point(coordinates: Position(_userPosition!.longitude, _userPosition!.latitude))
                                             ^
../../.pub-cache/hosted/pub.dev/geolocator_platform_interface-4.2.6/lib/src/models/position.dart:9:9: Context: Found this candidate, but the arguments don't match.
  const Position({
        ^^^^^^^^
Waiting for connection from debug service on Chrome...             35.0s
Failed to compile application.
~/dev/Scuzzy-goalkeeper feat/migrate-to-mapbox *1 !6 ?5 ❯
