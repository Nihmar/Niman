allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // whisper_ggml compiles against android-34 but depends on
    // ffmpeg_kit_flutter_new_min, whose AAR metadata demands compileSdk 35+,
    // so the plugin module fails checkReleaseAarMetadata. Compile it
    // against the same SDK as the app (app/build.gradle.kts).
    if (project.name == "whisper_ggml") {
        afterEvaluate {
            extensions.configure<com.android.build.api.dsl.LibraryExtension>("android") {
                compileSdk = 37
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
