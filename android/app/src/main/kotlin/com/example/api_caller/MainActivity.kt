package com.example.api_caller // Upewnij się, że ta ścieżka odpowiada Twojemu pakietowi

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.phone/call"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "callPhone") {
                val phoneNumber = call.arguments<String>()
                makePhoneCall(phoneNumber)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun makePhoneCall(phoneNumber: String?) {
        if (phoneNumber.isNullOrEmpty()) {
            // Sprawdź, czy numer telefonu nie jest null ani pusty
            println("Numer telefonu jest pusty lub null")
            return
        }

        val intent = Intent(Intent.ACTION_CALL)
        intent.data = Uri.parse("tel:$phoneNumber")

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            // Jeśli uprawnienia nie zostały przyznane, poproś o nie
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CALL_PHONE), 1)
            return
        }

        startActivity(intent) // Inicjuj połączenie
    }

}
