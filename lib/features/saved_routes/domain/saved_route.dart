import 'package:flutter/foundation.dart';

@immutable
class SavedRoute {
  const SavedRoute({
    required this.id,
    required this.title,
    required this.origin,
    required this.destination,
  });

  final String id;
  final String title;
  final String origin;
  final String destination;

  String get routeLabel => '$origin → $destination';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'origin': origin,
    'destination': destination,
  };

  static SavedRoute? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final origin = json['origin'];
    final destination = json['destination'];
    if (id is! String || origin is! String || destination is! String) {
      return null;
    }
    if (origin.isEmpty || destination.isEmpty) return null;
    return SavedRoute(
      id: id,
      title: json['title'] is String && (json['title'] as String).isNotEmpty
          ? json['title'] as String
          : '$origin → $destination',
      origin: origin,
      destination: destination,
    );
  }
}
