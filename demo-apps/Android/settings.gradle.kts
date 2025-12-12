pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        // 优先使用本地 Maven 仓库（~/.m2/repository）
        mavenLocal()
        google()
        mavenCentral()
        // GitHub Packages - finclip-chatkit (统一仓库，包含所有 SDK)
        maven {
            url = uri("https://maven.pkg.github.com/Geeksfino/finclip-chatkit")
            credentials {
                username = providers.gradleProperty("gpr.user").orNull ?: System.getenv("GITHUB_USERNAME")
                password = providers.gradleProperty("gpr.key").orNull ?: System.getenv("GITHUB_TOKEN")
            }
        }
    }
}

rootProject.name = "ChatKitDemo"
include(":app")
