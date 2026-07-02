package com.drn.app

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("Dr.N-Main", "Configuring Flutter engine")
        ProxyBridge().register(flutterEngine)
        Log.d("Dr.N-Main", "ProxyBridge registered")
    }
}