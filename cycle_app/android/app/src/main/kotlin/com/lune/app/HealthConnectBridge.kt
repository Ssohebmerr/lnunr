package com.lune.app

import android.content.Intent
import android.net.Uri
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.HealthConnectFeatures
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.BasalBodyTemperatureRecord
import androidx.health.connect.client.records.CervicalMucusRecord
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HeartRateVariabilityRmssdRecord
import androidx.health.connect.client.records.HydrationRecord
import androidx.health.connect.client.records.IntermenstrualBleedingRecord
import androidx.health.connect.client.records.MenstruationFlowRecord
import androidx.health.connect.client.records.MenstruationPeriodRecord
import androidx.health.connect.client.records.OvulationTestRecord
import androidx.health.connect.client.records.Record
import androidx.health.connect.client.records.RestingHeartRateRecord
import androidx.health.connect.client.records.SkinTemperatureRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.WeightRecord
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.health.connect.client.units.Mass
import androidx.health.connect.client.units.Temperature
import androidx.health.connect.client.units.Volume
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.Instant
import java.time.ZoneId
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Native Health Connect adapter. Flutter receives plain maps only; no health
 * information leaves the device or enters a Firebase/analytics channel here.
 */
class HealthConnectBridge(
    private val activity: MainActivity,
    messenger: BinaryMessenger,
    private val permissionRequester: (Set<String>, MethodChannel.Result) -> Unit,
) {
    companion object {
        private const val CHANNEL = "com.lune.app/health_connect"
        private const val PROVIDER = "com.google.android.apps.healthdata"
        private const val HISTORY_PERMISSION =
            "android.permission.health.READ_HEALTH_DATA_HISTORY"
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val channel = MethodChannel(messenger, CHANNEL)
    private val client by lazy { HealthConnectClient.getOrCreate(activity) }

    init {
        channel.setMethodCallHandler(::onMethodCall)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStatus" -> launch(result) { statusMap() }
            "requestPermissions" -> {
                if (!isAvailable()) {
                    result.error("unavailable", "Health Connect is unavailable", null)
                    return
                }
                val group = call.argument<String>("group") ?: "cycle"
                scope.launch {
                    val permissions = permissionsFor(group, includeHistory = true)
                    withContext(Dispatchers.Main) {
                        permissionRequester(permissions, result)
                    }
                }
            }
            "readData" -> launch(result) {
                val group = call.argument<String>("group") ?: "cycle"
                val start = parseInstant(call.argument<String>("start"))
                val end = parseInstant(call.argument<String>("end"))
                readData(group, start, end)
            }
            "writeData" -> launch(result) {
                writeData(call.argument<List<*>>("records").orEmpty())
            }
            "revokeAllPermissions" -> launch(result) {
                client.permissionController.revokeAllPermissions()
                true
            }
            "openSettings" -> {
                result.success(openSettings())
            }
            "installProvider" -> {
                val market = Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("market://details?id=$PROVIDER"),
                )
                activity.startActivity(market)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun launch(
        result: MethodChannel.Result,
        block: suspend () -> Any?,
    ) {
        scope.launch {
            try {
                val value = block()
                withContext(Dispatchers.Main) { result.success(value) }
            } catch (error: Throwable) {
                withContext(Dispatchers.Main) {
                    result.error(
                        "health_connect_error",
                        error.message ?: error.javaClass.simpleName,
                        null,
                    )
                }
            }
        }
    }

    private fun sdkStatus(): Int = HealthConnectClient.getSdkStatus(activity, PROVIDER)

    private fun isAvailable(): Boolean =
        sdkStatus() == HealthConnectClient.SDK_AVAILABLE

    private suspend fun statusMap(): Map<String, Any> {
        val status = sdkStatus()
        if (status != HealthConnectClient.SDK_AVAILABLE) {
            return mapOf(
                "availability" to if (
                    status == HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED
                ) "installRequired" else "notSupported",
                "cycleGranted" to false,
                "wellnessGranted" to false,
            )
        }

        val granted = client.permissionController.getGrantedPermissions()
        val cycle = permissionsFor("cycle")
        val wellness = permissionsFor("wellness")
        return mapOf(
            "availability" to "available",
            "cycleGranted" to granted.containsAll(cycle),
            "wellnessGranted" to granted.containsAll(wellness),
            "cycleGrantedCount" to cycle.count(granted::contains),
            "cyclePermissionCount" to cycle.size,
            "wellnessGrantedCount" to wellness.count(granted::contains),
            "wellnessPermissionCount" to wellness.size,
            "historyGranted" to granted.contains(HISTORY_PERMISSION),
        )
    }

    private fun permissionsFor(
        group: String,
        includeHistory: Boolean = false,
    ): Set<String> {
        val permissions = if (group == "wellness") {
            mutableSetOf(
                HealthPermission.getReadPermission(SleepSessionRecord::class),
                HealthPermission.getWritePermission(SleepSessionRecord::class),
                HealthPermission.getReadPermission(StepsRecord::class),
                HealthPermission.getReadPermission(ExerciseSessionRecord::class),
                HealthPermission.getReadPermission(RestingHeartRateRecord::class),
                HealthPermission.getReadPermission(HeartRateVariabilityRmssdRecord::class),
                HealthPermission.getReadPermission(SkinTemperatureRecord::class),
                HealthPermission.getReadPermission(WeightRecord::class),
                HealthPermission.getWritePermission(WeightRecord::class),
                HealthPermission.getReadPermission(HydrationRecord::class),
                HealthPermission.getWritePermission(HydrationRecord::class),
            )
        } else {
            mutableSetOf(
                HealthPermission.getReadPermission(MenstruationPeriodRecord::class),
                HealthPermission.getWritePermission(MenstruationPeriodRecord::class),
                HealthPermission.getReadPermission(MenstruationFlowRecord::class),
                HealthPermission.getWritePermission(MenstruationFlowRecord::class),
                HealthPermission.getReadPermission(IntermenstrualBleedingRecord::class),
                HealthPermission.getWritePermission(IntermenstrualBleedingRecord::class),
                HealthPermission.getReadPermission(OvulationTestRecord::class),
                HealthPermission.getWritePermission(OvulationTestRecord::class),
                HealthPermission.getReadPermission(CervicalMucusRecord::class),
                HealthPermission.getReadPermission(BasalBodyTemperatureRecord::class),
                HealthPermission.getWritePermission(BasalBodyTemperatureRecord::class),
            )
        }

        if (includeHistory && group != "wellness") {
            try {
                if (client.features.getFeatureStatus(
                        HealthConnectFeatures.FEATURE_READ_HEALTH_DATA_HISTORY,
                    ) == HealthConnectFeatures.FEATURE_STATUS_AVAILABLE
                ) {
                    permissions.add(HISTORY_PERMISSION)
                }
            } catch (_: Throwable) {
                // Older Health Connect providers still support the core records.
            }
        }
        return permissions
    }

    private suspend fun readData(
        group: String,
        start: Instant,
        end: Instant,
    ): Map<String, Any> {
        val records = mutableListOf<Map<String, Any?>>()
        val errors = mutableListOf<String>()
        if (group == "wellness") {
            readSafely("sleep", errors) {
                readAll<SleepSessionRecord>(start, end).forEach { item ->
                    records += base(item.metadata, "sleep") + mapOf(
                        "start" to item.startTime.toString(),
                        "end" to item.endTime.toString(),
                        "stages" to item.stages.map { stage ->
                            mapOf(
                                "start" to stage.startTime.toString(),
                                "end" to stage.endTime.toString(),
                                "stage" to stage.stage,
                            )
                        },
                    )
                }
            }
            readSafely("steps", errors) {
                readAll<StepsRecord>(start, end).forEach { item ->
                    records += base(item.metadata, "steps") + mapOf(
                        "start" to item.startTime.toString(),
                        "end" to item.endTime.toString(),
                        "count" to item.count,
                    )
                }
            }
            readSafely("exercise", errors) {
                readAll<ExerciseSessionRecord>(start, end).forEach { item ->
                    records += base(item.metadata, "exercise") + mapOf(
                        "start" to item.startTime.toString(),
                        "end" to item.endTime.toString(),
                        "exerciseType" to item.exerciseType,
                    )
                }
            }
            readSafely("restingHeartRate", errors) {
                readAll<RestingHeartRateRecord>(start, end).forEach { item ->
                    records += base(item.metadata, "restingHeartRate") + mapOf(
                        "time" to item.time.toString(),
                        "beatsPerMinute" to item.beatsPerMinute,
                    )
                }
            }
            readSafely("hrv", errors) {
                readAll<HeartRateVariabilityRmssdRecord>(start, end).forEach { item ->
                    records += base(item.metadata, "hrv") + mapOf(
                        "time" to item.time.toString(),
                        "milliseconds" to item.heartRateVariabilityMillis,
                    )
                }
            }
            readSafely("skinTemperature", errors) {
                readAll<SkinTemperatureRecord>(start, end).forEach { item ->
                    records += base(item.metadata, "skinTemperature") + mapOf(
                        "start" to item.startTime.toString(),
                        "end" to item.endTime.toString(),
                        "baselineCelsius" to item.baseline?.inCelsius,
                        "measurementLocation" to item.measurementLocation,
                        "deltas" to item.deltas.map { delta ->
                            mapOf(
                                "time" to delta.time.toString(),
                                "celsius" to delta.delta.inCelsius,
                            )
                        },
                    )
                }
            }
            readSafely("weight", errors) {
                readAll<WeightRecord>(start, end).forEach { item ->
                    records += base(item.metadata, "weight") + mapOf(
                        "time" to item.time.toString(),
                        "kilograms" to item.weight.inKilograms,
                    )
                }
            }
            readSafely("hydration", errors) {
                readAll<HydrationRecord>(start, end).forEach { item ->
                    records += base(item.metadata, "hydration") + mapOf(
                        "start" to item.startTime.toString(),
                        "end" to item.endTime.toString(),
                        "liters" to item.volume.inLiters,
                    )
                }
            }
        } else {
            readSafely("period", errors) {
                readAll<MenstruationPeriodRecord>(start, end).forEach { item ->
                    records += base(item.metadata, "period") + mapOf(
                        "start" to item.startTime.toString(),
                        "end" to item.endTime.toString(),
                    )
                }
            }
            readSafely("flow", errors) {
                readAll<MenstruationFlowRecord>(start, end).forEach { item ->
                    records += base(item.metadata, "flow") + mapOf(
                        "time" to item.time.toString(),
                        "flow" to item.flow,
                    )
                }
            }
            readSafely("intermenstrualBleeding", errors) {
                readAll<IntermenstrualBleedingRecord>(start, end).forEach { item ->
                    records += base(item.metadata, "intermenstrualBleeding") +
                        mapOf("time" to item.time.toString())
                }
            }
            readSafely("ovulationTest", errors) {
                readAll<OvulationTestRecord>(start, end).forEach { item ->
                    records += base(item.metadata, "ovulationTest") + mapOf(
                        "time" to item.time.toString(),
                        "result" to item.result,
                    )
                }
            }
            readSafely("cervicalMucus", errors) {
                readAll<CervicalMucusRecord>(start, end).forEach { item ->
                    records += base(item.metadata, "cervicalMucus") + mapOf(
                        "time" to item.time.toString(),
                        "appearance" to item.appearance,
                        "sensation" to item.sensation,
                    )
                }
            }
            readSafely("basalBodyTemperature", errors) {
                readAll<BasalBodyTemperatureRecord>(start, end).forEach { item ->
                    records += base(item.metadata, "basalBodyTemperature") + mapOf(
                        "time" to item.time.toString(),
                        "celsius" to item.temperature.inCelsius,
                        "measurementLocation" to item.measurementLocation,
                    )
                }
            }
        }
        return mapOf("records" to records, "errors" to errors)
    }

    private suspend inline fun <reified T : Record> readAll(
        start: Instant,
        end: Instant,
    ): List<T> {
        val output = mutableListOf<T>()
        var pageToken: String? = null
        do {
            val response = client.readRecords(
                ReadRecordsRequest<T>(
                    timeRangeFilter = TimeRangeFilter.between(start, end),
                    pageSize = 1000,
                    pageToken = pageToken,
                ),
            )
            output += response.records
            pageToken = response.pageToken
        } while (pageToken != null)
        return output
    }

    private suspend fun readSafely(
        type: String,
        errors: MutableList<String>,
        block: suspend () -> Unit,
    ) {
        try {
            block()
        } catch (error: Throwable) {
            errors += "$type:${error.javaClass.simpleName}"
        }
    }

    private fun base(metadata: Metadata, type: String): Map<String, Any?> = mapOf(
        "type" to type,
        "id" to metadata.id,
        "clientRecordId" to metadata.clientRecordId,
        "sourcePackage" to metadata.dataOrigin.packageName,
        "lastModified" to metadata.lastModifiedTime.toString(),
    )

    private suspend fun writeData(rawRecords: List<*>): Map<String, Any> {
        var written = 0
        val errors = mutableListOf<String>()
        rawRecords.forEachIndexed { index, raw ->
            val map = (raw as? Map<*, *>)?.entries?.associate {
                it.key.toString() to it.value
            } ?: return@forEachIndexed
            val record = try {
                toRecord(map)
            } catch (error: Throwable) {
                errors += "$index:${error.javaClass.simpleName}"
                null
            } ?: return@forEachIndexed

            try {
                client.insertRecords(listOf(record))
                written++
            } catch (error: Throwable) {
                errors += "$index:${error.javaClass.simpleName}"
            }
        }
        return mapOf("written" to written, "errors" to errors)
    }

    private fun toRecord(map: Map<String, Any?>): Record? {
        val type = map["type"]?.toString() ?: return null
        val clientId = map["clientRecordId"]?.toString()
            ?.takeIf(String::isNotBlank) ?: return null
        val metadata = Metadata.manualEntry(
            clientRecordId = clientId,
            clientRecordVersion = 1,
        )

        return when (type) {
            "period" -> {
                val start = parseInstant(map["start"]?.toString())
                val end = parseInstant(map["end"]?.toString())
                MenstruationPeriodRecord(
                    startTime = start,
                    startZoneOffset = zoneOffset(start),
                    endTime = end,
                    endZoneOffset = zoneOffset(end),
                    metadata = metadata,
                )
            }
            "flow" -> {
                val time = parseInstant(map["time"]?.toString())
                MenstruationFlowRecord(
                    time = time,
                    zoneOffset = zoneOffset(time),
                    metadata = metadata,
                    flow = (map["flow"] as? Number)?.toInt() ?: 0,
                )
            }
            "intermenstrualBleeding" -> {
                val time = parseInstant(map["time"]?.toString())
                IntermenstrualBleedingRecord(time, zoneOffset(time), metadata)
            }
            "ovulationTest" -> {
                val time = parseInstant(map["time"]?.toString())
                OvulationTestRecord(
                    time = time,
                    zoneOffset = zoneOffset(time),
                    result = (map["result"] as? Number)?.toInt() ?: 0,
                    metadata = metadata,
                )
            }
            "basalBodyTemperature" -> {
                val time = parseInstant(map["time"]?.toString())
                BasalBodyTemperatureRecord(
                    time = time,
                    zoneOffset = zoneOffset(time),
                    metadata = metadata,
                    temperature = Temperature.celsius(
                        (map["celsius"] as? Number)?.toDouble() ?: return null,
                    ),
                    measurementLocation =
                        0,
                )
            }
            "sleep" -> {
                val start = parseInstant(map["start"]?.toString())
                val end = parseInstant(map["end"]?.toString())
                SleepSessionRecord(
                    startTime = start,
                    startZoneOffset = zoneOffset(start),
                    endTime = end,
                    endZoneOffset = zoneOffset(end),
                    metadata = metadata,
                    title = "Lune",
                    stages = emptyList(),
                )
            }
            "weight" -> {
                val time = parseInstant(map["time"]?.toString())
                WeightRecord(
                    time = time,
                    zoneOffset = zoneOffset(time),
                    weight = Mass.kilograms(
                        (map["kilograms"] as? Number)?.toDouble() ?: return null,
                    ),
                    metadata = metadata,
                )
            }
            "hydration" -> {
                val start = parseInstant(map["start"]?.toString())
                val end = parseInstant(map["end"]?.toString())
                HydrationRecord(
                    startTime = start,
                    startZoneOffset = zoneOffset(start),
                    endTime = end,
                    endZoneOffset = zoneOffset(end),
                    volume = Volume.liters(
                        (map["liters"] as? Number)?.toDouble() ?: return null,
                    ),
                    metadata = metadata,
                )
            }
            else -> null
        }
    }

    private fun parseInstant(raw: String?): Instant =
        raw?.let(Instant::parse) ?: throw IllegalArgumentException("Missing time")

    private fun zoneOffset(time: Instant) =
        time.atZone(ZoneId.systemDefault()).offset

    private fun openSettings(): Boolean {
        val candidates = listOf(
            Intent("android.health.connect.action.HEALTH_HOME_SETTINGS"),
            Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS").setPackage(PROVIDER),
            activity.packageManager.getLaunchIntentForPackage(PROVIDER),
        )
        val intent = candidates.firstOrNull {
            it != null && it.resolveActivity(activity.packageManager) != null
        } ?: return false
        activity.startActivity(intent)
        return true
    }
}
