import Foundation
import AppKit

public final class ScreenCaptureService {
    public static let shared = ScreenCaptureService()
    
    private init() {}
    
    /// Launches macOS interactive screen capture tool.
    /// User can drag to select a region. If user hits Escape, it cancels cleanly.
    public func captureInteractiveSelection() async -> NSImage? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let tempDirectory = FileManager.default.temporaryDirectory
                let tempFilePath = tempDirectory.appendingPathComponent("arabic_helper_\(UUID().uuidString).png")
                
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                // -i: interactive selection
                // -r: do not add dpi metadata / screen resolution issues
                // tempFilePath.path: destination file
                process.arguments = ["-i", tempFilePath.path]
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    
                    if FileManager.default.fileExists(atPath: tempFilePath.path),
                       let image = NSImage(contentsOf: tempFilePath) {
                        // Clean up temp file
                        try? FileManager.default.removeItem(at: tempFilePath)
                        continuation.resume(returning: image)
                    } else {
                        // User cancelled (e.g. pressed Escape)
                        continuation.resume(returning: nil)
                    }
                } catch {
                    print("Error running screencapture: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
