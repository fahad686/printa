package com.example.printa

import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import com.sunmi.peripheral.printer.InnerPrinterCallback
import com.sunmi.peripheral.printer.InnerPrinterManager
import com.sunmi.peripheral.printer.SunmiPrinterService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val TAG = "SUNMI_LOG"

    private val PRINTER_CHANNEL = "com.sunmi.hardware/printer"
    private val SCANNER_CHANNEL = "com.sunmi.hardware/scanner"
    private val DEVICE_CHANNEL = "com.sunmi.hardware/device"

    private var printerService: SunmiPrinterService? = null

    private val printerCallback = object : InnerPrinterCallback() {
        override fun onConnected(service: SunmiPrinterService) {
            Log.d(TAG, "🟢 [InnerPrinterCallback] Connected to SunmiPrinterService")
            printerService = service
            try {
                service.printerInit(null)
                Log.d(TAG, "Printer initialized. Serial: ${service.printerSerialNo}, Version: ${service.printerVersion}")
            } catch (e: Exception) {
                Log.e(TAG, "Error during printerInit: ${e.message}", e)
            }
        }

        override fun onDisconnected() {
            Log.w(TAG, "🔴 [InnerPrinterCallback] SunmiPrinterService disconnected")
            printerService = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "🚀 [onCreate] Initializing MainActivity on ${Build.MANUFACTURER} ${Build.MODEL} (Android ${Build.VERSION.RELEASE})")
        bindPrinterService()
    }

    private fun bindPrinterService() {
        try {
            val requested = InnerPrinterManager.getInstance().bindService(this, printerCallback)
            Log.d(TAG, "[bindPrinterService] bind requested -> $requested")
        } catch (e: Exception) {
            Log.e(TAG, "🔴 [bindPrinterService] Failed: ${e.message}", e)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            InnerPrinterManager.getInstance().unBindService(this, printerCallback)
            Log.d(TAG, "Unbound SunmiPrinterService.")
        } catch (e: Exception) {
            Log.e(TAG, "Error unbinding service: ${e.message}")
        }
    }

    /**
     * Runs [block] against the connected printer service.
     * Returns false (and triggers a rebind) when the service is not connected.
     */
    private fun withPrinter(methodName: String, block: (SunmiPrinterService) -> Unit): Boolean {
        val svc = printerService
        if (svc == null) {
            Log.w(TAG, "⚠️ Printer service not connected for '$methodName'. Triggering rebind...")
            bindPrinterService()
            return false
        }
        return try {
            block(svc)
            true
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error executing '$methodName': ${e.message}", e)
            false
        }
    }

    private fun printerStateString(state: Int): String = when (state) {
        1 -> "READY"
        2 -> "PREPARING"
        3 -> "COMM_ERROR"
        4 -> "OUT_OF_PAPER"
        5 -> "OVERHEATED"
        6 -> "COVER_OPEN"
        7 -> "CUTTER_ERROR"
        8 -> "CUTTER_RECOVERED"
        9 -> "NO_BLACK_MARK"
        505 -> "NO_PRINTER"
        507 -> "FIRMWARE_UPDATE_FAILED"
        else -> "UNKNOWN($state)"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Printer Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRINTER_CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "📥 [MethodChannel] Received call: ${call.method}")
            when (call.method) {
                "isSunmiDevice" -> {
                    val isSunmi = Build.MANUFACTURER.contains("SUNMI", ignoreCase = true) || Build.MODEL.contains("SUNMI", ignoreCase = true)
                    Log.d(TAG, "isSunmiDevice check -> Manufacturer: ${Build.MANUFACTURER}, Model: ${Build.MODEL} => $isSunmi")
                    result.success(isSunmi)
                }
                "getPrinterStatus" -> {
                    val svc = printerService
                    val statusStr = if (svc == null) {
                        bindPrinterService()
                        "SERVICE_NOT_BOUND"
                    } else {
                        try {
                            printerStateString(svc.updatePrinterState())
                        } catch (e: Exception) {
                            Log.e(TAG, "Error reading printer state: ${e.message}")
                            "COMM_ERROR"
                        }
                    }
                    Log.d(TAG, "getPrinterStatus -> $statusStr")
                    result.success(statusStr)
                }
                "getPaperStatus" -> {
                    val state = try {
                        printerService?.updatePrinterState() ?: -1
                    } catch (e: Exception) {
                        -1
                    }
                    result.success(if (state == 4) "OUT_OF_PAPER" else "NORMAL")
                }
                "getPrinterWidth" -> {
                    val width = try {
                        // getPrinterPaper: 1 = 58mm, 2 = 80mm
                        if (printerService?.getPrinterPaper() == 2) 80 else 58
                    } catch (e: Exception) {
                        58
                    }
                    result.success(width)
                }
                "printText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val align = call.argument<Int>("align") ?: 0
                    val isBold = call.argument<Boolean>("isBold") ?: false
                    val isUnderline = call.argument<Boolean>("isUnderline") ?: false
                    val fontSize = (call.argument<Int>("fontSize") ?: 24).toFloat()

                    Log.d(TAG, "printText: align=$align, bold=$isBold, fontSize=$fontSize, text='$text'")
                    val ok = withPrinter("printText") { svc ->
                        svc.setAlignment(align, null)
                        svc.setFontSize(fontSize, null)
                        // ESC E n -> bold, ESC - n -> underline
                        svc.sendRAWData(byteArrayOf(0x1B, 0x45, (if (isBold) 1 else 0).toByte()), null)
                        svc.sendRAWData(byteArrayOf(0x1B, 0x2D, (if (isUnderline) 1 else 0).toByte()), null)
                        svc.printText(if (text.endsWith("\n")) text else "$text\n", null)
                        // Reset styles so they don't leak into the next call
                        svc.sendRAWData(byteArrayOf(0x1B, 0x45, 0), null)
                        svc.sendRAWData(byteArrayOf(0x1B, 0x2D, 0), null)
                    }
                    result.success(ok)
                }
                "printTable" -> {
                    val colsText = (call.argument<List<String>>("colsText") ?: emptyList()).toTypedArray()
                    val colsWidth = (call.argument<List<Int>>("colsWidth") ?: emptyList()).toIntArray()
                    val colsAlign = (call.argument<List<Int>>("colsAlign") ?: emptyList()).toIntArray()

                    Log.d(TAG, "printTable: colsText=${colsText.joinToString()}, colsWidth=${colsWidth.joinToString()}")
                    val ok = withPrinter("printTable") { svc ->
                        svc.printColumnsText(colsText, colsWidth, colsAlign, null)
                    }
                    result.success(ok)
                }
                "printQRCode" -> {
                    val data = call.argument<String>("data") ?: ""
                    val size = call.argument<Int>("size") ?: 6
                    Log.d(TAG, "printQRCode: size=$size, data='$data'")
                    val ok = withPrinter("printQRCode") { svc ->
                        svc.setAlignment(1, null)
                        // modulesize must be 4..16, errorlevel 0..3
                        svc.printQRCode(data, size.coerceIn(4, 16), 3, null)
                        svc.lineWrap(1, null)
                    }
                    result.success(ok)
                }
                "printBarCode" -> {
                    val data = call.argument<String>("data") ?: ""
                    val symbology = call.argument<Int>("symbology") ?: 8
                    val height = call.argument<Int>("height") ?: 100
                    val width = call.argument<Int>("width") ?: 2
                    Log.d(TAG, "printBarCode: symbology=$symbology, data='$data'")
                    val ok = withPrinter("printBarCode") { svc ->
                        svc.setAlignment(1, null)
                        svc.printBarCode(data, symbology, height, width, 2, null)
                        svc.lineWrap(1, null)
                    }
                    result.success(ok)
                }
                "feedPaper" -> {
                    val lines = call.argument<Int>("lines") ?: 3
                    Log.d(TAG, "feedPaper: lines=$lines")
                    val ok = withPrinter("feedPaper") { svc ->
                        svc.lineWrap(lines, null)
                    }
                    result.success(ok)
                }
                "cutPaper" -> {
                    Log.d(TAG, "cutPaper requested")
                    // Handheld devices (like V3) have no cutter; this fails gracefully.
                    val ok = withPrinter("cutPaper") { svc ->
                        svc.cutPaper(null)
                    }
                    result.success(ok)
                }
                else -> result.notImplemented()
            }
        }

        // 2. Scanner Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCANNER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getScannerStatus" -> {
                    val isSunmi = Build.MANUFACTURER.contains("SUNMI", ignoreCase = true)
                    result.success(if (isSunmi) "AVAILABLE" else "CAMERA_ONLY")
                }
                "sendScan" -> {
                    Log.d(TAG, "sendScan broadcast com.sunmi.scan")
                    val intent = Intent("com.sunmi.scan")
                    intent.putExtra("SEND_KEY_EVENT", false)
                    sendBroadcast(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 3. Device Info Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> {
                    val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                    val level = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
                    val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
                    val batteryPct = if (level >= 0 && scale > 0) (level * 100 / scale.toFloat()).toInt() else 100

                    val runtime = Runtime.getRuntime()
                    val totalMemoryMb = (runtime.totalMemory() / (1024 * 1024)).toInt()
                    val freeMemoryMb = (runtime.freeMemory() / (1024 * 1024)).toInt()

                    val info = mapOf(
                        "deviceName" to Build.DEVICE,
                        "model" to Build.MODEL,
                        "manufacturer" to Build.MANUFACTURER,
                        "androidVersion" to Build.VERSION.RELEASE,
                        "sdkInt" to Build.VERSION.SDK_INT,
                        "batteryLevel" to batteryPct,
                        "ramTotalMb" to (totalMemoryMb * 2),
                        "ramFreeMb" to freeMemoryMb,
                        "isSunmiHardware" to Build.MANUFACTURER.contains("SUNMI", ignoreCase = true)
                    )
                    result.success(info)
                }
                else -> result.notImplemented()
            }
        }
    }
}
