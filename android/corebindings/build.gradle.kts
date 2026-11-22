// SPDX-License-Identifier: GPL-3.0-or-later
plugins { id("com.android.library") }
android {
    namespace = "com.eslamelbarbary.wasla.bindings"
    compileSdk = 37
    defaultConfig { minSdk = 26 }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    sourceSets.getByName("main").kotlin.srcDir("../app/build/generated/java/uniffiBindgenDebug")
}
tasks.configureEach {
    if (name.startsWith("compile") && name.endsWith("Kotlin")) {
        dependsOn(":app:uniffiBindgenDebug")
    }
}
dependencies {
    api("net.java.dev.jna:jna:5.19.1@aar")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
}
