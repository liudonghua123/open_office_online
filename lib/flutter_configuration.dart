import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:open_office_online/provider.dart';
import 'package:yaml/yaml.dart';

class FlutterConfiguration {
  late YamlMap _data;
  late double windowHeight, windowWidth;
  late List<Provider> providers;

  static Future<FlutterConfiguration> fromAsset(String asset) async {
    var text = await rootBundle.loadString(asset);
    return FlutterConfiguration(text);
  }

  static Future<FlutterConfiguration> fromFile(File file) async {
    var text = await file.readAsString();
    return FlutterConfiguration(text);
  }

  void _init() {
    var _defaultWindowSize = get('default_window_size');
    var _defaultProviders = get('default_providers');
    windowHeight = double.parse(_defaultWindowSize['height'].toString());
    windowWidth = double.parse(_defaultWindowSize['width'].toString());
    providers = _defaultProviders.map<Provider>((provider) {
      return Provider(
        name: provider['name'].toString(),
        url: provider['url'].toString(),
        enabled: provider['enabled'],
      );
    }).toList();
  }

  FlutterConfiguration(String text) {
    _data = loadYaml(text);
    _init();
  }

  dynamic get(String key) => _data[key];

  @override
  String toString() {
    return _data.toString();
  }
}
