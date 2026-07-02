package com.lune.app

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService

/**
 * Listens for "log period" requests sent from the Wear OS app over the
 * Data Layer ([LOG_REQUEST_PATH]).
 *
 * The Flutter engine may not be running when the watch sends the request, so we
 * persist the timestamp into Flutter's SharedPreferences. The phone app reads
 * and processes it on the next launch/resume (see WatchSyncService in Dart).
 */
class WearLogRequestListenerService : WearableListenerService() {

    companion object {
        private const val TAG = "LuneWearListener"
        private const val LOG_REQUEST_PATH = "/lune/log-request"

        // Flutter's shared_preferences backing file and key prefix.
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val PENDING_KEY = "flutter.pending_watch_log_timestamp"
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            if (event.dataItem.uri.path != LOG_REQUEST_PATH) continue

            try {
                val map = DataMapItem.fromDataItem(event.dataItem).dataMap
                val timestamp = map.getLong("timestamp")
                val prefs = applicationContext
                    .getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
                prefs.edit().putString(PENDING_KEY, timestamp.toString()).apply()
                Log.d(TAG, "Stored pending watch log request: $timestamp")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to handle log request: $e")
            }
        }
    }
}
