package com.lune.wear.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.platform.LocalContext
import com.lune.wear.data.WatchDataLayerClient

@Composable
fun LuneWearApp() {
    val context = LocalContext.current
    val client = WatchDataLayerClient(context)

    LaunchedEffect(Unit) {
        client.connect()
    }

    val cycleData by client.cycleData.collectAsState()
    val connected by client.connected.collectAsState()

    CycleScreen(
        cycleData = cycleData,
        connected = connected,
        onLogPeriod = {
            kotlinx.coroutines.runBlocking { client.sendLogRequest() }
        }
    )
}
