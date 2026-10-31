package com.fithost.fit_host

import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.fithost.fit_host/lockscreen"
    private var lockScreenMethodChannel: MethodChannel? = null
    private var launchAlarmPayload: String? = null
    private var isAlarmActive: Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        lockScreenMethodChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialAlarmPayload" -> {
                    val p = launchAlarmPayload
                    launchAlarmPayload = null
                    result.success(p)
                }
                "isDeviceLocked" -> {
                    val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                    val isLocked = keyguardManager?.isKeyguardLocked ?: false
                    result.success(isLocked)
                }
                "enableLockScreenOverlay" -> {
                    isAlarmActive = true
                    setLockScreenOverlay(true)
                    result.success(true)
                }
                "disableLockScreenOverlay" -> {
                    isAlarmActive = false
                    setLockScreenOverlay(false)
                    result.success(true)
                }
                "closeAlarmToLockScreen" -> {
                    isAlarmActive = false
                    setLockScreenOverlay(false)
                    val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                    val isLocked = keyguardManager?.isKeyguardLocked ?: false
                    if (isLocked) {
                        moveTaskToBack(true)
                    }
                    result.success(true)
                }
                "dismissKeyguardAndProceed" -> {
                    val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                    if (keyguardManager != null && keyguardManager.isKeyguardLocked) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            keyguardManager.requestDismissKeyguard(this, object : KeyguardManager.KeyguardDismissCallback() {
                                override fun onDismissSucceeded() {
                                    super.onDismissSucceeded()
                                    isAlarmActive = false
                                    setLockScreenOverlay(false)
                                    result.success(true)
                                }
                                override fun onDismissCancelled() {
                                    super.onDismissCancelled()
                                    result.success(false)
                                }
                                override fun onDismissError() {
                                    super.onDismissError()
                                    result.success(false)
                                }
                            })
                        } else {
                            isAlarmActive = false
                            setLockScreenOverlay(false)
                            result.success(true)
                        }
                    } else {
                        isAlarmActive = false
                        setLockScreenOverlay(false)
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleLockScreenIntent(intent)
        val p = extractAlarmPayload(intent)
        if (p != null) {
            launchAlarmPayload = p
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleLockScreenIntent(intent)
        val payload = extractAlarmPayload(intent)
        if (payload != null && payload.isNotEmpty()) {
            lockScreenMethodChannel?.invokeMethod("onAlarmIntentPayload", payload)
        }
    }

    override fun onStop() {
        super.onStop()
        isAlarmActive = false
        setLockScreenOverlay(false)
    }

    private fun handleLockScreenIntent(intent: Intent?) {
        if (isAlarmIntent(intent)) {
            isAlarmActive = true
            setLockScreenOverlay(true)
        } else {
            // For normal app launches or standard notifications, ensure lockscreen overlay is OFF!
            isAlarmActive = false
            setLockScreenOverlay(false)
        }
    }

    private fun extractAlarmPayload(intent: Intent?): String? {
        if (intent == null) return null
        val payload = intent.getStringExtra("payload")
        if (payload != null && payload.contains("/alarm")) return payload
        val extras = intent.extras ?: return null
        for (key in extras.keySet()) {
            val value = extras.get(key)
            if (value is String && value.contains("/alarm")) {
                return value
            }
            if (value is Bundle) {
                for (subKey in value.keySet()) {
                    val subValue = value.get(subKey)
                    if (subValue is String && subValue.contains("/alarm")) {
                        return subValue
                    }
                }
            }
        }
        return null
    }

    private fun isAlarmIntent(intent: Intent?): Boolean {
        if (intent == null) return false
        val action = intent.action
        if (action != null && action.contains("ALARM", ignoreCase = true)) return true
        return extractAlarmPayload(intent) != null
    }

    private fun setLockScreenOverlay(enable: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(enable)
            setTurnScreenOn(enable)
        }
        if (enable) {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        } else {
            window.clearFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }
}
