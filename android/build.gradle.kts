buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Classpath cho Android Gradle Plugin (Kiểm tra version nếu cần)
        classpath("com.android.tools.build:gradle:8.2.1")
        
        // Classpath cho Kotlin (Kiểm tra version nếu cần)
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.22")
        
        // 👇 Classpath cho Google Services (Firebase) - QUAN TRỌNG
        classpath("com.google.gms:google-services:4.4.2")
    }
}
allprojects {
    repositories {
        google()
        mavenCentral()
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
