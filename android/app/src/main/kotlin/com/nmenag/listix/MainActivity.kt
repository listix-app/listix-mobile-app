package com.nmenag.listix

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.nmenag.listix/native_file_system"
    private var pendingResult: MethodChannel.Result? = null
    private var pendingSaveContent: String? = null

    companion object {
        private const val REQUEST_CODE_OPEN = 1001
        private const val REQUEST_CODE_SAVE = 1002
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "openFile" -> {
                    pendingResult = result
                    try {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                            putExtra(
                                Intent.EXTRA_MIME_TYPES,
                                arrayOf("application/json", "text/csv", "text/plain", "application/octet-stream", "*/*")
                            )
                        }
                        startActivityForResult(intent, REQUEST_CODE_OPEN)
                    } catch (e: Exception) {
                        pendingResult = null
                        result.error("OPEN_INTENT_ERROR", e.message, null)
                    }
                }
                "saveFile" -> {
                    pendingResult = result
                    pendingSaveContent = call.argument<String>("content") ?: ""
                    val fileName = call.argument<String>("fileName") ?: "listix_backup.json"
                    val mimeType = call.argument<String>("mimeType") ?: "application/json"
                    try {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = mimeType
                            putExtra(Intent.EXTRA_TITLE, fileName)
                        }
                        startActivityForResult(intent, REQUEST_CODE_SAVE)
                    } catch (e: Exception) {
                        pendingResult = null
                        pendingSaveContent = null
                        result.error("SAVE_INTENT_ERROR", e.message, null)
                    }
                }
                "isAndroid" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val channelResult = pendingResult ?: return
        pendingResult = null

        when (requestCode) {
            REQUEST_CODE_OPEN -> {
                if (resultCode == Activity.RESULT_OK && data?.data != null) {
                    val uri: Uri = data.data!!
                    try {
                        val content = contentResolver.openInputStream(uri)?.bufferedReader(Charsets.UTF_8)?.use { it.readText() } ?: ""
                        val name = getFileName(uri) ?: "backup.json"
                        channelResult.success(
                            mapOf(
                                "name" to name,
                                "content" to content,
                                "uri" to uri.toString()
                            )
                        )
                    } catch (e: Exception) {
                        channelResult.error("READ_ERROR", e.message, null)
                    }
                } else {
                    channelResult.success(null)
                }
            }
            REQUEST_CODE_SAVE -> {
                val contentToWrite = pendingSaveContent
                pendingSaveContent = null
                if (resultCode == Activity.RESULT_OK && data?.data != null) {
                    val uri: Uri = data.data!!
                    try {
                        contentResolver.openOutputStream(uri)?.use { stream ->
                            stream.write(contentToWrite?.toByteArray(Charsets.UTF_8) ?: ByteArray(0))
                        }
                        val name = getFileName(uri) ?: "backup.json"
                        channelResult.success(
                            mapOf(
                                "success" to true,
                                "name" to name,
                                "uri" to uri.toString()
                            )
                        )
                    } catch (e: Exception) {
                        channelResult.error("WRITE_ERROR", e.message, null)
                    }
                } else {
                    channelResult.success(null)
                }
            }
        }
    }

    private fun getFileName(uri: Uri): String? {
        var name: String? = null
        if (uri.scheme == "content") {
            val cursor = contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val index = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index >= 0) {
                        name = it.getString(index)
                    }
                }
            }
        }
        if (name == null) {
            name = uri.path?.let { path ->
                val cut = path.lastIndexOf('/')
                if (cut != -1) path.substring(cut + 1) else path
            }
        }
        return name
    }
}
