import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:open_office_online/flutter_configuration.dart';
import 'package:open_office_online/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

late SharedPreferences prefs;
late FlutterConfiguration config;

void main() async {
  // see https://stackoverflow.com/questions/67604560/flutter-unable-to-load-text-from-assets-folder
  WidgetsFlutterBinding.ensureInitialized();
  config = await FlutterConfiguration.fromAsset('assets/config.yaml');
  // config window size on desktop platform
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    var size = Size(config.windowWidth, config.windowHeight);
    // disable window resizing
    await DesktopWindow.setWindowSize(size);
    await DesktopWindow.setMinWindowSize(size);
    await DesktopWindow.setMaxWindowSize(size);
  }
  // init local storage
  prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('first_run')) {
    await prefs.setBool('first_run', true);
    await prefs.setString('providers', jsonEncode(config.providers));
  }

  runApp(const App());
}

class App extends StatelessWidget {
  final appTitle = 'Open Office Online';
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: HomePage(title: appTitle),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textController = TextEditingController(text: "");
  final List<Provider> _providers = config.providers;
  late Timer clipboardTriggerTime;
  bool validInput = false;

  @override
  void initState() {
    super.initState();
    // listen to clipboard and trigger a paste
    // clipboardTriggerTime = Timer.periodic(
    //   const Duration(seconds: 5),
    //   (timer) {
    //     Clipboard.getData('text/plain').then((clipboarContent) {
    //       if (clipboarContent!.text!.isNotEmpty &&
    //           _textController.text != clipboarContent.text) {
    //         setState(() {
    //           _textController.text = clipboarContent.text!;
    //         });
    //       }
    //     });
    //   },
    // );
  }

  @override
  void dispose() {
    clipboardTriggerTime.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _setting() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var appBarHeight = AppBar().preferredSize.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  const url =
                      'https://github.com/liudonghua123/open_office_online.git';
                  if (await canLaunch(url)) {
                    await launch(url);
                  }
                },
                child: Lottie.asset(
                  'assets/28189-github-octocat.json',
                  height: appBarHeight,
                ),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: [
                const Text(
                  'Resource URL:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'input office file url here...',
                      suffix: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _textController.clear();
                            validInput = false;
                          });
                        },
                      ),
                    ),
                    controller: _textController,
                    onChanged: (text) {
                      var urlReg = RegExp(
                          r'^((?:.|\n)*?)((http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)([-A-Z0-9.]+)(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:‌​,.;]*)?)',
                          caseSensitive: false);
                      var input = text.trim();
                      setState(() {
                        var _selection = _textController.selection;
                        _textController.text = input;
                        _textController.selection = _selection;
                        validInput = input.isNotEmpty && urlReg.hasMatch(input);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    child: const Text(
                      'Open',
                      style: TextStyle(fontSize: 18),
                    ),
                    onPressed: validInput
                        ? () async {
                            for (var provider in _providers) {
                              var launchUrl =
                                  '${provider.url}${Uri.encodeComponent(_textController.text)}';
                              if (provider.enabled &&
                                  await canLaunch(launchUrl)) {
                                await launch(launchUrl);
                              }
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
            Row(children: [
              const Text(
                'Providers:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ..._providers.map((provider) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: SizedBox(
                    width: 150,
                    child: CheckboxListTile(
                      title: Text(provider.name),
                      value: provider.enabled,
                      onChanged: (bool? value) {
                        setState(() {
                          provider.enabled = !provider.enabled;
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ]),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _setting,
        tooltip: 'Setting',
        child: const Icon(Icons.settings),
      ),
    );
  }
}
