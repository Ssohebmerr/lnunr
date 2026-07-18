package com.lune.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle

/**
 * Target for the privacy-policy link shown by Health Connect's permission UI.
 * The policy is public and matches the URL already used by Flutter and Play.
 */
class HealthPermissionsRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val policy = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("https://lune-7d956.web.app/privacy-policy.html"),
        )
        try {
            startActivity(policy)
        } finally {
            finish()
        }
    }
}
