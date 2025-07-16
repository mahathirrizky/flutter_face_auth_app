allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

ext {
    set("androidx.camera.camera2.version", "1.3.0")
    set("androidx.camera.version", "1.3.0")
    set("androidx.camera.view.version", "1.3.0")
    set("androidx.lifecycle.version", "2.6.1")
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
