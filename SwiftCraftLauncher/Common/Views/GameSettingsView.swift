import Foundation
import SwiftUI
import Sliders

public struct GameSettingsView: View {
    
    @ObservedObject private var gameSettings = GameSettingsManager.shared
    @State private var showJavaPathPicker = false
    @State private var javaVersion: String = "未检测"

    
    private var maximumMemoryAllocation: Int {
        let physicalMemoryBytes = ProcessInfo.processInfo.physicalMemory
        let physicalMemoryMB = physicalMemoryBytes / 1_048_576
        let calculatedMax = Int(Double(physicalMemoryMB) * 0.7)
        let roundedMax = (calculatedMax / 512) * 512
        return max(roundedMax, 512)
    }
    // 内存区间
    @State private var globalMemoryRange: ClosedRange<Double> = 512...4096
    public init() {}

    private func checkJavaVersion(at path: String) {
        guard !path.isEmpty else {
            javaVersion = "未检测"
            return
        }

        DispatchQueue.global().async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = ["-version"]
            let pipe = Pipe()
            process.standardError = pipe
            process.standardOutput = nil
            do {
                try process.run()
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                let version = output.components(separatedBy: .newlines).first(where: { $0.contains("version") }) ?? output
                DispatchQueue.main.async {
                    if version.contains("version") {
                        if let match = version.split(separator: "\"").dropFirst().first {
                            javaVersion = "Java \(match)"
                        } else {
                            javaVersion = version
                        }
                    } else {
                        javaVersion = "无法识别"
                    }

                }
            } catch {
                DispatchQueue.main.async {
                    javaVersion = "检测失败"

                }
            }
        }
    }

    public var body: some View {
        
        Form {
            Section {
                LabeledContent {
                    VStack(alignment: .leading, spacing: 2) {
                        DirectorySettingRow(
                            title: "settings.default_java_path.label".localized(),
                            path: gameSettings.defaultJavaPath.isEmpty ? AppConstants.defaultJava : gameSettings.defaultJavaPath,
                            description: "\(javaVersion) 说明：全局配置，如果游戏没有配置路径的话，使用这个。",
                            onChoose: { showJavaPathPicker = true },
                            onReset: {
                                gameSettings.defaultJavaPath = AppConstants.defaultJava
                            }
                        )
                    }
                } label: {
                    Text("settings.default_java_path.label".localized()).labelsHidden()
                }
                .fileImporter(isPresented: $showJavaPathPicker,
                              allowedContentTypes: [.directory], // 改为允许目录
                              allowsMultipleSelection: false) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            gameSettings.defaultJavaPath = url.path
                        }
                    case .failure:
                        break
                    }
                }
                .onAppear {
                    checkJavaVersion(at: gameSettings.defaultJavaPath.isEmpty ? AppConstants.defaultJava : gameSettings.defaultJavaPath)
                }
                .onChange(of: gameSettings.defaultJavaPath) { old,newPath in
                    checkJavaVersion(at: newPath.isEmpty ? AppConstants.defaultJava : newPath)
                }
            }
            .padding(.bottom, 20) // 只控制Section之间的垂直间距
            Section {
                LabeledContent {
                    HStack {
                        
                        RangeSlider(
                            range: $globalMemoryRange,
                            in: 512...Double(maximumMemoryAllocation),
                            step: 1
                        )
                        .rangeSliderStyle(
                            HorizontalRangeSliderStyle(
                                track:
                                    HorizontalRangeTrack(
                                        view: Capsule().foregroundColor(.accentColor)
                                    )
                                    .background(Capsule().foregroundColor(Color.gray.opacity(0.15)))
                                    .frame(height: 3),
                                lowerThumb: Circle().foregroundColor(.white),
                                upperThumb: Circle().foregroundColor(.white),
                                lowerThumbSize: CGSize(width: 12, height: 12),
                                upperThumbSize: CGSize(width: 12, height: 12)
                            )
                        )
                        
                        .frame(width: 200,height: 20)
                        .onChange(of: globalMemoryRange) { old, newValue in
                            gameSettings.globalXms = Int(newValue.lowerBound)
                            gameSettings.globalXmx = Int(newValue.upperBound)
                        }
                        .onAppear {
                            // 确保 RangeSlider 的值与 GameSettingsManager 同步
                            globalMemoryRange = Double(gameSettings.globalXms)...Double(gameSettings.globalXmx)
                        }
                        Text("\(Int(globalMemoryRange.lowerBound)) MB - \(Int(globalMemoryRange.upperBound)) MB")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize()
                    }
                } label: {
                    Text("settings.default_memory_allocation.label".localized()).labelsHidden()
                }
        
            }
            .padding(.bottom, 20) // 只控制Section之间的垂直间距
            Section {
                LabeledContent {
                    VStack(alignment: .leading,spacing: 6) {
                         Toggle(
                             "settings.auto_download_dependencies.label".localized(),
                             isOn: $gameSettings.autoDownloadDependencies
                         )
                         Text("该选项用于是否弹窗显示前置Mod(依赖)").font(.footnote).foregroundColor(.secondary)
                     }
                 } label: {
                     Text("自动处理依赖").labelsHidden()
                 }
            }
        }
    }
}
#Preview {
    GameSettingsView()
}
