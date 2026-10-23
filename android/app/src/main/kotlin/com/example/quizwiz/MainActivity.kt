package com.example.quizwiz

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "quizwiz/export_storage"
    private val writePermissionRequest = 7412
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasExportAccess" -> result.success(hasExportAccess())
                    "requestExportAccess" -> requestExportAccess(result)
                    "getExportDirectory" -> {
                        if (!hasExportAccess()) {
                            result.success(null)
                        } else {
                            val directory = java.io.File(
                                Environment.getExternalStorageDirectory(),
                                "QuizWiz"
                            )
                            if (directory.exists() || directory.mkdirs()) {
                                result.success(directory.absolutePath)
                            } else {
                                result.error("DIRECTORY_ERROR", "Không thể tạo thư mục QuizWiz", null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasExportAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun requestExportAccess(result: MethodChannel.Result) {
        if (hasExportAccess()) {
            result.success(true)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent = Intent(
                    Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivity(intent)
            } catch (_: Exception) {
                startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
            }
            // Android does not return a result from this settings page. Flutter
            // checks the permission again when the app resumes.
            result.success(false)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            pendingPermissionResult = result
            requestPermissions(
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                writePermissionRequest
            )
            return
        }
        result.success(true)
    }

    @Deprecated("Deprecated in Android")
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == writePermissionRequest) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }
}
