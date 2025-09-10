import Foundation

final class CSVLogger {
    private var handle: FileHandle?
    private var currentPath: URL?

    // 日毎のファイル名にする（例: Barolog-2025-09-10.csv）
    private func fileURLForToday() throws -> URL {
        let fm = FileManager.default
        let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let name = "Barolog-\(df.string(from: Date())).csv"
        return docs.appendingPathComponent(name)
    }

    func startIfNeeded() {
        do {
            let url = try fileURLForToday()
            currentPath = url
            let fm = FileManager.default
            if !fm.fileExists(atPath: url.path) {
                let header = "timestamp,pressure_hPa,relative_altitude_m\n"
                try header.data(using: .utf8)!.write(to: url)
            }
            handle = try FileHandle(forWritingTo: url)
            try handle?.seekToEnd()
        } catch {
            print("CSV open error: \(error)")
        }
    }

    func append(timestamp: Date, pressure_hPa: Double, altitude_m: Double) {
        guard let handle else { return }
        let iso = ISO8601DateFormatter()
        let line = "\(iso.string(from: timestamp)),\(String(format: "%.1f", pressure_hPa)),\(String(format: "%.3f", altitude_m))\n"
        if let data = line.data(using: .utf8) {
            do { try handle.write(contentsOf: data) } catch { print("CSV write error: \(error)") }
        }
    }

    func stop() {
        try? handle?.close()
        handle = nil
    }

    func currentFileURL() -> URL? { currentPath }
}
