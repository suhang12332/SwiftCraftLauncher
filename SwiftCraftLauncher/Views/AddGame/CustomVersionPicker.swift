import SwiftUI

private enum Constants {
    static let versionGridColumns = 6
    static let versionPopoverMinWidth: CGFloat = 320
    static let versionPopoverMaxHeight: CGFloat = 360
    static let versionButtonPadding: CGFloat = 6
    static let versionButtonVerticalPadding: CGFloat = 3
}

struct CustomVersionPicker: View {
    @Binding var selected: String
    let versions: [MojangVersionInfo]
    @Binding var isLoadingVersions: Bool
    @Binding var time: String
    @State private var showMenu = false
    private var groupedVersions: [(String, [MojangVersionInfo])] {
        let dict = Dictionary(grouping: versions) { version in
            version.id.split(separator: ".").prefix(2).joined(separator: ".")
        }
        return dict.sorted {
            let lhs = $0.key.split(separator: ".").compactMap { Int($0) }
            let rhs = $1.key.split(separator: ".").compactMap { Int($0) }
            return lhs.lexicographicallyPrecedes(rhs)
        }.reversed()
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: Constants.versionGridColumns)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("game.form.version".localized())
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Text(time.isEmpty ? "" : "release.time.prefix".localized() + time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            versionInput
        }
    }

    private var versionInput: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                .background(Color(.textBackgroundColor))
            HStack {
                if selected.isEmpty {
                    if isLoadingVersions {
                        ProgressView().controlSize(.mini).foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                    } else {
                        Text("game.form.version.placeholder".localized()).foregroundColor(.primary)
                            .padding(.horizontal, 8)
                    }
                } else {
                    Text(selected).foregroundColor(.primary)
                        .padding(.horizontal, 8)
                }
                Spacer()
            }
        }
        .frame(height: 22)
        .onTapGesture { showMenu.toggle() }
        .popover(isPresented: $showMenu, arrowEdge: .trailing) {
            versionPopoverContent
        }
    }

    private var versionPopoverContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(groupedVersions, id: \.0) { (major, versions) in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(major)
                            .font(.headline)
                            .padding(.vertical, 2)
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                            ForEach(versions, id: \.id) { version in
                                versionButton(for: version)
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
        .frame(minWidth: Constants.versionPopoverMinWidth, maxHeight: Constants.versionPopoverMaxHeight)
    }

    private func versionButton(for version: MojangVersionInfo) -> some View {
        Button(version.id) {
            selected = version.id
            showMenu = false
            time = CommonUtil.formatRelativeTime(version.releaseTime)
        }
        .padding(.horizontal, Constants.versionButtonPadding)
        .padding(.vertical, Constants.versionButtonVerticalPadding)
        .font(.subheadline)
        .cornerRadius(4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(selected == version.id ? Color.accentColor : Color.gray.opacity(0.15))
        )
        .foregroundStyle(selected == version.id ? .white : .primary)
        .buttonStyle(.plain)
        .fixedSize()
    }
} 