package com.checkscan.app

import android.content.ClipboardManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "checkscan/clipboard")
            .setMethodCallHandler { call, result ->
                if (call.method == "getClip") {
                    result.success(readPrimaryClip())
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun readPrimaryClip(): Map<String, String?> {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip
        if (clip == null || clip.itemCount == 0) {
            return mapOf("plain" to "", "html" to null)
        }
        val item = clip.getItemAt(0)
        return mapOf(
            "plain" to (item.text?.toString() ?: ""),
            "html" to item.htmlText,
        )
    }
}
