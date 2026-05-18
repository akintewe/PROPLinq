package com.proplinq.app

import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.app.Activity

class SplashActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.setBackgroundColor(Color.WHITE)
        setContentView(R.layout.activity_splash)
        val next = Intent(this, MainActivity::class.java).apply {
            data = intent.data
            action = intent.action
            intent.categories?.forEach { addCategory(it) }
        }
        startActivity(next)
        finish()
    }
}
