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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Flutter plugins that still declare an older compileSdk cannot satisfy the
// minCompileSdk of newer plugin AARs under AGP 9. Align them with the app's SDK.
fun alignPluginCompileSdk(target: Project) {
    target.extensions.findByType(com.android.build.api.dsl.LibraryExtension::class.java)
        ?.compileSdk = 36
}
subprojects {
    if (state.executed) {
        alignPluginCompileSdk(this)
    } else {
        afterEvaluate { alignPluginCompileSdk(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
