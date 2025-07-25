import Foundation

enum URLConfig {
    // API 端点
    enum API {
        // Minecraft API
        enum Minecraft {
            static let baseURL = URL(string: "https://launchermeta.mojang.com")!

            static let versionList = baseURL.appendingPathComponent(
                "mc/game/version_manifest.json"
            )
        }

        // Modrinth API
        enum Modrinth {
            static let baseURL = URL(string: GameSettingsManager.shared.modrinthAPIBaseURL)!
            
            // 项目相关
            static let projects = baseURL.appendingPathComponent("project")
            static func project(id: String) -> URL {
                baseURL.appendingPathComponent("project/\(id)")
            }

            // 版本相关
            static let versions = baseURL.appendingPathComponent("version")
            static func version(id: String) -> URL {
                baseURL.appendingPathComponent("project/\(id)/version")
            }

            // 搜索相关
            static let search = baseURL.appendingPathComponent("search")

            static func versionFile(hash: String) -> URL {
                baseURL.appendingPathComponent("version_file/\(hash)")
            }

//            // 用户相关
//            static let users = baseURL.appendingPathComponent("user")
//            static func user(id: String) -> URL {
//                baseURL.appendingPathComponent("user/\(id)")
//            }

            // 标签相关
            enum Tag {
                static let baseURL = Modrinth.baseURL.appendingPathComponent(
                    "tag"
                )

                // 游戏版本
                static let gameVersion = baseURL.appendingPathComponent(
                    "game_version"
                )

                // 加载器
                static let loader = baseURL.appendingPathComponent("loader")

                // 分类
                static let category = baseURL.appendingPathComponent("category")

                // 许可证
                static let license = baseURL.appendingPathComponent("license")
            }
        }

        // 其他第三方 API
        enum ThirdParty {
            static let baseURL = URL(string: "https://api.example.com")!

            static let analytics = baseURL.appendingPathComponent("analytics")
            static let updateCheck = baseURL.appendingPathComponent("update")
        }

        // FabricMC API
        enum Fabric {
            static let baseAPI = URL(string: "https://meta.fabricmc.net/v2")!
            static let loader = baseAPI.appendingPathComponent("versions/loader")
            static let maven = URL(string: "https://maven.fabricmc.net/")!
        }
        // Forge API
        enum Forge {
            /// 官方 Forge maven
            static let officialMavenBase = "https://maven.minecraftforge.net/net/minecraftforge/forge/"
            /// 镜像 Forge maven（如阿里云、清华等，可自行替换）
            static var mirrorMavenBase: String? = nil // 可在启动时或设置中赋值

            /// 获取当前使用的 maven base url
            static var mavenBase: String {
                mirrorMavenBase ?? officialMavenBase
            }

            static var mavenMetadata: URL {
                // maven-metadata.json 只在官方有，镜像一般没有
                URL(string: "https://files.minecraftforge.net/net/minecraftforge/forge/maven-metadata.json")!
            }
            static func installerJar(version: String) -> URL {
                URL(string: mavenBase)!
                    .appendingPathComponent(version)
                    .appendingPathComponent("forge-\(version)-installer.jar")
            }
            static let bmclListBase = URL(string: "https://bmclapi2.bangbang93.com/forge/minecraft/")!
            static let gitReleasesBase = URL(string: "https://github.com/suhang12332/forge-client/releases/download/")!
        }

        // NeoForge API
        enum NeoForge {
            static let gitReleasesBase = URL(string: "https://github.com/suhang12332/neoforge-client/releases/download/")!
            static let mavenMetadata = URL(string: "https://maven.neoforged.net/net/neoforged/neoforge/maven-metadata.xml")!
            static let bmclListBase = URL(string: "https://bmclapi2.bangbang93.com/neoforge/list/")!
        }

        // Quilt API
        enum Quilt {
            static let loaderBase = URL(string: "https://meta.quiltmc.org/v3/versions/loader/")!
            
        }
    }

    // 资源文件
    enum Resources {
        // Minecraft 资源
        enum Minecraft {
            static let baseURL = URL(string: "https://api.mojang.com")!

            static func playerAvatar(name: String) -> URL {
                baseURL.appendingPathComponent(
                    "users/profiles/minecraft/\(name)"
                )
            }

            static func playerSkin(name: String) -> URL {
                baseURL.appendingPathComponent(
                    "users/profiles/minecraft/\(name)"
                )
            }
        }

        // Modrinth 资源
        enum Modrinth {
            static let baseURL = URL(string: "https://cdn.modrinth.com")!

            static func projectIcon(id: String) -> URL {
                baseURL.appendingPathComponent("data/\(id)/icon.png")
            }

            static func versionFile(id: String) -> URL {
                baseURL.appendingPathComponent("data/\(id)/file")
            }
        }
    }
}
