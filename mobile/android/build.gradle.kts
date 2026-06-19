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
// بعض إضافات Flutter (مثل package_info_plus) بتطلب compileSdk 36+، لكن وحدات
// الإضافات بتاخد الافتراضي من Flutter (٣٥). بنفرض ٣٦ على كل وحدة أندرويد عشان
// فحص الـ AAR metadata (checkReleaseAarMetadata) ما يفشلش. لازم يتسجّل الـ
// afterEvaluate قبل evaluationDependsOn(":app") لتفادي "project already evaluated".
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            (ext as com.android.build.gradle.BaseExtension).compileSdkVersion(36)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
