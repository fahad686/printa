package com.example.printa

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.ServiceConnection
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PRINTER_CHANNEL = "com.sunmi.hardware/printer"
    private val SCANNER_CHANNEL = "com.sunmi.hardware/scanner"
    private val DEVICE_CHANNEL = "com.sunmi.hardware/device"

    private var woyouService: Any? = null

    private val connService = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            try {
                val stubClass = Class.forName("woyou.aio.service.IWoyouService\$Stub")
                val asInterface = stubClass.getDeclaredMethod("asInterface", IBinder::class.java)
                woyouService = asInterface.invoke(null, service)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            woyouService = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        bindSunmiPrinterService()
    }

    private fun bindSunmiPrinterService() {
        if (woyouService != null) return
        try {
            val intent = Intent()
            intent.setPackage("woyou.aio.service")
            intent.action = "woyou.aio.service.impl.WoyouService"
            bindService(intent, connService, Context.BIND_AUTO_CREATE)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unbindService(connService)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun invokeSunmi(methodName: String, vararg args: Any?): Boolean {
        if (woyouService == null) {
            bindSunmiPrinterService()
        }
        val target = woyouService ?: return false
        try {
            val methods = target.javaClass.methods
            for (m in methods) {
                if (m.name == methodName && m.parameterTypes.size == args.size) {
                    m.invoke(target, *args)
                    return true
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Printer Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRINTER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSunmiDevice" -> {
                    val isSunmi = Build.MANUFACTURER.contains("SUNMI", ignoreCase = true) || Build.MODEL.contains("SUNMI", ignoreCase = true)
                    result.success(isSunmi)
                }
                "getPrinterStatus" -> {
                    if (woyouService == null) bindSunmiPrinterService()
                    result.success(if (woyouService != null) "READY" else "SERVICE_NOT_BOUND")
                }
                "getPaperStatus" -> {
                    result.success("NORMAL")
                }
                "getPrinterWidth" -> {
                    result.success(58)
                }
                "printText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val align = call.argument<Int>("align") ?: 0
                    val fontSize = (call.argument<Int>("fontSize") ?: 24).toFloat()

                    invokeSunmi("setAlignment", align, null)
                    var ok = invokeSunmi("printTextWithFont", text + "\n", null, fontSize, null)
                    if (!ok) {
                        ok = invokeSunmi("printText", text + "\n", null)
                    }
                    result.success(ok)
                }
                "printTable" -> {
                    val colsText = (call.argument<List<String>>("colsText") ?: emptyList()).toTypedArray()
                    val colsWidthInt = call.argument<List<Int>>("colsWidth") ?: emptyList()
                    val colsAlignInt = call.argument<List<Int>>("colsAlign") ?: emptyList()

                    val colsWidth = colsWidthInt.toIntArray()
                    val colsAlign = colsAlignInt.toIntArray()

                    val ok = invokeSunmi("printColumnsText", colsText, colsWidth, colsAlign, null)
                    result.success(ok)
                }
                "printQRCode" -> {
                    val data = call.argument<String>("data") ?: ""
                    val size = call.argument<Int>("size") ?: 6
                    invokeSunmi("setAlignment", 1, null)
                    val ok = invokeSunmi("printQRCode", data, size, 3, null)
                    result.success(ok)
                }
                "printBarCode" -> {
                    val data = call.argument<String>("data") ?: ""
                    val symbology = call.argument<Int>("symbology") ?: 8
                    val height = call.argument<Int>("height") ?: 100
                    val width = call.argument<Int>("width") ?: 2
                    invokeSunmi("setAlignment", 1, null)
                    val ok = invokeSunmi("printBarCode", data, symbology, height, width, 2, null)
                    result.success(ok)
                }
                "feedPaper" -> {
                    val lines = call.argument<Int>("lines") ?: 3
                    val ok = invokeSunmi("lineWrap", lines, null)
                    result.success(ok)
                }
                "cutPaper" -> {
                    val ok = invokeSunmi("cutPaper", null)
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
