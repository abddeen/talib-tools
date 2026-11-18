import SwiftUI
import AppKit

public struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Text("Recent Captures (\(appState.history.count))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !appState.history.isEmpty {
                    Button(action: {
                        appState.clearHistory()
                    }) {
                        Text("Clear All")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Divider()
            
            if appState.history.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("No capture history yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Take a screenshot using \(appState.preferences.shortcut.displayString) to see translations here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(appState.history) { item in
                            HistoryRow(result: item)
                                .onTapGesture {
                                    appState.currentResult = item
                                    appState.activeTab = .translation
                                }
                        }
                    }
                    .padding(12)
                }
            }
        }
    }
}

private struct HistoryRow: View {
    let result: TranslationResult
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Thumbnail or icon
            if let image = result.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .cornerRadius(6)
                    .clipped()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "text.viewfinder")
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(result.detectedLanguageName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .cornerRadius(3)
                    
                    Spacer()
                    
                    Text(result.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(result.originalText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text("AR: \(result.arabicTranslation)")
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}
