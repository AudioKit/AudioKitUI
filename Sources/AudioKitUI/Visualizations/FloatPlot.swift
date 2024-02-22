// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import Metal
import MetalKit

// This must be in sync with the definition in shaders.metal
public struct FragmentConstants {
    public var foregroundColor: SIMD4<Float>
    public var backgroundColor: SIMD4<Float>
    public var isFFT: Bool
    public var isCentered: Bool
    public var isFilled: Bool

    // Padding is required because swift doesn't pad to alignment
    // like MSL does.
    public var padding: Int = 0
}

public class FloatPlot: MTKView {
    let waveformTexture: MTLTexture!
    let commandQueue: MTLCommandQueue!
    let pipelineState: MTLRenderPipelineState!
    let bufferSampleCount: Int
    var dataCallback: () -> [Float]
    var constants: FragmentConstants
    let layerRenderPassDescriptor: MTLRenderPassDescriptor

    public init(frame frameRect: CGRect,
                constants: FragmentConstants,
                dataCallback: @escaping () -> [Float]) {
        self.dataCallback = dataCallback
        self.constants = constants
        bufferSampleCount = Int(frameRect.width)

        let desc = MTLTextureDescriptor()
        desc.textureType = .type1D
        desc.width = Int(frameRect.width)
        desc.pixelFormat = .r32Float
        assert(desc.height == 1)
        assert(desc.depth == 1)

        let device = MTLCreateSystemDefaultDevice()
        waveformTexture = device?.makeTexture(descriptor: desc)
        commandQueue = device!.makeCommandQueue()

        let library = try! device?.makeDefaultLibrary(bundle: Bundle.module)

        let fragmentProgram = library!.makeFunction(name: "genericFragment")!
        let vertexProgram = library!.makeFunction(name: "waveformVertex")!

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.sampleCount = 1

        let colorAttachment = pipelineStateDescriptor.colorAttachments[0]!
        colorAttachment.pixelFormat = .bgra8Unorm
        colorAttachment.isBlendingEnabled = true
        colorAttachment.sourceRGBBlendFactor = .sourceAlpha
        colorAttachment.sourceAlphaBlendFactor = .sourceAlpha
        colorAttachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        colorAttachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha

        pipelineState = try! device!.makeRenderPipelineState(descriptor: pipelineStateDescriptor)

        layerRenderPassDescriptor = MTLRenderPassDescriptor()
        layerRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        layerRenderPassDescriptor.colorAttachments[0].storeAction = .store
        layerRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1);

        super.init(frame: frameRect, device: device)

        clearColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0)

        delegate = self
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateWaveform(samples: [Float]) {
        if samples.count == 0 {
            return
        }

        var resampled = [Float](repeating: 0, count: bufferSampleCount)

        for i in 0 ..< bufferSampleCount {
            let x = Float(i) / Float(bufferSampleCount) * Float(samples.count - 1)
            let j = Int(x)
            let fraction = x - Float(j)
            resampled[i] = samples[j] * (1.0 - fraction) + samples[j + 1] * fraction
        }

        resampled.withUnsafeBytes { ptr in
            waveformTexture.replace(region: MTLRegionMake1D(0, bufferSampleCount),
                                    mipmapLevel: 0,
                                    withBytes: ptr.baseAddress!,
                                    bytesPerRow: 0)
        }
    }

    func encode(to commandBuffer: MTLCommandBuffer, pass: MTLRenderPassDescriptor) {
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) else { return }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentTexture(waveformTexture, index: 0)
        assert(MemoryLayout<FragmentConstants>.size == 48)
        encoder.setFragmentBytes(&constants, length: MemoryLayout<FragmentConstants>.size, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
    }

    func draw(in layer: CAMetalLayer) {

        let size = layer.drawableSize
        let w = Float(size.width)
        let h = Float(size.height)
        // let scale = Float(view.contentScaleFactor)

        if w == 0 || h == 0 {
            return
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }

        if let currentDrawable = layer.nextDrawable() {

            layerRenderPassDescriptor.colorAttachments[0].texture = currentDrawable.texture

            encode(to: commandBuffer, pass: layerRenderPassDescriptor)

            commandBuffer.present(currentDrawable)
        }
        commandBuffer.commit()
    }
}

#if !os(visionOS)
extension FloatPlot: MTKViewDelegate {
    public func mtkView(_: MTKView, drawableSizeWillChange _: CGSize) {
        // We may want to resize the texture.
    }

    public func draw(in view: MTKView) {
        updateWaveform(samples: dataCallback())

        if let commandBuffer = commandQueue.makeCommandBuffer() {
            if let renderPassDescriptor = currentRenderPassDescriptor {
                encode(to: commandBuffer, pass: renderPassDescriptor)
                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                }
            }

            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
}
#endif
