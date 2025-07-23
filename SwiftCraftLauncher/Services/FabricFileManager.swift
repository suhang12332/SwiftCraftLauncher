import Foundation

class FabricFileManager {
    let librariesDir: URL
    let session: URLSession
    var onProgressUpdate: ((String, Int, Int) -> Void)?
    private let fileManager = FileManager.default
    private let retryCount = 3
    private let retryDelay: TimeInterval = 2
    
    init(librariesDir: URL) {
        self.librariesDir = librariesDir
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = GameSettingsManager.shared.concurrentDownloads
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }
    
    actor Counter {
        private var value = 0
        func increment() -> Int {
            value += 1
            return value
        }
    }
    
    func downloadFabricJars(urls: [URL], sha1s: [String?]? = nil) async throws {
        let tasks: [JarDownloadTask] = urls.enumerated().map { (index, url) in
            let fileName = url.lastPathComponent
            let mavenPath = FabricFileManager.mavenURLToMavenPath(url: url)
            let expectedSha1 = sha1s?.count ?? 0 > index ? sha1s?[index] : nil
            return JarDownloadTask(
                name: fileName,
                url: url,
                destinationPath: mavenPath,
                expectedSha1: expectedSha1
            )
        }
        guard let metaLibrariesDir = AppPaths.metaDirectory?.appendingPathComponent("libraries") else { return }
        try await BatchJarDownloader.download(
            tasks: tasks,
            metaLibrariesDir: metaLibrariesDir,
            onProgressUpdate: self.onProgressUpdate
        )
    }

    static func mavenURLToMavenPath(url: URL) -> String {
        let components = url.path.split(separator: "/")
        return components.joined(separator: "/")
    }
} 