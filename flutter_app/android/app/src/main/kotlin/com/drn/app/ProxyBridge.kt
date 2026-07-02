package com.drn.app

import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ProxyBridge {
    private val TAG = "Dr.N-Bridge"

    fun register(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "drn.app/proxy")
        Log.d(TAG, "Registering MethodChannel: drn.app/proxy")

        channel.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            Log.d(TAG, "Method called: ${call.method}")
            try {
                when (call.method) {
                    "getServers" -> {
                        result.success("[]")
                    }
                    "getStatus" -> {
                        result.success("""{"running":false,"note":"Go backend not loaded"}""")
                    }
                    "addServer" -> {
                        result.success(null)
                    }
                    "removeServer" -> {
                        result.success(null)
                    }
                    "startProxy" -> {
                        val address = call.argument<String>("address") ?: ""
                        val port = call.argument<String>("port") ?: "19132"
                        Log.d(TAG, "startProxy called: $address:$port")

                        // Try to use Go backend if available, otherwise return error
                        try {
                            val core = drnbind.Core()
                            core.startProxy(address, port)
                            Log.d(TAG, "Proxy started via Go backend")
                            result.success(null)
                        } catch (e: Throwable) {
                            Log.e(TAG, "Go backend failed: ${e.message}")
                            result.error(
                                "BACKEND_UNAVAILABLE",
                                "Go proxy backend not available: ${e.message}",
                                null
                            )
                        }
                    }
                    "stopProxy" -> {
                        try {
                            val core = drnbind.Core()
                            core.stopProxy()
                            result.success(null)
                        } catch (e: Throwable) {
                            result.success(null) // Not running is fine
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Unhandled error: ${e.message}")
                result.error("ERROR", e.message, null)
            }
        }
        Log.d(TAG, "MethodChannel registered successfully")
    }
}