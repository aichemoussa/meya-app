package app.meya.messenger

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Shares text (an invite link) through the phone's share sheet:
        // WhatsApp, Telegram, Gmail, SMS and so on.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "meya/share")
            .setMethodCallHandler { call, result ->
                if (call.method != "shareText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val text = call.argument<String>("text")
                if (text.isNullOrEmpty()) {
                    result.error("empty", "Nothing to share", null)
                    return@setMethodCallHandler
                }
                val send = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, text)
                }
                startActivity(Intent.createChooser(send, call.argument<String>("title")))
                result.success(null)
            }

        // Battery optimisation: whether MEYA is exempt, and Android's own
        // dialog to exempt it (the person decides there).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "meya/battery")
            .setMethodCallHandler { call, result ->
                val power = getSystemService(Context.POWER_SERVICE) as PowerManager
                when (call.method) {
                    "isExempt" -> result.success(power.isIgnoringBatteryOptimizations(packageName))
                    "requestExemption" -> {
                        try {
                            startActivity(
                                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                                    .setData(Uri.parse("package:$packageName")),
                            )
                            result.success(true)
                        } catch (error: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
