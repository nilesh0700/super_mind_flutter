package com.example.super_mind_flutter

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.super_mind_flutter/share"
    private var sharedText: String? = null
    private var sharedImageUris: ArrayList<String>? = null
    private var isSharedContentProcessed = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSharedText") {
                result.success(sharedText)
                sharedText = null
            } else if (call.method == "getSharedImageUris") {
                result.success(sharedImageUris)
                sharedImageUris = null
            } else if (call.method == "hasSharedContent") {
                result.success(sharedText != null || sharedImageUris != null)
            } else {
                result.notImplemented()
            }
        }
        
        // Process intent if it exists
        if (!isSharedContentProcessed) {
            handleIntent(intent)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val action = intent.action
        val type = intent.type

        if (Intent.ACTION_SEND == action && type != null) {
            if (type.startsWith("text/")) {
                handleSendText(intent)
            } else if (type.startsWith("image/")) {
                handleSendImage(intent)
            }
            isSharedContentProcessed = true
        } else if (Intent.ACTION_SEND_MULTIPLE == action && type != null) {
            if (type.startsWith("image/")) {
                handleSendMultipleImages(intent)
            }
            isSharedContentProcessed = true
        }
    }

    private fun handleSendText(intent: Intent) {
        intent.getStringExtra(Intent.EXTRA_TEXT)?.let {
            sharedText = it
        }
    }

    private fun handleSendImage(intent: Intent) {
        intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)?.let {
            sharedImageUris = ArrayList()
            sharedImageUris?.add(it.toString())
        }
    }

    private fun handleSendMultipleImages(intent: Intent) {
        intent.getParcelableArrayListExtra<android.net.Uri>(Intent.EXTRA_STREAM)?.let {
            sharedImageUris = ArrayList()
            for (uri in it) {
                sharedImageUris?.add(uri.toString())
            }
        }
    }
}
