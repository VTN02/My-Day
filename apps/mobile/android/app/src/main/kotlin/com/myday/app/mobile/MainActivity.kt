package com.myday.app.mobile

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.myday.app/installer"
    private val DOC_CHANNEL = "com.myday.app/document_viewer"
    private var documentMethodChannel: MethodChannel? = null
    private var pendingDocumentMap: Map<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        documentMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOC_CHANNEL)
        documentMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialDocument" -> {
                    val map = pendingDocumentMap
                    pendingDocumentMap = null
                    result.success(map)
                }
                "openFile" -> {
                    val filePath = call.argument<String>("filePath")
                    val mimeType = call.argument<String>("mimeType") ?: "*/*"
                    val title = call.argument<String>("title") ?: "Open Document"
                    if (filePath != null) {
                        val res = openFileExternally(filePath, mimeType, title)
                        result.success(res)
                    } else {
                        result.error("INVALID_PATH", "File path was null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Check if cold-started with an ACTION_VIEW document intent
        val initialDoc = processViewIntent(intent)
        if (initialDoc != null) {
            pendingDocumentMap = initialDoc
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppVersion" -> {
                    try {
                        val pInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
                        } else {
                            @Suppress("DEPRECATION")
                            packageManager.getPackageInfo(packageName, 0)
                        }
                        val longVersionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            pInfo.longVersionCode
                        } else {
                            @Suppress("DEPRECATION")
                            pInfo.versionCode.toLong()
                        }
                        result.success(mapOf(
                            "versionName" to (pInfo.versionName ?: "1.2.0"),
                            "versionCode" to longVersionCode.toInt()
                        ))
                    } catch (e: Exception) {
                        result.error("VERSION_ERROR", e.message, null)
                    }
                }
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        val success = installApk(filePath)
                        result.success(success)
                    } else {
                        result.error("INVALID_PATH", "File path was null", null)
                    }
                }
                "canInstallUnknownPackages" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        result.success(packageManager.canRequestPackageInstalls())
                    } else {
                        result.success(true)
                    }
                }
                "openInstallPermissionSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                            data = Uri.parse("package:$packageName")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } else {
                        result.success(true)
                    }
                }
                "shareFile" -> {
                    val filePath = call.argument<String>("filePath")
                    val mimeType = call.argument<String>("mimeType") ?: "application/pdf"
                    val title = call.argument<String>("title") ?: "Share Statement"
                    if (filePath != null) {
                        val success = shareFile(filePath, mimeType, title)
                        result.success(success)
                    } else {
                        result.error("INVALID_PATH", "File path was null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun installApk(filePath: String): Boolean {
        val file = File(filePath)
        if (!file.exists()) return false

        // On Android 8.0+, check if app is permitted to install packages
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (!packageManager.canRequestPackageInstalls()) {
                val permissionIntent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                    data = Uri.parse("package:$packageName")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(permissionIntent)
                return false
            }
        }

        return try {
            val apkUri = FileProvider.getUriForFile(
                applicationContext,
                "$packageName.fileprovider",
                file
            )

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }

            startActivity(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun getAccessibleFile(filePath: String): File? {
        val file = File(filePath)
        if (!file.exists()) return null

        return try {
            if (filePath.startsWith(cacheDir.absolutePath)) {
                file
            } else {
                val cacheDocsDir = File(cacheDir, "shared_documents")
                if (!cacheDocsDir.exists()) cacheDocsDir.mkdirs()
                val destFile = File(cacheDocsDir, file.name)
                file.copyTo(destFile, overwrite = true)
                destFile
            }
        } catch (e: Exception) {
            e.printStackTrace()
            file
        }
    }

    private fun shareFile(filePath: String, mimeType: String, title: String): Boolean {
        val targetFile = getAccessibleFile(filePath) ?: return false

        return try {
            val uri = FileProvider.getUriForFile(
                applicationContext,
                "$packageName.fileprovider",
                targetFile
            )

            val intent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, uri)
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
            }

            val chooser = Intent.createChooser(intent, title).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }

            startActivity(chooser)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun openFileExternally(filePath: String, mimeType: String, title: String): Map<String, Any> {
        val targetFile = getAccessibleFile(filePath)
            ?: return mapOf("success" to false, "error" to "FILE_NOT_FOUND")

        return try {
            val uri = FileProvider.getUriForFile(
                applicationContext,
                "$packageName.fileprovider",
                targetFile
            )

            val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            val chooser = Intent.createChooser(viewIntent, title).apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            startActivity(chooser)
            mapOf("success" to true)
        } catch (e: Exception) {
            e.printStackTrace()
            mapOf("success" to false, "error" to (e.message ?: "UNKNOWN_ERROR"))
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val docMap = processViewIntent(intent)
        if (docMap != null) {
            documentMethodChannel?.invokeMethod("onDocumentOpened", docMap)
        }
    }

    private fun processViewIntent(viewIntent: Intent?): Map<String, String>? {
        if (viewIntent == null || viewIntent.action != Intent.ACTION_VIEW) return null
        val uri = viewIntent.data ?: return null

        return try {
            var displayName = "document"
            val mimeType = viewIntent.type ?: contentResolver.getType(uri) ?: "application/octet-stream"

            if (uri.scheme == "content") {
                contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (nameIndex != -1 && cursor.moveToFirst()) {
                        displayName = cursor.getString(nameIndex)
                    }
                }
            } else if (uri.scheme == "file") {
                displayName = uri.lastPathSegment ?: "document"
            }

            // Copy safely into internal app cache
            val cacheDocsDir = File(cacheDir, "external_documents")
            if (!cacheDocsDir.exists()) {
                cacheDocsDir.mkdirs()
            }

            val sanitizedName = displayName.replace(Regex("[^a-zA-Z0-9._-]"), "_")
            val targetFile = File(cacheDocsDir, "${System.currentTimeMillis()}_$sanitizedName")

            contentResolver.openInputStream(uri)?.use { inputStream ->
                FileOutputStream(targetFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }

            mapOf(
                "filePath" to targetFile.absolutePath,
                "fileName" to displayName,
                "mimeType" to mimeType
            )
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
