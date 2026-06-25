package com.lune.wear.data

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.DataClient
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.tasks.await

data class CycleData(
    val currentValue: Int = 0,
    val maxValue: Int = 28,
    val phase: String = "Unknown",
    val daysUntilPeriod: Int = 0
) {
    val progress: Float
        get() = if (maxValue > 0) currentValue.toFloat() / maxValue else 0f
}

class WatchDataLayerClient(private val context: Context) {

    private val dataClient: DataClient = Wearable.getDataClient(context)

    private val _cycleData = MutableStateFlow(CycleData())
    val cycleData: StateFlow<CycleData> = _cycleData.asStateFlow()

    private val _connected = MutableStateFlow(false)
    val connected: StateFlow<Boolean> = _connected.asStateFlow()

    companion object {
        private const val TAG = "WatchDataLayer"
        private const val CYCLE_PATH = "/lune/cycle"
        private const val LOG_REQUEST_PATH = "/lune/log-request"
        private const val KEY_CURRENT = "currentValue"
        private const val KEY_MAX = "maxValue"
        private const val KEY_PHASE = "phase"
        private const val KEY_DAYS_UNTIL = "daysUntilPeriod"
    }

    fun connect() {
        try {
            dataClient.addListener { events -> processEvents(events) }
            _connected.value = true
            Log.d(TAG, "Connected to Data Layer")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to connect: $e")
            _connected.value = false
        }
    }

    private fun processEvents(events: DataEventBuffer) {
        for (event in events) {
            if (event.type == DataEvent.TYPE_CHANGED && event.dataItem.uri.path == CYCLE_PATH) {
                val map = DataMapItem.fromDataItem(event.dataItem).dataMap
                _cycleData.value = CycleData(
                    currentValue = map.getInt(KEY_CURRENT),
                    maxValue = map.getInt(KEY_MAX).coerceAtLeast(28),
                    phase = map.getString(KEY_PHASE) ?: "Unknown",
                    daysUntilPeriod = map.getInt(KEY_DAYS_UNTIL)
                )
                Log.d(TAG, "Cycle data updated: ${_cycleData.value}")
            }
        }
    }

    suspend fun sendLogRequest() {
        try {
            val req = PutDataMapRequest.create(LOG_REQUEST_PATH).apply {
                dataMap.putLong("timestamp", System.currentTimeMillis())
            }.asPutDataRequest().setUrgent()
            dataClient.putDataItem(req).await()
            Log.d(TAG, "Log request sent")
        } catch (e: Exception) {
            Log.e(TAG, "Log request failed: $e")
        }
    }
}
