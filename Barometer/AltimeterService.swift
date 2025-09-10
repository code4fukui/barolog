import Foundation
import CoreMotion

final class AltimeterService: ObservableObject {
    private let altimeter = CMAltimeter()
    private let queue = OperationQueue()
    private let logger = CSVLogger()
    
    @Published var pressureHectoPascal: Double?      // hPa
    @Published var relativeAltitudeMeter: Double?    // m
    @Published var isRunning = false
    @Published var isLogging = false
    @Published var errorMessage: String?
    
    var isAvailable: Bool {
        return CMAltimeter.isRelativeAltitudeAvailable()
    }
    
    func start(logging: Bool = false) {
        guard !isRunning else { return }
        guard isAvailable else {
            DispatchQueue.main.async {
                self.errorMessage = "このデバイスでは気圧センサーが利用できません。"
            }
            return
        }
        errorMessage = nil
        isRunning = true
        isLogging = logging
        if logging { logger.startIfNeeded() }
        
        
        // 相対高度アップデート開始（pressureはkPaで返る）
        altimeter.startRelativeAltitudeUpdates(to: queue) { [weak self] data, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isRunning = false
                }
                return
            }
            guard let d = data else { return }
            let kPa = d.pressure.doubleValue
            let hPa = kPa * 10.0 // 1 kPa = 10 hPa
            let meters = d.relativeAltitude.doubleValue
            
            DispatchQueue.main.async {
                self.pressureHectoPascal = hPa
                self.relativeAltitudeMeter = meters
            }
            
            if self.isLogging {
                let now = Date()
                self.logger.append(timestamp: now, pressure_hPa: hPa, altitude_m: meters)
            }
        }
    }
    
    func stop() {
        guard isRunning else { return }
        altimeter.stopRelativeAltitudeUpdates()
        DispatchQueue.main.async {
            self.isRunning = false
            if self.isLogging { self.logger.stop() }
            self.isLogging = false
        }
    }
    // 共有用に現在のCSVファイルURLを返す
    func currentCSV() -> URL? {
        logger.currentFileURL()
    }
}
