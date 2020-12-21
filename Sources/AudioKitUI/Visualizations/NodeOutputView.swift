// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import Accelerate
import AVFoundation
import SwiftUI

public class NodeTap {
    /// Keep track of connection
    public var isConnected = false

    /// Avoiding bangs
    public var isNotConnected: Bool { return !isConnected }

    /// Set up node
    /// - Parameter input: Input node
    public func setupTap(on input: Node) {
        if isNotConnected {
            input.avAudioUnitOrNode.installTap(
                onBus: 0,
                bufferSize: bufferSize,
                format: nil) { [weak self] (buffer, _) in

                guard let strongSelf = self else {
                    Log("Unable to create strong reference to self")
                    return
                }
                buffer.frameLength = strongSelf.bufferSize
                strongSelf.dataBuffer = buffer
            }
        }
        isConnected = true
    }

    public var dataBuffer: AVAudioPCMBuffer?

    /// Pause plot
    public func pause() {
        if isConnected {
            node.avAudioUnitOrNode.removeTap(onBus: 0)
            isConnected = false
        }
    }

    /// Resume plot
    public func resume() {
        setupTap(on: node)
    }

    public var bufferSize: UInt32 = 1_024

    /// Node to plot
    open var node: Node {
        willSet {
            pause()
        }
        didSet {
            resume()
        }
    }

    /// Remove the tap
    public func removeTap() {
        guard node.avAudioUnitOrNode.engine != nil else {
            Log("The tapped node isn't attached to the engine")
            return
        }

        node.avAudioUnitOrNode.removeTap(onBus: 0)
    }

    /// Initialize the plot with the output from a given node and optional plot size
    ///
    /// - Parameters:
    ///   - input: Node from which to get the plot data
    ///
    public init(_ input: Node, bufferSize: Int = 1_024) {
        self.node = input
    }

    /// Start the plot
    public func start() {
        setupTap(on: node)
    }
}



public struct NodeOutputView: ViewRepresentable {
    var nodeTap: NodeTap
    let bufferSampleCount = 128

    public init(_ node: Node) {
        nodeTap = NodeTap(node)
    }

    let metalFragment = FragmentBuilder(foregroundColor: CrossPlatformColor(red: 0.5, green: 0.5, blue: 1, alpha: 1).cgColor,
                                        backgroundColor: CrossPlatformColor(red: 0.1, green: 0.3, blue: 0.2, alpha: 1).cgColor,
                                        isCentered: true,
                                        isFilled: false)

    var plot: FloatPlot {
        nodeTap.start()

        return FloatPlot(frame: CGRect(x: 0, y: 0, width: 1024, height: 1024), fragment: metalFragment.stringValue) {
            if let buf = nodeTap.dataBuffer {
                return Array(UnsafeBufferPointer(start: buf.floatChannelData![0],
                                             count: Int(nodeTap.bufferSize)))
            } else {
                return []
            }
        }
    }

    #if os(macOS)
    public func makeNSView(context: Context) -> FloatPlot { return plot }
    public func updateNSView(_ nsView: FloatPlot, context: Context) {}
    #else
    public func makeUIView(context: Context) -> FloatPlot { return plot }
    public func updateUIView(_ uiView: FloatPlot, context: Context) {}
    #endif
}
