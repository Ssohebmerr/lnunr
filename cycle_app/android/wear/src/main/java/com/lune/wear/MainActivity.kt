package com.lune.wear

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.Composable
import androidx.wear.compose.material3.MaterialTheme
import com.lune.wear.ui.LuneWearApp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            LuneWearTheme {
                LuneWearApp()
            }
        }
    }
}

@Composable
fun LuneWearTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        content = content
    )
}
