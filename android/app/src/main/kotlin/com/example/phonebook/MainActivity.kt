package com.example.phonebook

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import io.flutter.plugins.GeneratedPluginRegistrant  // AGREGAR ESTO

class MainActivity : FlutterActivity() {

    private val CHANNEL = "direct_call_channel"
    private var pendingCallNumber: String? = null
    private val CALL_PHONE_REQUEST_CODE = 1

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // AGREGAR ESTA LÍNEA (lo único que cambia)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        super.configureFlutterEngine(flutterEngine)
        
        println("🔧 Configurando Flutter Engine")
        println("🔧 Channel name: $CHANNEL")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                println("📞 Método llamado: ${call.method}")
                println("📞 Argumentos: ${call.arguments}")

                if (call.method == "directCall") {
                    val number = call.argument<String>("number")
                    println("📞 Número recibido: $number")

                    if (number != null) {
                        if (directCall(number)) {
                            println("📞 Resultado: ok")
                            result.success("ok")
                        } else {
                            pendingCallNumber = number
                            println("📞 Resultado: permission_requested")
                            result.success("permission_requested")
                        }
                    } else {
                        println("📞 Resultado: ERROR - Número inválido")
                        result.error("ERROR", "Número inválido", null)
                    }
                } else {
                    println("📞 Método desconocido: ${call.method}")
                    result.notImplemented()
                }
            }
    }

    private fun directCall(number: String): Boolean {
        println("📱 directCall llamado con número: $number")
        
        // Validar permiso en tiempo de ejecución
        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.CALL_PHONE
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            println("✅ Permiso CALL_PHONE concedido")
            val intent = Intent(Intent.ACTION_CALL)
            intent.data = Uri.parse("tel:$number")
            
            // Verifica si hay una app para manejar la llamada
            if (intent.resolveActivity(packageManager) != null) {
                println("✅ Hay actividad para manejar la llamada")
                startActivity(intent)
                return true
            } else {
                println("❌ No hay actividad para manejar ACTION_CALL")
                return false
            }
        } else {
            println("❌ Permiso CALL_PHONE NO concedido, solicitando...")
            // Solicitar permiso
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CALL_PHONE),
                CALL_PHONE_REQUEST_CODE
            )
            return false
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == CALL_PHONE_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Permiso concedido, hacer la llamada pendiente
                pendingCallNumber?.let { number ->
                    directCall(number)
                }
            } else {
                // Permiso denegado, mostrar mensaje
                // Puedes enviar un mensaje a Flutter si lo necesitas
            }
            pendingCallNumber = null
        }
    }
}