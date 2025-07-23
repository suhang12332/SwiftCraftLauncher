import SwiftUI

struct DependencySheetView: View {
    @ObservedObject var viewModel: DependencySheetViewModel
    @Binding var isDownloadingAllDependencies: Bool
    @Binding var isDownloadingMainResourceOnly: Bool
    
    let onDownloadAll: () async -> Void
    let onRetry: (ModrinthProjectDetail) async -> Void
    let onDownloadMainOnly: () async -> Void
    
    var body: some View {
        CommonSheetView(
            header: {
                Text("dependency.required_mods.title".localized())
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            },
            body: {
                if viewModel.isLoadingDependencies {
                    ProgressView().frame(height: 100).controlSize(.small)
                } else {
                    VStack {
                        ForEach(viewModel.missingDependencies, id: \.id) { dep in
                            let versions = viewModel.dependencyVersions[dep.id] ?? []
                            if !versions.isEmpty {
                                VStack(alignment: .leading) {
                                    HStack(alignment: .center) {
                                        Text(dep.title)
                                            .font(.headline)
                                        Spacer()
                                        dependencyDownloadStatusView(dep: dep)
                                    }
                                    Picker("dependency.version.picker".localized(), selection: Binding(
                                        get: { viewModel.selectedDependencyVersion[dep.id] ?? (versions.first?.id ?? "") },
                                        set: { viewModel.selectedDependencyVersion[dep.id] = $0 }
                                    )) {
                                        ForEach(versions, id: \.id) { v in
                                            Text(v.name).tag(v.id)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .font(.subheadline)
                                }
                            }
                        }
                    }
                }
            },
            footer: {
                if viewModel.isLoadingDependencies {
                    HStack {
                        Spacer()
                        Button("common.close".localized()) { viewModel.showDependenciesSheet = false }
                    }
                } else if !viewModel.missingDependencies.isEmpty {
                    HStack {
                        Button("common.close".localized()) { viewModel.showDependenciesSheet = false }
                        Spacer()
                        
                        let hasDownloading = viewModel.missingDependencies.contains {
                            viewModel.dependencyDownloadStates[$0.id] == .downloading
                        }
                        Button(action: {
                            Task { await onDownloadMainOnly() }
                        }) {
                            if isDownloadingMainResourceOnly {
                                ProgressView().controlSize(.small)
                            } else {
                                Text("global_resource.download_main_only".localized())
                            }
                        }
                        .disabled(isDownloadingAllDependencies || isDownloadingMainResourceOnly)
                        switch viewModel.overallDownloadState {
                        case .idle:
                            Button(action: {
                                isDownloadingAllDependencies = true
                                Task {
                                    await onDownloadAll()
                                    isDownloadingAllDependencies = false
                                }
                            }) {
                                if isDownloadingAllDependencies || hasDownloading {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Text("dependency.download_all_and_continue".localized())
                                }
                            }
                            .keyboardShortcut(.defaultAction)
                            .disabled(isDownloadingAllDependencies || hasDownloading)
                            
                        case .failed:
                            Button(action: {
                                isDownloadingAllDependencies = true
                                Task {
                                    await onDownloadAll()
                                    isDownloadingAllDependencies = false
                                }
                            }) {
                                if isDownloadingAllDependencies || hasDownloading {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Text("common.continue".localized())
                                }
                            }
                            .keyboardShortcut(.defaultAction)
                            .disabled(isDownloadingAllDependencies || hasDownloading || !viewModel.allDependenciesDownloaded)

                        case .retrying:
                            EmptyView()
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        Button("common.close".localized()) { viewModel.showDependenciesSheet = false }
                    }
                }
            }
        )
    }

    @ViewBuilder
    private func dependencyDownloadStatusView(dep: ModrinthProjectDetail) -> some View {
        let state = viewModel.dependencyDownloadStates[dep.id] ?? .idle
        switch state {
        case .idle:
            EmptyView()
        case .downloading:
            ProgressView().controlSize(.small)
        case .success:
            Label("dependency.download.success".localized(), systemImage: "checkmark.circle.fill")
                .labelStyle(.iconOnly)
                .foregroundColor(.green)
        case .failed:
            Button(action: { Task { await onRetry(dep) } }) {
                Label("dependency.download.retry".localized(), systemImage: "arrow.clockwise.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundColor(.orange)
            }
            .buttonStyle(.borderless)
            .help("dependency.download.retry.help".localized())
        }
    }
} 
 
