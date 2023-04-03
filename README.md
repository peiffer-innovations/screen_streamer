# screen_streamer

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Introduction](#introduction)
- [Setup](#setup)
  - [Android](#android)
  - [iOS](#ios)
  - [MacOS](#macos)
  - [Linux](#linux)
  - [Web](#web)
  - [Windows](#windows)
- [Usage](#usage)
  - [Sending](#sending)
  - [Receiving](#receiving)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

---

## Introduction

A package that utilizes the super awesome [flutter_webrtc](https://pub.dev/packages/flutter_webrtc) package to be able to send the screen from one device to another.  The package was inspired by a closed [Flutter Issue](https://github.com/flutter/flutter/issues/81653).

This is compatible with all Flutter platforms, including Web, but has only been tested on Android, iOS, MacOS, and Web.

This package provides two examples.  One to [send the screen](https://github.com/peiffer-innovations/screen_streamer/tree/main/examples/sender) and the other to [receive the screen](https://github.com/peiffer-innovations/screen_streamer/tree/main/examples/receiver).

As a note, this library will not work on simulators or emulators as the underlying frameworks don't exist.  You must use a physical device when using this framework.

---

## Setup

### Android

On Android, you must add three permissions:

1. `android.permission.ACCESS_NETWORK_STATE`
1. `android.permission.FOREGROUND_SERVICE`
1. `android.permission.SCHEDULE_EXACT_ALARM`

Next, within the `application` tag, you must add the following service:

```xml
<service android:name="id.flutter.flutter_background_service.BackgroundService"
    android:foregroundServiceType="mediaProjection"
    android:enabled="true"
    android:exported="false"
    tools:replace="android:exported" />
```

Your `AndroidManifest.xml` file will now look similar to:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="com.example.sender">

    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />

    <application
        android:label="sender"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"
            />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to
        generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />

        <service android:name="id.flutter.flutter_background_service.BackgroundService"
            android:foregroundServiceType="mediaProjection"
            android:enabled="true"
            android:exported="false"
            tools:replace="android:exported" />

    </application>
</manifest>
```


### iOS

No special configuration needed for iOS


---

### MacOS

Open your macOS workspace in Xcode and enable both of the network permissions fro all build modes:

* `Incoming Connections (Server)`
* `Outgoing Connections (Client)`


---

### Linux

No known special configuration needed for Linux

---

### Web

No known special configuration needed for Web

---

### Windows

No known special configuration needed for Windows

---

## Usage

### Sending

To send a screen to a remote listener, you can utilize the `ScreenSender` class.

```dart

final sender = ScreenSender();
await sender.connect(
  Uri.parse(_controller.text),
  context: context,
);

```


---

### Receiving

To send a screen to a remote listener, you can utilize the `ScreenReceiver`
class along with the `RemoteScreenRenderer`.
