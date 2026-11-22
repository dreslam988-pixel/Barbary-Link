// SPDX-License-Identifier: GPL-3.0-or-later
pragma Singleton
import QtQuick

// Every link the app itself opens, in one place and nowhere else: never in
// a translation, a setting or anything that arrives over the network, so
// nothing can repoint one. Open them by key with open(); a test pins each
// address (src/app_links.rs).
QtObject {
    id: links

    readonly property string discord: "https://t.me/apkok2026"
    readonly property string x: "https://www.facebook.com/dr.barbary2"
    readonly property string donate: "https://t.me/apkok2026"
    readonly property string repo: "https://github.com/dreslam988-pixel/Barbary-Link"
    readonly property string releases: "https://github.com/dreslam988-pixel/Barbary-Link"
    readonly property string latestRelease: "https://github.com/dreslam988-pixel/Barbary-Link"
    readonly property string privacy: "https://github.com/thtbee/nectarlink/blob/main/docs/guide/privacy-and-security.md"
    readonly property string androidSdkTerms: "https://developer.android.com/studio/terms"
    readonly property string oemUsb: "https://developer.android.com/studio/run/oem-usb"

    // The hosts these may point at; anything else isn't opened.
    readonly property var hosts: ["t.me", "www.facebook.com", "github.com", "developer.android.com"]

    // The address for `key`, or "" for a key that isn't one of the above.
    function url(key) {
        switch (key) {
        case "discord": return discord
        case "x": return x
        case "donate": return donate
        case "repo": return repo
        case "releases": return releases
        case "latestRelease": return latestRelease
        case "privacy": return privacy
        case "androidSdkTerms": return androidSdkTerms
        case "oemUsb": return oemUsb
        default: return ""
        }
    }

    // Whether `address` is https on one of the hosts above.
    function allowed(address) {
        const match = /^https:\/\/([^\/:?#]+)(?:[\/?#]|$)/.exec(address)
        return match !== null && hosts.indexOf(match[1]) >= 0
    }

    // Opens the link `key`; an unknown key opens nothing.
    function open(key) {
        const address = url(key)
        if (address.length === 0 || !allowed(address)) {
            console.warn("Links: not opening", key)
            return false
        }
        return Qt.openUrlExternally(address)
    }
}
