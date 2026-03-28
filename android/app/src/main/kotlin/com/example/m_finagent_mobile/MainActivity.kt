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

class MainActivity : FlutterActivity() {
	private val methodChannelName = "m_finagent_mobile/sms_method"
	private val eventChannelName = "m_finagent_mobile/sms_events"
	private val permissionRequestCode = 2026

	private var pendingPermissionResult: MethodChannel.Result? = null
	private var smsReceiver: BroadcastReceiver? = null
	private var sink: EventChannel.EventSink? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"requestPermissions" -> requestSmsPermissions(result)
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

	private fun requestSmsPermissions(result: MethodChannel.Result) {
		val requiredPermissions = mutableListOf(
			Manifest.permission.RECEIVE_SMS,
			Manifest.permission.READ_SMS,
		)

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
			requiredPermissions.add(Manifest.permission.POST_NOTIFICATIONS)
		}

		val denied = requiredPermissions.filter {
			ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
		}

		if (denied.isEmpty()) {
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

		if (requestCode != permissionRequestCode) {
			return
		}

		val granted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
		pendingPermissionResult?.success(granted)
		pendingPermissionResult = null
	}

	private fun registerSmsReceiver() {
		if (smsReceiver != null) {
			return
		}

		smsReceiver = object : BroadcastReceiver() {
			override fun onReceive(context: Context?, intent: Intent?) {
				if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
					return
				}

				val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
				if (messages.isEmpty()) {
					return
				}

				val body = messages.joinToString(separator = "") { it.messageBody ?: "" }
				val address = messages.firstOrNull()?.displayOriginatingAddress.orEmpty()

				sink?.success(
					mapOf(
						"address" to address,
						"body" to body,
					),
				)
			}
		}

		val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
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
