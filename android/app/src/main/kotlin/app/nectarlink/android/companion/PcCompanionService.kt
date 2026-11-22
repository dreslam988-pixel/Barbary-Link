// SPDX-License-Identifier: GPL-3.0-or-later
package com.eslamelbarbary.wasla.android.companion

import android.companion.AssociationInfo
import android.companion.CompanionDeviceService
import android.companion.DevicePresenceEvent
import android.os.Build
import androidx.annotation.RequiresApi
import com.eslamelbarbary.wasla.android.NectarlinkApplication
import com.eslamelbarbary.wasla.android.service.ConnectionService

/**
 * Bound by Android's CompanionDeviceManager when an associated PC's BLE
 * proximity beacon (`NCTR\x01` + 8-byte device ID prefix) appears nearby.
 * Wakes the foreground [ConnectionService] and triggers an immediate LAN/BLE
 * reconnect in [com.eslamelbarbary.wasla.android.core.Core].
 */
@RequiresApi(Build.VERSION_CODES.S)
class PcCompanionService : CompanionDeviceService() {
    override fun attachBaseContext(base: android.content.Context) {
        super.attachBaseContext(com.eslamelbarbary.wasla.android.ui.AppLanguage.arabicContext(base))
    }


    @Deprecated("Deprecated in API 36 in favor of onDevicePresenceEvent")
    @Suppress("DEPRECATION")
    override fun onDeviceAppeared(associationInfo: AssociationInfo) {
        super.onDeviceAppeared(associationInfo)
        wakeAndReconnect()
    }

    @Deprecated("Deprecated in API 33")
    @Suppress("DEPRECATION")
    override fun onDeviceAppeared(address: String) {
        super.onDeviceAppeared(address)
        wakeAndReconnect()
    }

    @RequiresApi(Build.VERSION_CODES.BAKLAVA)
    override fun onDevicePresenceEvent(event: DevicePresenceEvent) {
        super.onDevicePresenceEvent(event)
        if (event.event == DevicePresenceEvent.EVENT_BLE_APPEARED ||
            event.event == DevicePresenceEvent.EVENT_BT_CONNECTED
        ) {
            wakeAndReconnect()
        }
    }

    private fun wakeAndReconnect() {
        val appContext = applicationContext ?: return
        if (!com.eslamelbarbary.wasla.android.ui.Preferences.isBackgroundServiceEnabled(appContext)) {
            return
        }
        val core = (appContext as? NectarlinkApplication)?.core
        val state = core?.state?.value
        if (state != null && state.status is com.eslamelbarbary.wasla.android.core.CoreStatus.Ready && state.devices.isEmpty()) {
            PcCompanion.disassociateForRemovedPc(appContext, pcName = null, noDevicesRemaining = true)
            return
        }
        ConnectionService.start(appContext)
        core?.reconnectNow()
    }
}
