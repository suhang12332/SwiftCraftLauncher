//
//  ModrinthProjectContentView.swift
//  SwiftCraftLauncher
//
//  Created by su on 2025/6/2.
//
import SwiftUI

// MARK: - Constants
private enum Constants {
    static let maxVisibleVersions = 15
    static let popoverWidth: CGFloat = 300
    static let popoverHeight: CGFloat = 400
    static let cornerRadius: CGFloat = 4
    static let spacing: CGFloat = 6
    static let padding: CGFloat = 8
}

// MARK: - View Components
private struct CompatibilitySection: View {
    let project: ModrinthProjectDetail
    @State private var showingVersionsPopover = false
    
    var body: some View {
        SectionView(title: "project.info.compatibility".localized()) {
            VStack(alignment: .leading, spacing: 12) {
                MinecraftVersionHeader()
                
                if !project.gameVersions.isEmpty {
                    GameVersionsSection(
                        versions: project.gameVersions,
                        showingVersionsPopover: $showingVersionsPopover
                    )
                }
                
                if !project.loaders.isEmpty {
                    LoadersSection(loaders: project.loaders)
                }
                
                PlatformSupportSection(
                    clientSide: project.clientSide,
                    serverSide: project.serverSide
                )
            }
        }
    }
}

private struct MinecraftVersionHeader: View {
    var body: some View {
        HStack {
            Text("project.info.minecraft".localized())
                .font(.headline)
            Text("project.info.minecraft.edition".localized())
                .foregroundStyle(.primary)
                .font(.caption.bold())
        }
    }
}

private struct GameVersionsSection: View {
    let versions: [String]
    @Binding var showingVersionsPopover: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("project.info.versions".localized())
                    .font(.headline)
                Spacer()
                if versions.count > Constants.maxVisibleVersions {
                    Button(action: { showingVersionsPopover = true }) {
                        Text("+\(versions.count - Constants.maxVisibleVersions)")
                            .font(.caption)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingVersionsPopover) {
                        GameVersionsPopover(versions: versions)
                    }
                }
            }
            
            HStack {
                FlowLayout(spacing: Constants.spacing) {
                    ForEach(Array(versions.prefix(Constants.maxVisibleVersions)), id: \.self) { version in
                        VersionTag(version: version)
                    }
                }
            }
            .padding(.top, 4)
        }
    }
}

private struct GameVersionsPopover: View {
    let versions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("project.info.versions".localized())
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(groupedVersions(versions).keys.sorted(by: >), id: \.self) { majorVersion in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(majorVersion)
                                .font(.headline.bold())
                                .foregroundColor(.primary)
                            
                            FlowLayout(spacing: Constants.spacing) {
                                ForEach(groupedVersions(versions)[majorVersion] ?? [], id: \.self) { version in
                                    VersionTag(version: version)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(width: Constants.popoverWidth, height: Constants.popoverHeight)
    }
}

private struct VersionTag: View {
    let version: String
    
    var body: some View {
        Text(version)
            .font(.caption)
            .padding(.horizontal, Constants.padding)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(Constants.cornerRadius)
    }
}

private struct LoadersSection: View {
    let loaders: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("project.info.platforms".localized())
                .font(.headline)
            FlowLayout(spacing: Constants.spacing) {
                ForEach(loaders, id: \.self) { loader in
                    VersionTag(version: loader)
                }
            }
            .padding(.top, 4)
        }
    }
}

private struct PlatformSupportSection: View {
    let clientSide: String
    let serverSide: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("platform.support".localized() + ":")
                .font(.headline)
            HStack(spacing: 8) {
                PlatformSupportItem(
                    icon: "laptopcomputer",
                    text: "platform.client.\(clientSide)".localized()
                )
                PlatformSupportItem(
                    icon: "server.rack",
                    text: "platform.server.\(serverSide)".localized()
                )
            }.padding(.top, 4)
        }
    }
}

private struct PlatformSupportItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            Text(text)
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
}

private struct LinksSection: View {
    let project: ModrinthProjectDetail
    
    var body: some View {
        SectionView(title: "project.info.links".localized()) {
            FlowLayout(spacing: Constants.spacing) {
                if let url = project.issuesUrl {
                    ProjectLink(
                        text: "project.info.links.issues".localized(),
                        url: url
                    )
                }
                
                if let url = project.sourceUrl {
                    ProjectLink(
                        text: "project.info.links.source".localized(),
                        url: url
                    )
                }
                
                if let url = project.wikiUrl {
                    ProjectLink(
                        text: "project.info.links.wiki".localized(),
                        url: url
                    )
                }
                
                if let url = project.discordUrl {
                    ProjectLink(
                        text: "project.info.links.discord".localized(),
                        url: url
                    )
                }
                
                if let donationUrls = project.donationUrls, !donationUrls.isEmpty {
                    ForEach(donationUrls, id: \.id) { donation in
                        ProjectLink(
                            text: "project.info.links.donate".localized(),
                            url: donation.url
                        )
                    }
                }
            }
        }
    }
}

private struct ProjectLink: View {
    let text: String
    let url: String
    
    var body: some View {
        if let url = URL(string: url) {
            Link(destination: url) {
                Text(text)
                    .font(.caption)
                    .padding(.horizontal, Constants.padding)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(Constants.cornerRadius)
            }
        }
    }
}

private struct DetailsSection: View {
    let project: ModrinthProjectDetail
    
    var body: some View {
        SectionView(title: "project.info.details".localized()) {
            VStack(alignment: .leading, spacing: 8) {
                if let license = project.license {
                    DetailRow(
                        label: "project.info.details.licensed".localized(),
                        value: license.name
                    )
                }
                
                DetailRow(
                    label: "project.info.details.published".localized(),
                    value: project.published.formatted(.relative(presentation: .named))
                )
                DetailRow(
                    label: "project.info.details.updated".localized(),
                    value: project.updated.formatted(.relative(presentation: .named))
                )
            }
        }
    }
}

struct ModrinthProjectContentView: View {
    @State private var isLoading = false
    @State private var error: Error?
    @Binding var projectDetail: ModrinthProjectDetail?
    let projectId: String
    
    var body: some View {
        VStack {
            if let error = error {
                ErrorView(error)
            } else if let project = projectDetail {
                CompatibilitySection(project: project)
                LinksSection(project: project)
                DetailsSection(project: project)
            }
        }
        .task(id: projectId) { await loadProjectDetails() }
    }
    
    private func loadProjectDetails() async {
        isLoading = true
        error = nil
        Logger.shared.info("Loading project details for ID: \(projectId)")
        do {
            let fetchedProject = try await ModrinthService.fetchProjectDetails(id: projectId)
            await MainActor.run {
                projectDetail = fetchedProject
                isLoading = false
            }
            Logger.shared.info("Successfully loaded project details for ID: \(projectId)")
        } catch {
            await MainActor.run {
                self.error = error
                isLoading = false
            }
            Logger.shared.error("Failed to load project details for ID: \(projectId), error: \(error)")
        }
    }
}

// MARK: - Helper Functions
private func groupedVersions(_ versions: [String]) -> [String: [String]] {
    var groups: [String: [String]] = [:]
    
    for version in versions {
        // 处理快照版本 (如 23w43a)
        if version.contains("w") {
            let year = String(version.prefix(2))
            let groupKey = "Snapshot \(year)"
            if groups[groupKey] == nil {
                groups[groupKey] = []
            }
            groups[groupKey]?.append(version)
            continue
        }
        
        // 处理预发布版本 (如 1.20.4-pre1)
        if version.contains("-pre") {
            let baseVersion = version.components(separatedBy: "-pre")[0]
            let components = baseVersion.split(separator: ".")
            if components.count >= 2 {
                let majorVersion = "\(components[0]).\(components[1])"
                if groups[majorVersion] == nil {
                    groups[majorVersion] = []
                }
                groups[majorVersion]?.append(version)
            }
            continue
        }
        
        // 处理候选版本 (如 1.20.4-rc1)
        if version.contains("-rc") {
            let baseVersion = version.components(separatedBy: "-rc")[0]
            let components = baseVersion.split(separator: ".")
            if components.count >= 2 {
                let majorVersion = "\(components[0]).\(components[1])"
                if groups[majorVersion] == nil {
                    groups[majorVersion] = []
                }
                groups[majorVersion]?.append(version)
            }
            continue
        }
        
        // 处理正式版本 (如 1.20.4)
        let components = version.split(separator: ".")
        if components.count >= 2 {
            let majorVersion = "\(components[0]).\(components[1])"
            if groups[majorVersion] == nil {
                groups[majorVersion] = []
            }
            groups[majorVersion]?.append(version)
        } else {
            // 处理其他格式的版本
            if groups["Other"] == nil {
                groups["Other"] = []
            }
            groups["Other"]?.append(version)
        }
    }
    
    // 对每个组内的版本进行排序
    for key in groups.keys {
        groups[key]?.sort { version1, version2 in
            // 移除所有非数字字符后比较
            let v1 = version1.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            let v2 = version2.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return v1 > v2
        }
    }
    
    return groups
}

// MARK: - Helper Views
private struct SectionView<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.bold())
                .padding(.top, 10)
            
            content()
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.callout.bold())
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}



