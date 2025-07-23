import Foundation

// Top-level manifest structure
struct MinecraftVersionManifest: Codable {
    let arguments: Arguments
    let assetIndex: AssetIndex
    let assets: String
    let complianceLevel: Int
    let downloads: Downloads
    let id: String
    let javaVersion: JavaVersion
    let libraries: [Library]
    let logging: Logging
    let mainClass: String
    let minimumLauncherVersion: Int
    let releaseTime: String
    let time: String
    let type: String
}

// Arguments structure
struct Arguments: Codable {
    let game: [ArgumentValue]
    let jvm: [ArgumentValue]
}

// Represents a single argument value, which can be String or an object with rules
enum ArgumentValue: Codable {
    case string(String)
    case objectWithRules(ArgumentRuleObject)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let objectValue = try? container.decode(
            ArgumentRuleObject.self
        ) {
            self = .objectWithRules(objectValue)
        } else {
            throw DecodingError.typeMismatch(
                ArgumentValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected String or ArgumentRuleObject"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .objectWithRules(let value):
            try container.encode(value)
        }
    }
}

// Structure for arguments with rules
struct ArgumentRuleObject: Codable {
    let rules: [Rule]
    let value: ArgumentValueArrayOrString
}

// Helper enum for value in ArgumentRuleObject, which can be String or [String]
enum ArgumentValueArrayOrString: Codable {
    case string(String)
    case array([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([String].self) {
            self = .array(arrayValue)
        } else {
            throw DecodingError.typeMismatch(
                ArgumentValueArrayOrString.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected String or [String]"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
}

// Rule structure
struct Rule: Codable {
    let action: String
    let features: Features?
    let os: OS?
}

// Features structure for rules
struct Features: Codable {
    let is_demo_user: Bool?
    let has_custom_resolution: Bool?
    let has_quick_plays_support: Bool?
    let is_quick_play_singleplayer: Bool?
    let is_quick_play_multiplayer: Bool?
    let is_quick_play_realms: Bool?

    // Handle potential missing keys during decoding
    enum CodingKeys: String, CodingKey {
        case is_demo_user
        case has_custom_resolution
        case has_quick_plays_support
        case is_quick_play_singleplayer
        case is_quick_play_multiplayer
        case is_quick_play_realms
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        is_demo_user = try container.decodeIfPresent(
            Bool.self,
            forKey: .is_demo_user
        )
        has_custom_resolution = try container.decodeIfPresent(
            Bool.self,
            forKey: .has_custom_resolution
        )
        has_quick_plays_support = try container.decodeIfPresent(
            Bool.self,
            forKey: .has_quick_plays_support
        )
        is_quick_play_singleplayer = try container.decodeIfPresent(
            Bool.self,
            forKey: .is_quick_play_singleplayer
        )
        is_quick_play_multiplayer = try container.decodeIfPresent(
            Bool.self,
            forKey: .is_quick_play_multiplayer
        )
        is_quick_play_realms = try container.decodeIfPresent(
            Bool.self,
            forKey: .is_quick_play_realms
        )
    }
}

// OS structure for rules
struct OS: Codable {
    let name: String?
    let version: String?
    let arch: String?

    // Handle potential missing keys during decoding
    enum CodingKeys: String, CodingKey {
        case name, version, arch
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        arch = try container.decodeIfPresent(String.self, forKey: .arch)
    }
}

// Asset Index structure
struct AssetIndex: Codable {
    let id: String
    let sha1: String
    let size: Int
    let totalSize: Int
    let url: URL

    enum CodingKeys: String, CodingKey {
        case id, sha1, size, totalSize, url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        sha1 = try container.decode(String.self, forKey: .sha1)
        size = try container.decode(Int.self, forKey: .size)
        totalSize = try container.decode(Int.self, forKey: .totalSize)
        let urlString = try container.decode(String.self, forKey: .url)
        guard let url = URL(string: urlString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .url,
                in: container,
                debugDescription: "Invalid URL string."
            )
        }
        self.url = url
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sha1, forKey: .sha1)
        try container.encode(size, forKey: .size)
        try container.encode(totalSize, forKey: .totalSize)
        try container.encode(url.absoluteString, forKey: .url)
    }
}

// Downloads structure
struct Downloads: Codable {
    let client: DownloadInfo
    let client_mappings: DownloadInfo?
    let server: DownloadInfo?
    let server_mappings: DownloadInfo?

    // Handle potential missing keys during decoding
    enum CodingKeys: String, CodingKey {
        case client
        case client_mappings
        case server
        case server_mappings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        client = try container.decode(DownloadInfo.self, forKey: .client)
        client_mappings = try container.decodeIfPresent(
            DownloadInfo.self,
            forKey: .client_mappings
        )
        server = try container.decodeIfPresent(
            DownloadInfo.self,
            forKey: .server
        )
        server_mappings = try container.decodeIfPresent(
            DownloadInfo.self,
            forKey: .server_mappings
        )
    }
}

// Download Info structure (for client, server, mappings)
struct DownloadInfo: Codable {
    let sha1: String
    let size: Int
    let url: URL

    enum CodingKeys: String, CodingKey {
        case sha1, size, url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sha1 = try container.decode(String.self, forKey: .sha1)
        size = try container.decode(Int.self, forKey: .size)
        let urlString = try container.decode(String.self, forKey: .url)
        guard let url = URL(string: urlString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .url,
                in: container,
                debugDescription: "Invalid URL string."
            )
        }
        self.url = url
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sha1, forKey: .sha1)
        try container.encode(size, forKey: .size)
        try container.encode(url.absoluteString, forKey: .url)
    }
}

// Library structure
struct Library: Codable {
    let downloads: LibraryDownloads?
    let name: String
    let rules: [Rule]?
    let natives: [String: String]?  // Dictionary for native library paths per OS
    let extract: LibraryExtract?
    let url: URL?  // Some libraries might have a direct URL

    // Handle potential missing keys during decoding
    enum CodingKeys: String, CodingKey {
        case downloads, name, rules, natives, extract, url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        downloads = try container.decodeIfPresent(
            LibraryDownloads.self,
            forKey: .downloads
        )
        name = try container.decode(String.self, forKey: .name)
        rules = try container.decodeIfPresent([Rule].self, forKey: .rules)
        natives = try container.decodeIfPresent(
            [String: String].self,
            forKey: .natives
        )
        extract = try container.decodeIfPresent(
            LibraryExtract.self,
            forKey: .extract
        )

        // Custom decoding for URL to handle optionality and string conversion
        if let urlString = try container.decodeIfPresent(
            String.self,
            forKey: .url
        ) {
            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .url,
                    in: container,
                    debugDescription: "Invalid URL string."
                )
            }
            self.url = url
        } else {
            self.url = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(downloads, forKey: .downloads)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(rules, forKey: .rules)
        try container.encodeIfPresent(natives, forKey: .natives)
        try container.encodeIfPresent(extract, forKey: .extract)
        try container.encodeIfPresent(url?.absoluteString, forKey: .url)
    }
}

// Library Downloads structure
struct LibraryDownloads: Codable {
    let artifact: LibraryArtifact?
    let classifiers: [String: LibraryArtifact]?  // For native libraries

    // Handle potential missing keys during decoding
    enum CodingKeys: String, CodingKey {
        case artifact, classifiers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        artifact = try container.decodeIfPresent(
            LibraryArtifact.self,
            forKey: .artifact
        )
        classifiers = try container.decodeIfPresent(
            [String: LibraryArtifact].self,
            forKey: .classifiers
        )
    }
}

// Library Artifact structure (for main JAR and native classifiers)
struct LibraryArtifact: Codable {
    let path: String
    let sha1: String
    let size: Int
    let url: URL

    enum CodingKeys: String, CodingKey {
        case path, sha1, size, url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decode(String.self, forKey: .path)
        sha1 = try container.decode(String.self, forKey: .sha1)
        size = try container.decode(Int.self, forKey: .size)
        let urlString = try container.decode(String.self, forKey: .url)
        guard let url = URL(string: urlString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .url,
                in: container,
                debugDescription: "Invalid URL string."
            )
        }
        self.url = url
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        try container.encode(sha1, forKey: .sha1)
        try container.encode(size, forKey: .size)
        try container.encode(url.absoluteString, forKey: .url)
    }
}

// Library Extract structure (for native libraries)
struct LibraryExtract: Codable {
    let exclude: [String]
}

// Logging structure
struct Logging: Codable {
    let client: LoggingClient
}

// Logging Client structure
struct LoggingClient: Codable {
    let argument: String
    let file: LoggingFile
    let type: String
}

// Logging File structure
struct LoggingFile: Codable {
    let id: String
    let sha1: String
    let size: Int
    let url: URL

    enum CodingKeys: String, CodingKey {
        case id, sha1, size, url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        sha1 = try container.decode(String.self, forKey: .sha1)
        size = try container.decode(Int.self, forKey: .size)
        let urlString = try container.decode(String.self, forKey: .url)
        guard let url = URL(string: urlString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .url,
                in: container,
                debugDescription: "Invalid URL string."
            )
        }
        self.url = url
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sha1, forKey: .sha1)
        try container.encode(size, forKey: .size)
        try container.encode(url.absoluteString, forKey: .url)
    }
}

// Java Version structure
struct JavaVersion: Codable {
    let component: String
    let majorVersion: Int

    enum CodingKeys: String, CodingKey {
        case component
        case majorVersion
    }
}

// MARK: - Mojang Version Manifest Structures
struct MojangVersionManifest: Codable {
    let latest: LatestVersions
    let versions: [MojangVersionInfo]
}

struct LatestVersions: Codable {
    let release: String
    let snapshot: String
}

struct MojangVersionInfo: Codable, Identifiable {
    let id: String  // Version ID (e.g., "1.20.1")
    let type: String  // e.g., "release", "snapshot"
    let url: URL  // URL to the version-specific manifest
    let time: String
    let releaseTime: String

    // Custom decoding for URL to handle string conversion
    enum CodingKeys: String, CodingKey {
        case id, type, url, time, releaseTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        time = try container.decode(String.self, forKey: .time)
        releaseTime = try container.decode(String.self, forKey: .releaseTime)

        let urlString = try container.decode(String.self, forKey: .url)
        guard let url = URL(string: urlString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .url,
                in: container,
                debugDescription: "Invalid URL string for MojangVersionInfo."
            )
        }
        self.url = url
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(time, forKey: .time)
        try container.encode(releaseTime, forKey: .releaseTime)
        try container.encode(url.absoluteString, forKey: .url)
    }
}
