import Foundation
import SwiftUI

public struct GameSettingsView: View {
    @ObservedObject private var gameSettings = GameSettingsManager.shared
    private var maximumMemoryAllocation: Int {
        let physicalMemoryBytes = ProcessInfo.processInfo.physicalMemory
        let physicalMemoryMB = physicalMemoryBytes / 1_048_576
        let calculatedMax = Int(Double(physicalMemoryMB) * 0.7)
        let roundedMax = (calculatedMax / 512) * 512
        return max(roundedMax, 512)
    }
    public init() {}
    public var body: some View {

        HStack {
            Form {
                Section {
                    SettingRow(label: "settings.default_java_path.label") {
                        TextField("", text: $gameSettings.defaultJavaPath)
                    }
                    Spacer().frame(height: 20)
                    HStack {
                        SettingRow(
                            label: "settings.default_memory_allocation.label"
                        ) {
                            // 内存滑块控制
                            Slider(
                                value: Binding(
                                    get: {
                                        Double(
                                            gameSettings.defaultMemoryAllocation
                                        )
                                    },
                                    set: {
                                        gameSettings.defaultMemoryAllocation =
                                            Int($0)
                                    }
                                ),
                                in: 512...Double(maximumMemoryAllocation),
                                label: { EmptyView() },
                                minimumValueLabel: { EmptyView() },
                                maximumValueLabel: {
                                    EmptyView()
                                }
                            ).controlSize(.mini)
                        }
                        // 当前内存值显示（右对齐，固定宽度）
                        Text("\(gameSettings.defaultMemoryAllocation) MB").font(
                            .subheadline
                        ).foregroundColor(.secondary).frame(minWidth: 64)
                    }
                    HStack {
                        SettingRow(label: "settings.concurrent_downloads.label")
                        {
                            // 并发滑块控制
                            Slider(
                                value: Binding(
                                    get: {
                                        Double(gameSettings.concurrentDownloads)
                                    },
                                    set: {
                                        gameSettings.concurrentDownloads = Int(
                                            $0
                                        )
                                    }
                                ),
                                in: 1...20,
                                label: { EmptyView() },
                                minimumValueLabel: { EmptyView() },
                                maximumValueLabel: { EmptyView() }
                            ).controlSize(.mini)
                        }
                        // 当前内存值显示（右对齐，固定宽度）
                        Text("\(gameSettings.concurrentDownloads)").font(
                            .subheadline
                        ).foregroundColor(.secondary).frame(minWidth: 20)
                    }
                    Spacer().frame(height: 20)
                    Toggle(
                        "settings.auto_download_dependencies.label".localized(),
                        isOn: $gameSettings.autoDownloadDependencies
                    )
                    Text("该选项用于是否弹窗显示前置Mod(依赖)").font(.subheadline).foregroundColor(.secondary).padding(.horizontal)
                }
            }
        }
    }
}
#Preview {
    GameSettingsView()
}
