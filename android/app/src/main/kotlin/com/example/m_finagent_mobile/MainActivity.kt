package com.example.m_finagent_mobile

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Telephony
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {
    private val methodChannelName = "m_finagent_mobile/sms_method"
    private val eventChannelName  = "m_finagent_mobile/sms_events"
    private val permissionRequestCode = 2026
    private val smsPrefsName = "m_finagent_mobile_sms"
    private val smsQueueKey = "captured_sms_queue"

    private var pendingPermissionResult: MethodChannel.Result? = null
    private var smsReceiver: BroadcastReceiver? = null
    private var sink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermissions"  -> requestSmsPermissions(result)
                    "fetchHistoricalSms"  -> {
                        val maxMessages = call.argument<Int>("maxMessages") ?: 200
                        fetchHistoricalSms(maxMessages, result)
                    }
                    "fetchCapturedSmsQueue" -> fetchCapturedSmsQueue(result)
                    "clearCapturedSmsQueue" -> clearCapturedSmsQueue(result)
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        sink = events
                        registerSmsReceiver()
                    }
                    override fun onCancel(arguments: Any?) {
                        sink = null
                        unregisterSmsReceiver()
                    }
                },
            )
    }

    // -------------------------------------------------------------------------
    // Permission handling
    // -------------------------------------------------------------------------

    private fun requestSmsPermissions(result: MethodChannel.Result) {
        val smsPermissions = listOf(
            Manifest.permission.RECEIVE_SMS,
            Manifest.permission.READ_SMS,
        )

        val denied = smsPermissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (denied.isEmpty()) {
            // Notification permission is optional for SMS capture.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                    != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    permissionRequestCode + 1,
                )
            }
            result.success(true)
            return
        }

        pendingPermissionResult = result
        ActivityCompat.requestPermissions(this, denied.toTypedArray(), permissionRequestCode)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != permissionRequestCode) return
        val granted = permissions
            .zip(grantResults.toTypedArray())
            .filter { (permission, _) ->
                permission == Manifest.permission.RECEIVE_SMS ||
                    permission == Manifest.permission.READ_SMS
            }
            .all { (_, grantResult) -> grantResult == PackageManager.PERMISSION_GRANTED }
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }

    // -------------------------------------------------------------------------
    // Historical SMS — reads the inbox via ContentResolver
    // -------------------------------------------------------------------------

    /**
     * Reads up to [maxMessages] SMS from the device inbox (most recent first)
     * and returns them as a List<Map<String, Any>> with keys:
     *   - address   : sender phone / shortcode
     *   - body      : full message text
     *   - timestamp : epoch milliseconds (UTC)
     *
     * Only messages from the last 180 days are included to avoid flooding
     * the backend on first login.
     */
    private fun fetchHistoricalSms(maxMessages: Int, result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS)
                != PackageManager.PERMISSION_GRANTED) {
            result.success(emptyList<Map<String, Any>>())
            return
        }

        val cutoffMs = System.currentTimeMillis() - 180L * 24 * 60 * 60 * 1000 // 180 days

        val projection = arrayOf(
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
        )

        val cursor = contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            projection,
            "${Telephony.Sms.DATE} >= ?",
            arrayOf(cutoffMs.toString()),
            "${Telephony.Sms.DATE} DESC",  // newest first
        )

        val messages = mutableListOf<Map<String, Any>>()

        cursor?.use { c ->
            val addressIdx   = c.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
            val bodyIdx      = c.getColumnIndexOrThrow(Telephony.Sms.BODY)
            val timestampIdx = c.getColumnIndexOrThrow(Telephony.Sms.DATE)

            while (c.moveToNext() && messages.size < maxMessages) {
                val address   = c.getString(addressIdx).orEmpty()
                val body      = c.getString(bodyIdx).orEmpty()
                val timestamp = c.getLong(timestampIdx)

                if (body.isBlank()) continue  // skip empty rows

                messages.add(
                    mapOf(
                        "address"   to address,
                        "body"      to body,
                        "timestamp" to timestamp,
                    )
                )
            }
        }

        result.success(messages)
    }

    private fun fetchCapturedSmsQueue(result: MethodChannel.Result) {
        val prefs = getSharedPreferences(smsPrefsName, Context.MODE_PRIVATE)
        val raw = prefs.getString(smsQueueKey, "[]") ?: "[]"
        val queue = try {
            JSONArray(raw)
        } catch (_: Exception) {
            JSONArray()
        }

        val messages = mutableListOf<Map<String, Any>>()
        for (i in 0 until queue.length()) {
            val item = queue.optJSONObject(i) ?: continue
            val body = item.optString("body", "")
            if (body.isBlank()) continue
            messages.add(
                mapOf(
                    "address" to item.optString("address", ""),
                    "body" to body,
                    "timestamp" to item.optLong("timestamp", System.currentTimeMillis()),
                )
            )
        }
        result.success(messages)
    }

    private fun clearCapturedSmsQueue(result: MethodChannel.Result) {
        val prefs = getSharedPreferences(smsPrefsName, Context.MODE_PRIVATE)
        prefs.edit().putString(smsQueueKey, "[]").apply()
        result.success(true)
    }

    // -------------------------------------------------------------------------
    // Real-time incoming SMS broadcast receiver
    // -------------------------------------------------------------------------

    private fun registerSmsReceiver() {
        if (smsReceiver != null) return

        smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

                val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
                if (messages.isEmpty()) return

                val body      = messages.joinToString(separator = "") { it.messageBody ?: "" }
                val address   = messages.firstOrNull()?.displayOriginatingAddress.orEmpty()
                val timestamp = messages.firstOrNull()?.timestampMillis
                               ?: System.currentTimeMillis()

                sink?.success(
                    mapOf(
                        "address"   to address,
                        "body"      to body,
                        "timestamp" to timestamp,
                    )
                )
            }
        }

        val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION).apply {
            // Higher priority than the default SMS app so we see every message
            priority = IntentFilter.SYSTEM_HIGH_PRIORITY - 1
        }
        registerReceiver(smsReceiver, filter)
    }

    private fun unregisterSmsReceiver() {
        val receiver = smsReceiver ?: return
        unregisterReceiver(receiver)
        smsReceiver = null
    }

    override fun onDestroy() {
        unregisterSmsReceiver()
        super.onDestroy()
    }
}
