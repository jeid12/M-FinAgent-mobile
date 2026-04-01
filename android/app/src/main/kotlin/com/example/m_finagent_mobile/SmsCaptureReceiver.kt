package com.mfinagent.mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import org.json.JSONArray
import org.json.JSONObject

class SmsCaptureReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isEmpty()) return

        val body = messages.joinToString(separator = "") { it.messageBody ?: "" }
        if (body.isBlank()) return

        val address = messages.firstOrNull()?.displayOriginatingAddress.orEmpty()
        val timestamp = messages.firstOrNull()?.timestampMillis ?: System.currentTimeMillis()

        val prefs = context.getSharedPreferences("m_finagent_mobile_sms", Context.MODE_PRIVATE)
        val key = "captured_sms_queue"
        val raw = prefs.getString(key, "[]") ?: "[]"

        val queue = try {
            JSONArray(raw)
        } catch (_: Exception) {
            JSONArray()
        }

        // Append new event; keep bounded queue size.
        val item = JSONObject().apply {
            put("address", address)
            put("body", body)
            put("timestamp", timestamp)
        }
        queue.put(item)

        val maxItems = 500
        val trimmed = JSONArray()
        val start = if (queue.length() > maxItems) queue.length() - maxItems else 0
        for (i in start until queue.length()) {
            trimmed.put(queue.get(i))
        }

        prefs.edit().putString(key, trimmed.toString()).apply()
    }
}
