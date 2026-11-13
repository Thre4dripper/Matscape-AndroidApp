// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    alias(libs.plugins.android.application) apply false
}

tasks.register<Delete>("clean") {
    description = "Deletes the build directory of the root project."
    delete(rootProject.layout.buildDirectory)
}

