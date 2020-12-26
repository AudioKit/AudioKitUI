// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import Metal
import MetalKit

public class FloatPlot: MTKView, MTKViewDelegate {
    let waveformTexture: MTLTexture!
    let commandQueue: MTLCommandQueue!
    let pipelineState: MTLRenderPipelineState!
    let bufferSampleCount: Int
    let parameterBuffer: MTLBuffer!
    let colorParameterBuffer: MTLBuffer!
    var dataCallback: () -> [Float]

    let metalHeader = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexOut {
    float4 position  [[ position ]];
    float2 t;
    };

    constant float2 verts[4] = { float2(-1, -1), float2(1, -1), float2(-1, 1), float2(1, 1) };

    vertex VertexOut textureVertex(uint vid [[ vertex_id ]]) {

    VertexOut out;
    out.position = float4(verts[vid], 0.0, 1.0);
    out.t = (verts[vid] + float2(1)) * .5;
    out.t.y = 1.0 - out.t.y;
    return out;

    }

    constexpr sampler s(coord::normalized,
    filter::linear);

    fragment half4 textureFragment(VertexOut in [[ stage_in ]],
    texture1d<float, access::sample> waveform, device float* parameters, device float4* colorParameters) {
    """

    init(frame frameRect: CGRect, fragment: String? = nil, dataCallback: @escaping () -> [Float]) {
        self.dataCallback = dataCallback
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

        let defaultFragment = """
        float sample = waveform.sample(s, in.t.x).x;
        float y = (in.t.y - .5);
        float d = fabs(y - sample);
        float alpha = fabs(1/(50 * d));
        return alpha;
        """

        let metal = metalHeader + (fragment ?? defaultFragment) + "}"
//        let library = device!.makeDefaultLibrary()!
        let library = try! device?.makeLibrary(source: metal, options: nil)

        let fragmentProgram = library!.makeFunction(name: "textureFragment")!
        let vertexProgram = library!.makeFunction(name: "textureVertex")!

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

        parameterBuffer = device!.makeBuffer(length: 128 * MemoryLayout<Float>.size,
                                             options: .storageModeShared)
        colorParameterBuffer = device!.makeBuffer(length: 128 * MemoryLayout<SIMD4<Float>>.size,
                                                  options: .storageModeShared)

        super.init(frame: frameRect, device: device)

        self.clearColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0)

        delegate = self
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
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

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // We may want to resize the texture.
    }

    public func draw(in view: MTKView) {
        updateWaveform(samples: dataCallback())

        if let commandBuffer = commandQueue.makeCommandBuffer() {
            if let renderPassDescriptor = currentRenderPassDescriptor {
                guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }

                encoder.setRenderPipelineState(pipelineState)
                encoder.setFragmentTexture(waveformTexture, index: 0)
                encoder.setFragmentBuffer(parameterBuffer, offset: 0, index: 0)
                encoder.setFragmentBuffer(colorParameterBuffer, offset: 0, index: 1)
                encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
                encoder.endEncoding()

                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                }
            }

            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }

    func setParameter(address: Int, value: Float) {
        if address >= 0, address < 128 {
            parameterBuffer.contents().assumingMemoryBound(to: Float.self)[address] = value
        }
    }

    func setColorParameter(address: Int, value: SIMD4<Float>) {
        if address >= 0, address < 128 {
            colorParameterBuffer.contents().assumingMemoryBound(to: SIMD4<Float>.self)[address] = value
        }
    }
}
