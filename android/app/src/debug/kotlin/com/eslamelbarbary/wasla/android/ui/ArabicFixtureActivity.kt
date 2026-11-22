// SPDX-License-Identifier: GPL-3.0-or-later
package com.eslamelbarbary.wasla.android.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.eslamelbarbary.wasla.android.NectarlinkApplication
import com.eslamelbarbary.wasla.android.core.CoreState
import com.eslamelbarbary.wasla.android.core.CoreStatus
import com.eslamelbarbary.wasla.android.core.Device
import com.eslamelbarbary.wasla.android.ui.home.HomeScreen
import com.eslamelbarbary.wasla.android.ui.theme.Appearance
import com.eslamelbarbary.wasla.android.ui.theme.NectarlinkTheme
import app.nectarlink.core.DeviceKind
import app.nectarlink.core.Link

/** Screenshot fixture only. src/debug is never packaged in the shipped release. */
class ArabicFixtureActivity : ComponentActivity() {
    override fun attachBaseContext(base: android.content.Context) {
        super.attachBaseContext(AppLanguage.arabicContext(base))
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val device = Device(
            id = "visual-fixture", name = "كمبيوتر المكتب", kind = DeviceKind.DESKTOP,
            os = "windows", model = "Windows", pairedAt = 0L,
            link = Link.Online(relayed = false, usb = false, rttMs = 5u),
            features = listOf("files.send", "clipboard.auto_phone_to_pc", "device.pc_actions", "device.pc_hibernate", "device.pc_shutdown").map {
                app.nectarlink.core.Feature(it, app.nectarlink.core.FeatureStatus.Available)
            },
        )
        setContent {
            NectarlinkTheme(appearance = Appearance(theme = "graphite", mode = "dark")) {
                Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                    HomeScreen(
                        state = CoreState(status = CoreStatus.Ready("fixture"), devices = listOf(device)),
                        onRing = { _, _ -> }, onStopRinging = {}, onPairNew = {}, onRefresh = {},
                        onPower = { _, _ -> }, onHibernate = {}, onWake = {}, onSetReconnect = { _, _ -> },
                        onRemote = {}, onDeck = {}, onRecord = {},
                        updater = (application as NectarlinkApplication).updater,
                        onSendFiles = { _, _ -> }, onSendFolder = { _, _ -> }, onAccessChanged = {},
                        onCancelTransfer = {},
                    )
                }
            }
        }
    }
}
