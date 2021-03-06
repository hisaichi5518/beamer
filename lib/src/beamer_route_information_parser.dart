import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:beamer/src/beam_location.dart';

class BeamerRouteInformationParser
    extends RouteInformationParser<BeamLocation> {
  BeamerRouteInformationParser({
    @required this.beamLocations,
  });

  /// A [List] of all available [BeamLocation]s in the [Router]'s scope.
  final List<BeamLocation> beamLocations;

  @override
  SynchronousFuture<BeamLocation> parseRouteInformation(
      RouteInformation routeInformation) {
    final uri = Uri.parse(routeInformation.location);
    return SynchronousFuture(_chooseBeamLocation(uri));
  }

  @override
  RouteInformation restoreRouteInformation(BeamLocation location) {
    return RouteInformation(location: location.uri);
  }

  /// Traverses all [beamLocations] and returns the one whose one of
  /// [pathBlueprints] contains the [uri], ignoring concrete path parameters.
  ///
  /// Upon finding such [BeamLocation], configures it with
  /// [pathParameters] and [queryParameters] from [uri].
  ///
  /// If [beamLocations] don't contain a match, [NotFound] will be returned
  /// configured with [uri].
  BeamLocation _chooseBeamLocation(Uri uri) {
    for (var beamLocation in beamLocations) {
      for (var pathBlueprint in beamLocation.pathBlueprints) {
        if (pathBlueprint == uri.path) {
          beamLocation.pathSegments = uri.pathSegments;
          beamLocation.queryParameters = uri.queryParameters;
          return beamLocation..prepare();
        }
        final beamLocationPathBlueprintSegments =
            Uri.parse(pathBlueprint).pathSegments;
        if (uri.pathSegments.length >
            beamLocationPathBlueprintSegments.length) {
          continue;
        }
        var pathSegments = <String>[];
        var pathParameters = <String, String>{};
        var checksPassed = true;
        for (var i = 0; i < uri.pathSegments.length; i++) {
          if (uri.pathSegments[i] != beamLocationPathBlueprintSegments[i] &&
              beamLocationPathBlueprintSegments[i][0] != ':') {
            checksPassed = false;
            break;
          } else if (beamLocationPathBlueprintSegments[i][0] == ':') {
            pathParameters[beamLocationPathBlueprintSegments[i].substring(1)] =
                uri.pathSegments[i];
            pathSegments.add(beamLocationPathBlueprintSegments[i]);
          } else {
            pathSegments.add(uri.pathSegments[i]);
          }
        }
        if (checksPassed) {
          beamLocation.pathSegments = pathSegments;
          beamLocation.pathParameters = pathParameters;
          beamLocation.queryParameters = uri.queryParameters;
          return beamLocation..prepare();
        }
      }
    }
    return NotFound(path: uri.path);
  }
}
