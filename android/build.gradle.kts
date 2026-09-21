import java.io.File

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    pluginManager.withPlugin("com.android.library") {
        extensions.configure<com.android.build.api.dsl.LibraryExtension>("android") {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
    // Plugins often reset Java 8 in their own android {} block; override after evaluation.
    // Skip :app — Gradle 9 finalizes its toolchain and rejects later JavaCompile mutations.
    afterEvaluate {
        if (name == "app") return@afterEvaluate
        applyBitmapDownsamplePatch()
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
            options.compilerArgs.add("-Xlint:-options")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
   project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

/**
 * Play Console flags BitmapFactory.decode* without Options. flutter_local_notifications
 * is patched here; quill_native_bridge_android is overridden under packages/.
 */
fun Project.applyBitmapDownsamplePatch() {
    if (!name.contains("flutter_local_notifications")) {
        return
    }
    val javaDir = file("src/main/java")
    val decoderSource =
        File(rootProject.projectDir, "patches/SafeBitmapDecoder.java")
    check(javaDir.exists() && decoderSource.exists()) {
        "Missing flutter_local_notifications sources or ${decoderSource.path}"
    }

    val patchedJavaDir = layout.buildDirectory.dir("bitmap-patched-src/java")
    val patchTask =
        tasks.register("patchBitmapJavaSources") {
            outputs.dir(patchedJavaDir)
            doLast {
                val patchedJava = patchedJavaDir.get().asFile
                patchedJava.deleteRecursively()
                copy {
                    from(javaDir)
                    into(patchedJava)
                }
                val decoderDest =
                    File(
                        patchedJava,
                        "com/farenidham/books/saxatsavita/bitmap/SafeBitmapDecoder.java",
                    )
                decoderDest.parentFile.mkdirs()
                decoderSource.copyTo(decoderDest, overwrite = true)

                patchedJava.walkTopDown()
                    .filter {
                        it.isFile && it.extension == "java" && it.name != "SafeBitmapDecoder.java"
                    }
                    .forEach { file ->
                        val original = file.readText()
                        if (!original.contains("BitmapFactory.decode")) {
                            return@forEach
                        }
                        var updated =
                            original
                                .replace(
                                    "BitmapFactory.decodeResource(",
                                    "SafeBitmapDecoder.decodeResource(",
                                )
                                .replace(
                                    "BitmapFactory.decodeFile(",
                                    "SafeBitmapDecoder.decodeFile(",
                                )
                                .replace(
                                    "BitmapFactory.decodeByteArray(",
                                    "SafeBitmapDecoder.decodeByteArray(",
                                )
                                .replace(
                                    "BitmapFactory.decodeStream(",
                                    "SafeBitmapDecoder.decodeStream(",
                                )
                        if (updated != original &&
                            !updated.contains(
                                "import com.farenidham.books.saxatsavita.bitmap.SafeBitmapDecoder;"
                            )
                        ) {
                            updated =
                                updated.replace(
                                    "import android.graphics.BitmapFactory;",
                                    "import android.graphics.BitmapFactory;\n" +
                                        "import com.farenidham.books.saxatsavita.bitmap.SafeBitmapDecoder;",
                                )
                        }
                        file.writeText(updated)
                    }

                val patchedPlugin =
                    File(
                        patchedJava,
                        "com/dexterous/flutterlocalnotifications/FlutterLocalNotificationsPlugin.java",
                    )
                check(
                    patchedPlugin.exists() &&
                        patchedPlugin.readText().contains("SafeBitmapDecoder.decode")
                ) {
                    "Failed to patch flutter_local_notifications BitmapFactory usage"
                }
                check(!patchedPlugin.readText().contains("BitmapFactory.decode")) {
                    "flutter_local_notifications still calls BitmapFactory.decode* after patch"
                }
            }
        }

    extensions.configure<com.android.build.api.dsl.LibraryExtension>("android") {
        sourceSets.named("main") {
            val dirs = java.directories as MutableSet<String>
            dirs.clear()
            dirs.add(patchedJavaDir.get().asFile.absolutePath)
        }
    }
    tasks.withType<JavaCompile>().configureEach { dependsOn(patchTask) }
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        dependsOn(patchTask)
    }
}
