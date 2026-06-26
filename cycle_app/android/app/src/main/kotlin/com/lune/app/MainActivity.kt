package com.lune.app

import android.util.Log
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "LunePhone"
        private const val CHANNEL = "com.lune.app/wear_sync"
        private const val CYCLE_PATH = "/lune/cycle"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendCycleData" -> {
                    val currentValue = call.argument<Int>("currentValue") ?: 1
                    val maxValue = call.argument<Int>("maxValue") ?: 28
                    val phase = call.argument<String>("phase") ?: "Unknown"
                    val daysUntilPeriod = call.argument<Int>("daysUntilPeriod") ?: 0
                    sendToWearDataLayer(currentValue, maxValue, phase, daysUntilPeriod)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun sendToWearDataLayer(currentValue: Int, maxValue: Int, phase: String, daysUntilPeriod: Int) {
        Executors.newSingleThreadExecutor().execute {
            try {
                val request = PutDataMapRequest.create(CYCLE_PATH).apply {
                    dataMap.putInt("currentValue", currentValue)
                    dataMap.putInt("maxValue", maxValue.coerceAtLeast(28))
                    dataMap.putString("phase", phase)
                    dataMap.putInt("daysUntilPeriod", daysUntilPeriod)
                }.asPutDataRequest().setUrgent()
                Tasks.await(Wearable.getDataClient(this@MainActivity).putDataItem(request))
                Log.d(TAG, "Cycle data sent to watch: day $currentValue/$maxValue, phase: $phase")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send to Wear Data Layer: $e")
            }
        }
    }
}
