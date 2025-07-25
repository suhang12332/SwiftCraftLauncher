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
        let quotedNativesDir = "\"\(nativesDir)\""
        let quotedAssetsDir = "\"\(assetsDir)\""
        let quotedGameDir = "\"\(gameDir)\""
        let clientJarPath = versionsDir.appendingPathComponent(manifest.id).appendingPathComponent("\(manifest.id).jar").path
        
        // 生成 Classpath，modJvm 优先生效，按 group/artifact 去重，合并后再筛选当前系统适用的库
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
        let modJvmJars = gameInfo.modJvm
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
        for jar in manifestJarPaths {
            if let key = extractGroupArtifact(from: jar) {
                seenKeys.insert(key)
            }
            mergedJars.append(jar)
        }
        for jar in modJvmJars {
            if let key = extractGroupArtifact(from: jar), !seenKeys.contains(key) {
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
            classpathList = finalJars.map { "\"\($0)\"" } + ["\"\(clientJarPath)\""]
        } else {
            classpathList = finalJars.map { "\"\($0)\"" }
        }
        let classpathString = classpathList.joined(separator: ":")
        // JVM 参数
        let jvmArgs: [String] = [
            "-Djava.library.path=\(quotedNativesDir)",
            "-Djna.tmpdir=\(quotedNativesDir)",
            "-Dorg.lwjgl.system.SharedLibraryExtractPath=\(quotedNativesDir)",
            "-Dio.netty.native.workdir=\(quotedNativesDir)",
            "-Dminecraft.launcher.brand=\(launcherBrand)",
            "-Dminecraft.launcher.version=\(launcherVersion)",
            "-Xmx\(gameInfo.runningMemorySize)M",
            "-Xms\(gameInfo.runningMemorySize)M",
            "-XstartOnFirstThread",
            "-cp", classpathString
        ]

        // Minecraft 启动参数
        var mcArgs: [String] = [
            gameInfo.mainClass,
            "--username", username,
            "--version", gameInfo.gameVersion,
            "--gameDir", quotedGameDir,
            "--assetsDir", quotedAssetsDir,
            "--assetIndex", gameInfo.assetIndex,
            "--uuid", uuid,
            "--accessToken",
            "--clientId", "SCL",
            "--xuid",
            "--userType", "msa",
            "--versionType", "release"
        ]
        // 拼接 Forge/Fabric 特殊参数
        if !gameInfo.gameArguments.isEmpty {
            mcArgs.append(contentsOf: gameInfo.gameArguments)
        }
        return (jvmArgs + mcArgs).joined(separator: " ")
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
