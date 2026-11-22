// SPDX-License-Identifier: GPL-3.0-or-later
import javax.inject.Inject

plugins { id("com.android.library") }

/** Own a generated source directory so every Android consumer gets its task dependency. */
abstract class ImportCoreBindings : DefaultTask() {
    @get:Inject abstract val fs: FileSystemOperations
    @get:InputDirectory @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val sourceDir: DirectoryProperty
    @get:OutputDirectory abstract val outputDir: DirectoryProperty

    @TaskAction
    fun copyBindings() {
        fs.sync {
            from(sourceDir)
            into(outputDir)
        }
    }
}

val importedBindings = tasks.register<ImportCoreBindings>("importCoreBindings") {
    dependsOn(":app:uniffiBindgenDebug")
    sourceDir.set(rootProject.layout.projectDirectory.dir("app/build/generated/java/uniffiBindgenDebug"))
    outputDir.set(layout.buildDirectory.dir("generated/kotlin/corebindings"))
}

android {
    namespace = "com.eslamelbarbary.wasla.bindings"
    compileSdk = 37
    defaultConfig { minSdk = 26 }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
androidComponents {
    onVariants { variant ->
        variant.sources.kotlin?.addGeneratedSourceDirectory(importedBindings, ImportCoreBindings::outputDir)
    }
}
dependencies {
    api("net.java.dev.jna:jna:5.19.1@aar")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
}
