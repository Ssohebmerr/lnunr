package com.lune.wear.data

import android.content.SharedPreferences
import android.util.Log
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService

class WearableListenerServiceImpl : WearableListenerService() {

    companion object {
        private const val TAG = "WearListener"
        private const val CYCLE_PATH = "/lune/cycle"
        private const val LOG_REQUEST_PATH = "/lune/log-request"
        private const val PREFS_NAME = "lune_tile_prefs"
        private const val KEY_CURRENT = "currentValue"
        private const val KEY_MAX = "maxValue"
        private const val KEY_PHASE = "phase"
        private const val KEY_DAYS = "daysUntilPeriod"
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            val uri = event.dataItem.uri
            val path = uri.path ?: continue
            Log.d(TAG, "Data changed at path: $path")

            when (path) {
                CYCLE_PATH -> {
                    try {
                        val map = DataMapItem.fromDataItem(event.dataItem).dataMap
                        val prefs: SharedPreferences = applicationContext.getSharedPreferences(PREFS_NAME, 0)
                        prefs.edit()
                            .putInt(KEY_CURRENT, map.getInt(KEY_CURRENT))
                            .putInt(KEY_MAX, map.getInt(KEY_MAX))
                            .putString(KEY_PHASE, map.getString(KEY_PHASE) ?: "Unknown")
                            .putInt(KEY_DAYS, map.getInt(KEY_DAYS))
                            .apply()
                        Log.d(TAG, "Tile prefs updated: cur=${map.getInt(KEY_CURRENT)} max=${map.getInt(KEY_MAX)} phase=${map.getString(KEY_PHASE)}")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to process cycle data: $e")
                    }
                }

                LOG_REQUEST_PATH -> {
                    Log.d(TAG, "Log request received from phone (handled by phone-side)")
                }
            }
        }
    }
}
