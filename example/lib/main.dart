import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_user_certificates_android/flutter_user_certificates_android.dart';

final _flutterUserCertificatesAndroidPlugin = FlutterUserCertificatesAndroid();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Extend the default security context to trust Android user certificates.
  // This is a workaround for <https://github.com/dart-lang/sdk/issues/50435>.
  await _flutterUserCertificatesAndroidPlugin.trustAndroidUserCertificates(SecurityContext.defaultContext);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, Uint8List> _certs = {};
  String? error;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    Map<String, Uint8List>? certs;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      certs = await _flutterUserCertificatesAndroidPlugin.getUserCertificates();
    } on PlatformException {
      error = 'Failed to get user certificates from device.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    if (certs == null) return;

    setState(() {
      _certs = certs!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: error != null
            ? Center(
                child: Text(error!),
              )
            : ListView.builder(
                itemCount: _certs.length,
                itemBuilder: (c, i) => ListTile(
                  title: Text(_certs.keys.elementAt(i)),
                ),
              ),
      ),
    );
  }
}
