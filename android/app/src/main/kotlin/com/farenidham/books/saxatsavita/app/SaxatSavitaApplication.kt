package com.farenidham.books.saxatsavita.app

import android.app.Application
import android.content.Context
import androidx.multidex.MultiDex

class SaxatSavitaApplication : Application() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
}
