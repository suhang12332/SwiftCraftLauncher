//
//  ModLoaderHandler.swift
//  SwiftCraftLauncher
//
//  Created by su on 2025/7/25.
//

protocol ModLoaderHandler {
    static func setup(
        for gameVersion: String,
        gameInfo: GameVersionInfo,
        onProgressUpdate: @escaping (String, Int, Int) -> Void
    ) async throws -> (loaderVersion: String, classpath: String, mainClass: String)
}
