package pay.request

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.ArrayList

class MainActivity : FlutterActivity() {
    private val CHANNEL = "pay.request/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareToWhatsApp") {
                val phone = call.argument<String>("phone") ?: ""
                val text = call.argument<String>("text") ?: ""
                val imagePath = call.argument<String>("imagePath") ?: ""
                val invoicePath = call.argument<String>("invoicePath") ?: ""

                val uris = ArrayList<Uri>()
                if (imagePath.isNotEmpty()) {
                    val file = File(imagePath)
                    if (file.exists()) {
                        uris.add(FileProvider.getUriForFile(this, "${packageName}.fileprovider", file))
                    }
                }
                if (invoicePath.isNotEmpty()) {
                    val file = File(invoicePath)
                    if (file.exists()) {
                        uris.add(FileProvider.getUriForFile(this, "${packageName}.fileprovider", file))
                    }
                }

                if (uris.isNotEmpty()) {
                    val intent = if (uris.size > 1) {
                        Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                            type = "*/*"
                            putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
                        }
                    } else {
                        Intent(Intent.ACTION_SEND).apply {
                            type = "image/png"
                            putExtra(Intent.EXTRA_STREAM, uris[0])
                        }
                    }

                    intent.apply {
                        putExtra(Intent.EXTRA_TEXT, text)
                        putExtra("jid", "${phone}@s.whatsapp.net")
                        setPackage("com.whatsapp")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    startActivity(intent)
                    result.success(true)
                    return@setMethodCallHandler
                }

                // Fallback: wa.me text-only
                val waUrl = "https://wa.me/${phone}?text=${Uri.encode(text)}"
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(waUrl))
                startActivity(intent)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
