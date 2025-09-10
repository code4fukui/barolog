import SwiftUI

struct ContentView: View {
    @StateObject private var service = AltimeterService()
    @State private var showShare = false
    @State private var shareItems: [Any] = []

    var body: some View {
        VStack(spacing: 24) {
            Text("Barometer Logger").font(.largeTitle).bold()

            if !service.isAvailable {
                Text("このデバイスでは気圧センサーが利用できません。")
                    .foregroundStyle(.secondary)
            } else {
                Group {
                    row(label: "現在の気圧", value: formattedPressure)
                    row(label: "相対高度", value: formattedAltitude)
                }
                .font(.title3)
            }

            HStack(spacing: 12) {
                Button(service.isRunning ? "停止" : "開始") {
                    service.isRunning ? service.stop() : service.start(logging: true)
                }
                .buttonStyle(.borderedProminent)
                /*
                Button(service.isRunning ? "停止" : "開始") {
                    service.isRunning ? service.stop() : service.start(logging: false)
                }
                .buttonStyle(.borderedProminent)

                Button(service.isLogging ? "記録停止" : "記録開始") {
                    if service.isLogging {
                        service.stop()
                    } else {
                        service.start(logging: true)
                    }
                }
                .buttonStyle(.bordered)
                 */

                Button("共有") {
                    if let url = service.currentCSV() {
                        shareItems = [url]
                        showShare = true
                    }
                }
                .buttonStyle(.bordered)
                .disabled(service.currentCSV() == nil)
            }

            if let msg = service.errorMessage {
                Text(msg).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(24)
        .sheet(isPresented: $showShare) {
            if !shareItems.isEmpty {
                ShareSheet(activityItems: shareItems)
            }
        }
    }

    private func row(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).monospaced().bold()
        }
    }

    private var formattedPressure: String {
        if let p = service.pressureHectoPascal { String(format: "%.1f hPa", p) } else { "--.- hPa" }
    }
    private var formattedAltitude: String {
        if let m = service.relativeAltitudeMeter { String(format: "%.3f m", m) } else { "--.-- m" }
    }
}

// 共有シートラッパー
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
