// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/Waveform/

#if os(iOS) || os(visionOS)
import UIKit

class MetalView: UIView {

    var renderer: FloatPlot?
    var displayLink: CADisplayLink?

    @objc static override var layerClass: AnyClass {
        CAMetalLayer.self
    }

    var metalLayer: CAMetalLayer {
        layer as! CAMetalLayer
    }

    func createDisplayLink() {
        displayLink = CADisplayLink(target: self,
                                    selector: #selector(render))

        displayLink?.add(to: .current,
                         forMode: .default)
    }

    override func draw(_ rect: CGRect) {
        render()
    }

    override func draw(_ layer: CALayer, in ctx: CGContext) {
        render()
    }

    override func display(_ layer: CALayer) {
        render()
    }

    @objc func render() {
        guard let renderer else {
            print("⚠️ no renderer")
            return
        }
        renderer.draw(to: metalLayer)
    }

    func resizeDrawable() {

        var newSize = bounds.size
        newSize.width *= contentScaleFactor
        newSize.height *= contentScaleFactor

        if newSize.width <= 0 || newSize.height <= 0 {
            return
        }

        if newSize.width == metalLayer.drawableSize.width &&
            newSize.height == metalLayer.drawableSize.height {
            return
        }

        metalLayer.drawableSize = newSize

        setNeedsDisplay()
    }

    @objc override var frame: CGRect {
        get { super.frame }
        set {
            super.frame = newValue
            resizeDrawable()
        }
    }

    @objc override func layoutSubviews() {
        super.layoutSubviews()
        resizeDrawable()
    }

    @objc override var bounds: CGRect {
        get { super.bounds }
        set {
            super.bounds = newValue
            resizeDrawable()
        }
    }

}
#endif
