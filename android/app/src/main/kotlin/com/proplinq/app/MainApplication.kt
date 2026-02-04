package com.proplinq.app

import android.app.Application
// import com.appsflyer.AppsFlyerLib

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Note: AppsFlyer SDK initialization has been moved to Flutter side
        // to handle dependency resolution issues with Kotlin 2.1.0
        // The Flutter appsflyer_sdk plugin will handle initialization
    }
}