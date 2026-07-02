package com.drn.app

import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ProxyBridge {
    private val TAG = "DrNBridge"
    private var core: drnbind.Core? = null

    fun register(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "drn.app/proxy"
        )
        Log.d(TAG, "Registering channel drn.app/proxy")

        // Try to load the Go backend
        try {
            core = drnbind.Core()
            Log.d(TAG, "Go backend loaded successfully")
        } catch (e: Throwable) {
            Log.w(TAG, "Go backend not available: ${e.message}")
        }

        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getServers" -> result.success("[]")
                    "getStatus" -> {
                        val status = core?.getStatusJSON() ?: """{"running":false}"""
                        result.success(status)
                    }
                    "addServer" -> result.success(null)
                    "removeServer" -> result.success(null)
                    "startProxy" -> {
                        val c = core
                        if (c != null) {
                            val addr = call.argument<String>("address") ?: ""
                            val port = call.argument<String>("port") ?: "19132"
                            try {
                                c.startProxy(addr, port)
                                result.success(null)
                            } catch (e: Exception) {
                                result.error("PROXY_FAILED", e.message, null)
                            }
                        } else {
                            result.error(
                                "BACKEND_UNAVAILABLE",
                                "Go proxy not loaded",
                                null
                            )
                        }
                    }
                    "stopProxy" -> {
                        core?.stopProxy()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in ${call.method}: ${e.message}")
                result.error("ERROR", e.message, null)
            }
        }
        Log.d(TAG, "Channel ready (Go: ${if (core != null) "loaded" else "missing"})")
    }
}