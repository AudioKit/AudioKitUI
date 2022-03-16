// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import Accelerate
import AVFoundation
import AudioKit
import SwiftUI


#if os(iOS)

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
#endif

extension Shape {
    @ViewBuilder
    func flexableFill(fillType: FillType) -> some View {
        switch fillType {
        case .solid(let color):
            self.fill(color)
        case .gradient(let gradient):
            self.fill(LinearGradient(gradient: gradient, startPoint: .top, endPoint: .center))
        }
    }
}

enum FillType {
    case solid(color: Color)
    case gradient(gradient: Gradient)
}

extension CGRect {
     /// Initialize with a size
     /// - Parameter size: size to create the CGRect with
     public init(size: CGSize) {
         self.init(origin: .zero, size: size)
     }

     /// Initialize with width and height
     /// - Parameters:
     ///   - width: Width of rectangle
     ///   - height: Height of rectangle
     public init(width: CGFloat, height: CGFloat) {
         self.init(origin: .zero, size: CGSize(width: width, height: height))
     }

     /// Initialize with width and height
     /// - Parameters:
     ///   - width: Width of rectangle
     ///   - height: Height of rectangle
     public init(width: Int, height: Int) {
         self.init(width: CGFloat(width), height: CGFloat(height))
     }
 }

// TODO: refactor these to extensions where possible
class AudioHelpers {
    static func getRMSValues(url: URL, windowSize: Int) -> [Float] {
        if let audioInformation = loadAudioSignal(audioURL: url) {
            let signal = audioInformation.signal

            guard windowSize < signal.count else { return [] }

            return createRMSAnalysisArray(signal: signal, windowSize: windowSize)
        }
        return []
    }

    static func getRMSValues(url: URL, rmsFramesPerSecond: Double) -> [Float] {
        if let audioInformation = loadAudioSignal(audioURL: url) {
            let signal = audioInformation.signal
            let windowSize = Int(audioInformation.rate/rmsFramesPerSecond)

            guard windowSize < signal.count else { return [] }

            return createRMSAnalysisArray(signal: signal, windowSize: windowSize)
        }
        return []
    }

    static func createRMSAnalysisArray(signal: [Float], windowSize: Int) -> [Float] {
        let numberOfSamples = signal.count
        let numberOfOutputArrays = numberOfSamples / windowSize
        var outputArray: [Float] = []
        for index in 0...numberOfOutputArrays-1 {
            let startIndex = index * windowSize
            let endIndex = startIndex + windowSize >= signal.count ? signal.count-1 : startIndex + windowSize
            let arrayToAnalyze = Array(signal[startIndex..<endIndex])
            var rms: Float = 0
            vDSP_rmsqv(arrayToAnalyze, 1, &rms, UInt(windowSize))
            outputArray.append(rms)
        }
        return outputArray
    }

    static func getFileEndTime(_ audioFile: AVAudioFile) -> TimeInterval {
        let sampleRate = audioFile.processingFormat.sampleRate
        let numberOfSamples = audioFile.length
        return Double(numberOfSamples) / sampleRate
    }
}
