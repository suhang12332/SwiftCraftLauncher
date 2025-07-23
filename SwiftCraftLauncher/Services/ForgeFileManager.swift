import Foundation

class ForgeFileManager {
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
    
    func downloadForgeJars(libraries: [ForgeLibrary]) async throws {
        let tasks = libraries.compactMap { lib -> JarDownloadTask? in
            let artifact = lib.downloads.artifact
            guard let url = URL(string: artifact.url) else { return nil }
            return JarDownloadTask(
                name: lib.name,
                url: url,
                destinationPath: artifact.path,
                expectedSha1: artifact.sha1
            )
        }
        guard let metaLibrariesDir = AppPaths.metaDirectory?.appendingPathComponent("libraries") else { return }
        try await BatchJarDownloader.download(
            tasks: tasks,
            metaLibrariesDir: metaLibrariesDir,
            onProgressUpdate: self.onProgressUpdate
        )
    }
} 
 