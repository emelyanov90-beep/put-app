import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/app.dart';
import 'package:vput/core/api/pocketbase_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final pocketBase = await createPocketBase();

  runApp(
    ProviderScope(
      overrides: [pocketBaseProvider.overrideWithValue(pocketBase)],
      child: const VputApp(),
    ),
  );
}
