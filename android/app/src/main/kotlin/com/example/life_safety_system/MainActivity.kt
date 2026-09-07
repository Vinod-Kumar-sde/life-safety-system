package com.example.life_safety_system

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "life_safety_system/network"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "isConnected") {

                val connectivityManager =
                    getSystemService(
                        Context.CONNECTIVITY_SERVICE
                    ) as ConnectivityManager

                val network =
                    connectivityManager.activeNetwork

                val capabilities =
                    connectivityManager.getNetworkCapabilities(network)

                val connected =
                    capabilities != null &&
                    capabilities.hasCapability(
                        NetworkCapabilities.NET_CAPABILITY_INTERNET
                    ) &&
                    capabilities.hasCapability(
                        NetworkCapabilities.NET_CAPABILITY_VALIDATED
                    )

                result.success(connected)

            } else {
                result.notImplemented()
            }
        }
    }
}