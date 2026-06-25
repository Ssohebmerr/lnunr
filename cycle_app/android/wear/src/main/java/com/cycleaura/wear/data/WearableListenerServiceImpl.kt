package com.cycleaura.wear.data

import android.util.Log
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.WearableListenerService

class WearableListenerServiceImpl : WearableListenerService() {

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        Log.d("WearListener", "Data changed: ${dataEvents.count} events")
        // The watch-side data client handles the data events via its listener
    }
}
