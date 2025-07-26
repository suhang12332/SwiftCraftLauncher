import Foundation

struct MinecraftLaunchCommandBuilder {
    static func build(
        manifest: MinecraftVersionManifest,
        gameInfo: GameVersionInfo,
        username: String,
        uuid: String,
        launcherBrand: String,
        launcherVersion: String
    ) -> String {
        // 路径常量
        guard let nativesDir = AppPaths.nativesDirectory?.path,
              let librariesDir = AppPaths.librariesDirectory,
              let assetsDir = AppPaths.assetsDirectory?.path,
              let gameDir = AppPaths.profileDirectory(gameName: gameInfo.gameName)?.path,
              let versionsDir = AppPaths.versionsDirectory else {
            fatalError("AppPaths 路径获取失败")
        }
        let quotedGameDir = gameDir
        let quotedAssetsDir = assetsDir
        let quotedNativesDir = nativesDir
        let clientJarPath = versionsDir.appendingPathComponent(manifest.id).appendingPathComponent("\(manifest.id).jar").path
        
        // 1. 构建 path -> rules 映射
        var pathToRules: [String: [Rule]?] = [:]
        for lib in manifest.libraries {
            if let artifact = lib.downloads?.artifact {
                let path = librariesDir.appendingPathComponent(artifact.path).path
                pathToRules[path] = lib.rules
            }
        }
        // 2. 合并 manifest classpath 和 modJvmJars，manifest 优先，按 group/artifact 去重
        let manifestJarPaths = manifest.libraries
            .compactMap { $0.downloads?.artifact.map { librariesDir.appendingPathComponent($0.path).path } }
        let modClassPath = gameInfo.modClassPath
            .split(separator: ":")
            .map { String($0) }
            .filter { !$0.isEmpty }
        func extractGroupArtifact(from path: String) -> String? {
            let parts = path.split(separator: "/")
            guard parts.count >= 4 else { return nil }
            let artifact = parts[parts.count - 3]
            let group = parts[0..<(parts.count - 3)].joined(separator: "/")
            return "\(group)/\(artifact)"
        }
        var seenKeys = Set<String>()
        var mergedJars: [String] = []
        // 1. 先加 modClassPath
        for jar in modClassPath {
            if let key = extractGroupArtifact(from: jar) {
                if !seenKeys.contains(key) {
                    seenKeys.insert(key)
                    mergedJars.append(jar)
                }
            } else {
                mergedJars.append(jar)
            }
        }
        // 2. 再加 manifestJarPaths
        for jar in manifestJarPaths {
            if let key = extractGroupArtifact(from: jar) {
                if !seenKeys.contains(key) {
                    seenKeys.insert(key)
                    mergedJars.append(jar)
                }
            } else {
                mergedJars.append(jar)
            }
        }
        // 平台适配的 native jar 过滤
        func isJarForCurrentPlatform(_ path: String) -> Bool {
            #if os(macOS)
            return path.contains("-natives-macos") || path.contains("-natives-osx") || path.contains("-natives-macos-arm64") || path.contains("-natives-macos-x86_64") || (!path.contains("-natives-"))
            #elseif os(Windows)
            return path.contains("-natives-windows") || path.contains("-natives-windows-x86") || path.contains("-natives-windows-arm64") || (!path.contains("-natives-"))
            #elseif os(Linux)
            return path.contains("-natives-linux") || path.contains("-natives-linux-x86_64") || path.contains("-natives-linux-aarch_64") || (!path.contains("-natives-"))
            #else
            return !path.contains("-natives-")
            #endif
        }
        // 3. 合并后再筛选当前系统适用的库
        let finalJars = mergedJars.filter { jar in
            guard isJarForCurrentPlatform(jar) else { return false }
            if let rules = pathToRules[jar] {
                return libraryIsApplicable(rules)
            } else {
                // modJvmJars 里没有 rule，默认 true
                return true
            }
        }
        let isFabricOrVanilla = gameInfo.modLoader.lowercased().contains("fabric") || gameInfo.modLoader.lowercased().contains("vanilla")
        let classpathList: [String]
        if isFabricOrVanilla {
            classpathList = finalJars.map { $0 } + [clientJarPath]
        } else {
            classpathList = finalJars.map { $0 }
        }
        let classpathString = classpathList.joined(separator: ":")
        // JVM 参数
        // 获取全局默认内存设置
        let globalXms = GameSettingsManager.shared.globalXms
        let globalXmx = GameSettingsManager.shared.globalXmx
        let useGameMemory = gameInfo.xms > 0 && gameInfo.xmx > 0
        var jvmArgs: [String] = [
            "-Djava.library.path=\(quotedNativesDir)",
            "-Djna.tmpdir=\(quotedNativesDir)",
            "-Dorg.lwjgl.system.SharedLibraryExtractPath=\(quotedNativesDir)",
            "-Dio.netty.native.workdir=\(quotedNativesDir)",
            "-Dminecraft.launcher.brand=SCL",
            "-Dminecraft.launcher.version=\(launcherVersion)",
            "-Xms\((useGameMemory ? gameInfo.xms : globalXms))M",
            "-Xmx\((useGameMemory ? gameInfo.xmx : globalXmx))M",
            "-XstartOnFirstThread",
            "-cp", classpathString
        ]
        if !gameInfo.modJvm.isEmpty {
            jvmArgs.append(contentsOf: gameInfo.modJvm)
        }

        // Minecraft 启动参数
        var mcArgs: [String] = [
            gameInfo.mainClass,
            "--username", username,
            "--version", gameInfo.gameVersion,
            "--gameDir", quotedGameDir,
            "--assetsDir", quotedAssetsDir,
            "--assetIndex", gameInfo.assetIndex,
            "--uuid", uuid,
            "--accessToken", uuid, // 用 uuid 作为 accessToken 的默认值，保证不为空
            "--clientId", "SCL-\(launcherVersion)", // 用启动器版本作为 clientId
            "--xuid", "0", // 伪造 xuid，保证不为空
            "--userType", "msa",
            "--versionType", "release"
        ]
        // 拼接 Forge/Fabric 特殊参数
        if !gameInfo.gameArguments.isEmpty {
            mcArgs.append(contentsOf: gameInfo.gameArguments)
        }
        
        // 拼接前处理空格，所有包含空格的参数加英文双引号
        let safeJvmArgs = jvmArgs.map { arg in
            arg.contains(" ") ? "\"\(arg)\"" : arg
        }
        let safeMcArgs = mcArgs.map { arg in
            arg.contains(" ") ? "\"\(arg)\"" : arg
        }
        return (safeJvmArgs + safeMcArgs).joined(separator: " ")
    }

    /// 判断库是否适用当前平台
    private static func libraryIsApplicable(_ rules: [Rule]?) -> Bool {
        guard let rules = rules else { return true }
        var finalAction = "allow"
        for rule in rules {
            let applies: Bool = {
                guard let osRule = rule.os else { return true }
                #if os(macOS)
                return osRule.name == nil || osRule.name == "osx"
                #elseif os(Linux)
                return osRule.name == nil || osRule.name == "linux"
                #elseif os(Windows)
                return osRule.name == nil || osRule.name == "windows"
                #else
                return false
                #endif
            }()
            if applies {
                finalAction = rule.action
            }
        }
        return finalAction == "allow"
    }
} 
