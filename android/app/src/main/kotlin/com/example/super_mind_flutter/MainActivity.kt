package com.example.super_mind_flutter

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.super_mind_flutter/share"
    private var sharedText: String? = null
    private var sharedImageUris: ArrayList<String>? = null
    private var isSharedContentProcessed = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedText" -> {
                    result.success(sharedText)
                    sharedText = null
                }
                "getSharedImageUris" -> {
                    result.success(sharedImageUris)
                    sharedImageUris = null
                }
                "hasSharedContent" -> {
                    // Check for new content from QuickShareActivity first
                    checkForNewSharedContent()
                    result.success(sharedText != null || sharedImageUris != null)
                }
                "checkForNewContent" -> {
                    val hasNewContent = checkForNewSharedContent()
                    result.success(hasNewContent)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Process intent if it exists
        if (!isSharedContentProcessed) {
            handleIntent(intent)
        }
        
        // Check for content from QuickShareActivity
        checkForNewSharedContent()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    override fun onResume() {
        super.onResume()
        // Check for new shared content when the app is resumed
        checkForNewSharedContent()
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
    
    private fun checkForNewSharedContent(): Boolean {
        val sharedPrefs = getSharedPreferences("shared_content", MODE_PRIVATE)
        val hasNewContent = sharedPrefs.getBoolean("has_new_content", false)
        
        if (hasNewContent) {
            // Get the shared text if available
            val text = sharedPrefs.getString("shared_text", null)
            if (text != null) {
                sharedText = text
            }
            
            // Get the shared image URI if available
            val imageUri = sharedPrefs.getString("shared_image_uri", null)
            if (imageUri != null) {
                sharedImageUris = ArrayList()
                sharedImageUris?.add(imageUri)
            }
            
            // Get multiple image URIs if available
            val imageUris = sharedPrefs.getString("shared_image_uris", null)
            if (imageUris != null) {
                if (sharedImageUris == null) {
                    sharedImageUris = ArrayList()
                }
                val uriList = imageUris.split(",")
                for (uri in uriList) {
                    sharedImageUris?.add(uri)
                }
            }
            
            // Clear the shared preferences
            val editor = sharedPrefs.edit()
            editor.clear()
            editor.apply()
            
            isSharedContentProcessed = true
            return true
        }
        
        return false
    }
}
