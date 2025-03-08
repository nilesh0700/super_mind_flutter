package com.example.super_mind_flutter

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.super_mind_flutter/share"
    private val TAG = "MainActivity"
    private val RETURN_DELAY_MS = 5000L // 5 seconds delay before returning
    
    // Shared content variables
    private var currentSharedText: String? = null
    private var currentSharedImageUris: ArrayList<String>? = null
    private var isOpenedFromShare = false
    
    // Return handling
    private var shouldReturnToPreviousApp = false
    private var returnHandler: Handler? = null
    private var returnRunnable: Runnable = Runnable {}

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSharedContent" -> {
                    // Return the initial shared content as a JSON object
                    val contentJson = JSONObject()
                    contentJson.put("isOpenedFromShare", isOpenedFromShare)
                    
                    if (currentSharedText != null) {
                        contentJson.put("text", currentSharedText)
                    }
                    
                    if (currentSharedImageUris != null && currentSharedImageUris!!.isNotEmpty()) {
                        val uriArray = JSONArray()
                        for (uri in currentSharedImageUris!!) {
                            uriArray.put(uri)
                        }
                        contentJson.put("imageUris", uriArray.toString())
                    }
                    
                    Log.d(TAG, "Sending initial shared content to Flutter: $contentJson")
                    result.success(contentJson.toString())
                }
                "cancelReturn" -> {
                    shouldReturnToPreviousApp = false
                    returnHandler?.removeCallbacks(returnRunnable)
                    Log.d(TAG, "Return to previous app cancelled")
                    result.success(true)
                }
                "saveContentSuccess" -> {
                    // Flutter tells us the content was saved successfully
                    Log.d(TAG, "Content saved successfully in Flutter")
                    result.success(true)
                }
                "saveContentFailure" -> {
                    // Flutter tells us the content failed to save
                    Log.d(TAG, "Content failed to save in Flutter")
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate called")
        
        // Process the intent
        processIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent called")
        
        // Process the new intent
        processIntent(intent)
    }
    
    private fun processIntent(intent: Intent) {
        val action = intent.action
        val type = intent.type

        Log.d(TAG, "Processing intent: action=$action, type=$type")

        // Check if this is a share intent
        if (Intent.ACTION_SEND == action && type != null) {
            isOpenedFromShare = true
            
            if (type.startsWith("text/")) {
                handleSendText(intent)
            } else if (type.startsWith("image/")) {
                handleSendImage(intent)
            }
            
            // Schedule return after delay
            shouldReturnToPreviousApp = true
            scheduleReturn()
            
        } else if (Intent.ACTION_SEND_MULTIPLE == action && type != null) {
            isOpenedFromShare = true
            
            if (type.startsWith("image/")) {
                handleSendMultipleImages(intent)
            }
            
            // Schedule return after delay
            shouldReturnToPreviousApp = true
            scheduleReturn()
        } else {
            // Normal app launch, not from share
            isOpenedFromShare = false
            shouldReturnToPreviousApp = false
            
            // Clear any previous shared content
            currentSharedText = null
            currentSharedImageUris = null
        }
    }

    private fun handleSendText(intent: Intent) {
        intent.getStringExtra(Intent.EXTRA_TEXT)?.let {
            currentSharedText = it
            Log.d(TAG, "Received shared text: ${it.take(50)}...")
            
            // Save to persistent storage
            saveToSharedPreferences()
        }
    }

    private fun handleSendImage(intent: Intent) {
        intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)?.let {
            currentSharedImageUris = ArrayList()
            currentSharedImageUris?.add(it.toString())
            Log.d(TAG, "Received shared image: $it")
            
            // Save to persistent storage
            saveToSharedPreferences()
        }
    }

    private fun handleSendMultipleImages(intent: Intent) {
        intent.getParcelableArrayListExtra<android.net.Uri>(Intent.EXTRA_STREAM)?.let {
            currentSharedImageUris = ArrayList()
            for (uri in it) {
                currentSharedImageUris?.add(uri.toString())
            }
            Log.d(TAG, "Received ${it.size} shared images")
            
            // Save to persistent storage
            saveToSharedPreferences()
        }
    }
    
    private fun saveToSharedPreferences() {
        val sharedPrefs = getSharedPreferences("shared_content", MODE_PRIVATE)
        val editor = sharedPrefs.edit()
        
        // Clear previous content
        editor.clear()
        
        // Save new content
        if (currentSharedText != null) {
            editor.putString("shared_text", currentSharedText)
        }
        
        if (currentSharedImageUris != null && currentSharedImageUris!!.isNotEmpty()) {
            if (currentSharedImageUris!!.size == 1) {
                editor.putString("shared_image_uri", currentSharedImageUris!![0])
            } else {
                val uriStrings = currentSharedImageUris!!.joinToString(",")
                editor.putString("shared_image_uris", uriStrings)
            }
        }
        
        editor.putBoolean("has_new_content", true)
        editor.apply()
        
        Log.d(TAG, "Saved content to SharedPreferences")
    }
    
    private fun scheduleReturn() {
        Log.d(TAG, "Scheduling return in ${RETURN_DELAY_MS}ms")
        
        returnHandler = Handler(Looper.getMainLooper())
        returnRunnable = Runnable {
            if (shouldReturnToPreviousApp) {
                Log.d(TAG, "Auto-finishing activity after delay")
                finish()
            } else {
                Log.d(TAG, "Return cancelled by user interaction")
            }
        }
        
        returnHandler?.postDelayed(returnRunnable, RETURN_DELAY_MS)
    }
}
