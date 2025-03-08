package com.example.super_mind_flutter

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import android.os.Handler
import android.os.Looper

class ShareReceiverActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Process the shared content
        val intent = intent
        val action = intent.action
        val type = intent.type
        
        if (Intent.ACTION_SEND == action && type != null) {
            if (type.startsWith("text/")) {
                handleSendText(intent)
            } else if (type.startsWith("image/")) {
                handleSendImage(intent)
            }
        } else if (Intent.ACTION_SEND_MULTIPLE == action && type != null) {
            if (type.startsWith("image/")) {
                handleSendMultipleImages(intent)
            }
        }
        
        // Show a quick toast notification
        Toast.makeText(this, "Content received", Toast.LENGTH_SHORT).show()
        
        // Store the content in SharedPreferences for the main app to access
        val sharedPrefs = getSharedPreferences("shared_content", MODE_PRIVATE)
        val editor = sharedPrefs.edit()
        editor.putBoolean("has_new_content", true)
        editor.apply()
        
        // Launch the main app in the background to process the content
        val mainIntent = Intent(this, MainActivity::class.java)
        mainIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        mainIntent.putExtra("process_shared_content", true)
        
        // Pass along the shared content
        if (intent.getStringExtra(Intent.EXTRA_TEXT) != null) {
            mainIntent.putExtra(Intent.EXTRA_TEXT, intent.getStringExtra(Intent.EXTRA_TEXT))
        }
        if (intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM) != null) {
            mainIntent.putExtra(Intent.EXTRA_STREAM, intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM))
        }
        if (intent.getParcelableArrayListExtra<android.net.Uri>(Intent.EXTRA_STREAM) != null) {
            mainIntent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, 
                intent.getParcelableArrayListExtra<android.net.Uri>(Intent.EXTRA_STREAM))
        }
        
        // Start the main activity in the background
        startActivity(mainIntent)
        
        // Finish this activity immediately to return to the original app
        Handler(Looper.getMainLooper()).postDelayed({
            finish()
        }, 300) // Short delay to allow the toast to be visible
    }
    
    private fun handleSendText(intent: Intent) {
        intent.getStringExtra(Intent.EXTRA_TEXT)?.let {
            // Store the shared text in SharedPreferences
            val sharedPrefs = getSharedPreferences("shared_content", MODE_PRIVATE)
            val editor = sharedPrefs.edit()
            editor.putString("shared_text", it)
            editor.apply()
        }
    }
    
    private fun handleSendImage(intent: Intent) {
        intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)?.let {
            // Store the image URI in SharedPreferences
            val sharedPrefs = getSharedPreferences("shared_content", MODE_PRIVATE)
            val editor = sharedPrefs.edit()
            editor.putString("shared_image_uri", it.toString())
            editor.apply()
        }
    }
    
    private fun handleSendMultipleImages(intent: Intent) {
        intent.getParcelableArrayListExtra<android.net.Uri>(Intent.EXTRA_STREAM)?.let { uris ->
            // Store the image URIs in SharedPreferences
            val sharedPrefs = getSharedPreferences("shared_content", MODE_PRIVATE)
            val editor = sharedPrefs.edit()
            
            // Convert the list to a JSON array or comma-separated string
            val uriStrings = uris.map { it.toString() }
            editor.putString("shared_image_uris", uriStrings.joinToString(","))
            editor.apply()
        }
    }
} 