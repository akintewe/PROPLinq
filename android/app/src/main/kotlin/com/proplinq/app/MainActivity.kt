package com.proplinq.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle deep links when app is opened from a link
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle deep links when app is already running
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        // Flutter plugins (uni_links and appsflyer_sdk) will handle the deep link
        // This ensures the intent is properly passed to Flutter
        if (intent != null) {
            val action = intent.action
            val data = intent.data
            
            if (Intent.ACTION_VIEW == action && data != null) {
                // Deep link intent - Flutter plugins will process it
                // No additional handling needed here as uni_links and appsflyer_sdk handle it
            }
        }
    }
}
