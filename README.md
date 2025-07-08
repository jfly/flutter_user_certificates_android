# flutter_user_certificates_android

A Flutter plugin for getting user installed certificates on Android.

This is useful for working around the limitation that Dart's HttpClient doesn't
honor user installed certificates on Android. See:

- [dart-lang/sdk#50435](https://github.com/dart-lang/sdk/issues/50435)
- [flutter/flutter#56607](https://github.com/flutter/flutter/issues/56607)

## Getting Started

Here is an example that trusts and lists all the user installed certificates on the device.

```dart
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

  Future<void> initPlatformState() async {
    Map<String, Uint8List>? certs;
    try {
      certs = await _flutterUserCertificatesAndroidPlugin.getUserCertificates();
    } on PlatformException {
      error = 'Failed to get user certificates from device.';
    }

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
```

## Note about native Android HTTP

The above example only affects HTTP calls with Dart's
[http](https://pub.dev/packages/http) library. If you (or some library you
depend on) are using `javax.net.ssl.HttpsURLConnection` or
[Cronet](https://pub.dev/packages/cronet_http), then you will also need a
`<network-security-config>` that adds user certificates as a trust anchor.

`android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android" ...>
  <application ... android:networkSecurityConfig="@xml/network_security_config">
  ...
</manifest>
```

`android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
  <base-config>
    <trust-anchors>
      <certificates src="system"/>
      <certificates src="user"/>
    </trust-anchors>
  </base-config>
</network-security-config>
```

See
<https://developer.android.com/privacy-and-security/security-config#network-security-config>
for more details.
