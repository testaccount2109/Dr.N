package com.drn.app

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import drnbind.Core

class ProxyBridge(private val context: Context) {
    private val core: Core = Core()

    fun register(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "drn.app/proxy")

        channel.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            try {
                when (call.method) {
                    "getServers" -> {
                        result.success(core.getServersJSON())
                    }
                    "getStatus" -> {
                        result.success(core.getStatusJSON())
                    }
                    "addServer" -> {
                        val name = call.argument<String>("name") ?: ""
                        val address = call.argument<String>("address") ?: ""
                        val port = call.argument<String>("port") ?: "19132"
                        core.addServer(name, address, port)
                        result.success(null)
                    }
                    "removeServer" -> {
                        val id = call.argument<String>("id") ?: ""
                        core.removeServer(id)
                        result.success(null)
                    }
                    "startProxy" -> {
                        val address = call.argument<String>("address") ?: ""
                        val port = call.argument<String>("port") ?: "19132"
                        try {
                            core.startProxy(address, port)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("PROXY_ERROR", e.message, null)
                        }
                    }
                    "stopProxy" -> {
                        try {
                            core.stopProxy()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("PROXY_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("ERROR", e.message, null)
            }
        }
    }
}