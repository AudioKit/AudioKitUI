// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
#if !os(macOS) || targetEnvironment(macCatalyst)

import AVFoundation
import UIKit

/// A click and draggable view of an ADSR Envelope (Atttack, Decay, Sustain, Release)
/// All values are normalised 0->1, so scale them how you would like in your callback

@IBDesignable public class ADSRView: UIView {
    /// Type of function to call when values of the ADSR have changed
    public typealias ADSRCallback = (Float, Float, Float, Float) -> Void

    /// Attack amount, Default: 0.5
    open var attack: Float = 0.5 { didSet { setNeedsDisplay() } }

    /// Decay amount, Default: 0.5
    open var decay: Float = 0.5 { didSet { setNeedsDisplay() } }

    /// Sustain Level (0-1), Default: 0.5
    open var sustain: Float = 0.5 { didSet { setNeedsDisplay() } }

    /// Release amount, Default: 0.5
    open var release: Float = 0.5 { didSet { setNeedsDisplay() } }

    /// How much to slow the  drag - lower is slower, Default: 0.005
    open var dragSlew: Float = 0.005

    /// How much curve to apply to the attack section - 0 = no curve, 1 = full curve, Default: 1.0
    open var attackCurve: Float = 1.0 { didSet { setNeedsDisplay() } }

    /// How much curve to apply to the decay section - 0 = no curve, 1 = full curve, Default: 1.0
    open var decayCurve: Float = 1.0 { didSet { setNeedsDisplay() } }

    /// How much curve to apply to the release section - 0 = no curve, 1 = full curve, Default: 1.0
    open var releaseCurve: Float = 1.0 { didSet { setNeedsDisplay() } }

    /// Use gradient or solid color sections, Default: false
    open var useGradient: Bool = false { didSet { setNeedsDisplay() } }

    /// How much area to leave before attack to allow manipulation if attack == 0
    open var attackPaddingPercent: CGFloat = 0.06

    /// How much area to leave after release
    open var releasePaddingPercent: CGFloat = 0.01

    private var decaySustainTouchAreaPath = UIBezierPath()
    private var attackTouchAreaPath = UIBezierPath()
    private var releaseTouchAreaPath = UIBezierPath()

    /// Function to call when the values of the ADSR changes
    open var callback: ADSRCallback?
    private var currentDragArea = ""

    //// Color Declarations

    /// Color in the attack portion of the UI element
    @IBInspectable open var attackColor: UIColor = #colorLiteral(red: 0.767, green: 0.000, blue: 0.000, alpha: 1.000)

    /// Color in the decay portion of the UI element
    @IBInspectable open var decayColor: UIColor = #colorLiteral(red: 0.942, green: 0.648, blue: 0.000, alpha: 1.000)

    /// Color in the sustain portion of the UI element
    @IBInspectable open var sustainColor: UIColor = #colorLiteral(red: 0.320, green: 0.800, blue: 0.616, alpha: 1.000)

    /// Color in the release portion of the UI element
    @IBInspectable open var releaseColor: UIColor = #colorLiteral(red: 0.720, green: 0.519, blue: 0.888, alpha: 1.000)

    /// Background color
    @IBInspectable open var bgColor: UIColor = .clear

    /// Width of the envelope curve
    @IBInspectable open var curveStrokeWidth: CGFloat = 2

    /// Color of the envelope curve
    @IBInspectable open var curveColor: UIColor = .black

    private var lastPoint = CGPoint.zero

    public func setAllCurves(curve: Float) {
        attackCurve = curve
        decayCurve = curve
        releaseCurve = curve
    }

    public func setAllColors(color: UIColor) {
        attackColor = color
        decayColor = color
        sustainColor = color
        releaseColor = color
    }

    // MARK: - Initialization

    /// Initialize the view, usually with a callback
    public init(callback: ADSRCallback? = nil) {
        self.callback = callback
        super.init(frame: CGRect(x: 0, y: 0, width: 440, height: 150))
        backgroundColor = bgColor
    }

    /// Initialization of the view from within interface builder
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - Storyboard Rendering

    /// Perform necessary operation to allow the view to be rendered in interface builder
    override public func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        contentMode = .scaleAspectFill
        clipsToBounds = true
    }

    /// Size of the view
    override public var intrinsicContentSize: CGSize {
        return CGSize(width: 440, height: 150)
    }

    /// Requeire a constraint based layout with interface builder
    override public class var requiresConstraintBasedLayout: Bool {
        return true
    }

    // MARK: - Touch Handling

    /// Handle new touches
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self)

            if decaySustainTouchAreaPath.contains(touchLocation) {
                currentDragArea = "ds"
            }
            if attackTouchAreaPath.contains(touchLocation) {
                currentDragArea = "a"
            }
            if releaseTouchAreaPath.contains(touchLocation) {
                currentDragArea = "r"
            }
            lastPoint = touchLocation
        }
        setNeedsDisplay()
    }

    /// Handle moving touches
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: self)

            if currentDragArea != "" {
                if currentDragArea == "ds" {
                    sustain -= Float(touchLocation.y - lastPoint.y) * dragSlew
                    decay += Float(touchLocation.x - lastPoint.x) * dragSlew
                }
                if currentDragArea == "a" {
                    attack += Float(touchLocation.x - lastPoint.x) * dragSlew
                    attack -= Float(touchLocation.y - lastPoint.y) * dragSlew
                }
                if currentDragArea == "r" {
                    release += Float(touchLocation.x - lastPoint.x) * dragSlew
                    release -= Float(touchLocation.y - lastPoint.y) * dragSlew
                }
            }
            attack = max(min(attack, 1), 0)
            decay = max(min(decay, 1), 0)
            sustain = max(min(sustain, 1), 0)
            release = max(min(release, 1), 0)

            if let callback = callback {
                callback(attack,
                         decay,
                         sustain,
                         release)
            }
            lastPoint = touchLocation
        }
        setNeedsDisplay()
    }

    // MARK: - Drawing

    /// Draw the ADSR envelope
    func drawCurveCanvas(size: CGSize = CGSize(width: 440, height: 151),
                         attack: CGFloat = 0.5,           // normalised
                         decay: CGFloat = 0.5,            // normalised
                         sustain: CGFloat = 0.583,         // normalised
                         release: CGFloat = 0.5,          // normalised
                         attackPadPercentage: CGFloat = 0.1,    // how much % width of the view should pad attack
                         releasePadPercentage: CGFloat = 0.1,   // how much % width of the view should pad release
                         attackCurve: CGFloat = 1.0,      // how much curve to apply to attack portion
                         decayCurve: CGFloat = 1.0,       // how much curve to apply to decay portion
                         releaseCurve: CGFloat = 1.0      // how much curve to apply to release portion
    )
    {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()

        let width = floor(size.width)
        let height = floor(size.height)

        //// Variable Declarations
        let buffer = CGFloat(10) // curveStrokeWidth / 2.0 // make a little room for drwing the stroke
        let attackClickRoom = floor(CGFloat(attackPadPercentage * width)) // to allow attack to be clicked even if zero
        let releaseClickRoom = floor(CGFloat(releasePadPercentage * width)) // to allow attack to be clicked even if zero
        let endPointMax = width - releaseClickRoom
        let sectionMax = floor((width * (1.0 - attackPadPercentage - releasePadPercentage)) / 3.3)
        let attackSize = floor(attack * sectionMax)
        let decaySize = floor(decay * sectionMax)
        let sustainSize = floor(sustain * (height - buffer) + buffer)
        let releaseSize = release * sectionMax

        let initialPoint = CGPoint(x: attackClickRoom, y: height)
        let endAxes = CGPoint(x: width, y: height)
        let releasePoint = CGPoint(x: endPointMax - sectionMax,
                                   y: sustainSize)
        let endPoint = CGPoint(x: min(endPointMax, (releasePoint.x + releaseSize)), y: height)
        let endMax = CGPoint(x: min(endPoint.x, endPointMax), y: buffer)
        let releaseAxis = CGPoint(x: releasePoint.x, y: endPoint.y)
        let releaseMax = CGPoint(x: releasePoint.x, y: buffer)
        let highPoint = CGPoint(x: attackClickRoom + attackSize, y: buffer)
        let highPointAxis = CGPoint(x: highPoint.x, y: height)
        let highMax = CGPoint(x: highPoint.x, y: buffer)
        let sustainPoint = CGPoint(x: max(highPoint.x, attackClickRoom + attackSize + decaySize),
                                   y: sustainSize)
        let sustainAxis = CGPoint(x: sustainPoint.x, y: height)
        let initialMax = CGPoint(x: 0, y: buffer)

        let initialToHighControlPoint = CGPoint(x: initialPoint.x, y: highPoint.y)
        let highToSustainControlPoint = CGPoint(x: highPoint.x, y: sustainPoint.y)
        let releaseToEndControlPoint = CGPoint(x: releasePoint.x, y: endPoint.y)

        let attackMidPoint = initialPoint.midPoint(highPoint)
        let decayMidPoint = highPoint.midPoint(sustainPoint)
        let releaseMidPoint = releasePoint.midPoint(endPoint)
        let attackCurveControlPoint = CGPoint(x: (attackCurve * initialToHighControlPoint.x)
                                            + ((1.0 - attackCurve) * attackMidPoint.x),
                                         y: (attackCurve * initialToHighControlPoint.y)
                                            + ((1.0 - attackCurve) * attackMidPoint.y))

        let decayCurveControlPoint = CGPoint(x: (decayCurve * highToSustainControlPoint.x)
                                            + ((1.0 - decayCurve) * decayMidPoint.x),
                                         y: (decayCurve * highToSustainControlPoint.y)
                                            + ((1.0 - decayCurve) * decayMidPoint.y))

        let releaseCurveControlPoint = CGPoint(x: (releaseCurve * releaseToEndControlPoint.x)
                                            + ((1.0 - releaseCurve) * releaseMidPoint.x),
                                         y: (releaseCurve * releaseToEndControlPoint.y)
                                            + ((1.0 - releaseCurve) * releaseMidPoint.y))

        //// attackTouchArea Drawing
        context?.saveGState()

        attackTouchAreaPath = UIBezierPath()
        attackTouchAreaPath.move(to: CGPoint(x: 0, y: size.height))
        attackTouchAreaPath.addLine(to: highPointAxis)
        attackTouchAreaPath.addLine(to: highMax)
        attackTouchAreaPath.addLine(to: initialMax)
        attackTouchAreaPath.addLine(to: CGPoint(x: 0, y: size.height))
        attackTouchAreaPath.close()
        bgColor.setFill()
        attackTouchAreaPath.fill()

        context?.restoreGState()

        //// decaySustainTouchArea Drawing
        context?.saveGState()

        decaySustainTouchAreaPath = UIBezierPath()
        decaySustainTouchAreaPath.move(to: highPointAxis)
        decaySustainTouchAreaPath.addLine(to: releaseAxis)
        decaySustainTouchAreaPath.addLine(to: releaseMax)
        decaySustainTouchAreaPath.addLine(to: highMax)
        decaySustainTouchAreaPath.addLine(to: highPointAxis)
        decaySustainTouchAreaPath.close()
        bgColor.setFill()
        decaySustainTouchAreaPath.fill()

        context?.restoreGState()

        //// releaseTouchArea Drawing
        context?.saveGState()

        releaseTouchAreaPath = UIBezierPath()
        releaseTouchAreaPath.move(to: releaseAxis)
        releaseTouchAreaPath.addLine(to: endAxes)
        releaseTouchAreaPath.addLine(to: endMax)
        releaseTouchAreaPath.addLine(to: releaseMax)
        releaseTouchAreaPath.addLine(to: releaseAxis)
        releaseTouchAreaPath.close()
        bgColor.setFill()
        releaseTouchAreaPath.fill()

        context?.restoreGState()

        //// releaseArea Drawing
        context?.saveGState()

        let releaseAreaPath = UIBezierPath()
        releaseAreaPath.move(to: releaseAxis)
        releaseAreaPath.addCurve(to: endPoint,
                                 controlPoint1: releaseAxis,
                                 controlPoint2: endPoint)
        releaseAreaPath.addCurve(to: releasePoint,
                                 controlPoint1: releaseCurveControlPoint,
                                 controlPoint2: releasePoint)
        releaseAreaPath.addLine(to: releaseAxis)
        releaseAreaPath.close()
        if useGradient {
            context?.drawLinearGradient(in: releaseAreaPath.cgPath, startingWith: sustainColor.cgColor,
                                        finishingWith: releaseColor.cgColor)

        } else {
            releaseColor.setFill()
            releaseAreaPath.fill()
        }

        context?.restoreGState()

        //// sustainArea Drawing
        context?.saveGState()

        let sustainAreaPath = UIBezierPath()
        sustainAreaPath.move(to: sustainAxis)
        sustainAreaPath.addLine(to: releaseAxis)
        sustainAreaPath.addLine(to: releasePoint)
        sustainAreaPath.addLine(to: sustainPoint)
        sustainAreaPath.addLine(to: sustainAxis)
        sustainAreaPath.close()
        sustainColor.setFill()
        sustainAreaPath.fill()

        context?.restoreGState()

        //// decayArea Drawing
        context?.saveGState()

        let decayAreaPath = UIBezierPath()
        decayAreaPath.move(to: highPointAxis)
        decayAreaPath.addLine(to: sustainAxis)
        decayAreaPath.addCurve(to: sustainPoint,
                               controlPoint1: sustainAxis,
                               controlPoint2: sustainPoint)
        decayAreaPath.addCurve(to: highPoint,
                               controlPoint1: decayCurveControlPoint,
                               controlPoint2: highPoint)
        decayAreaPath.addLine(to: highPoint)
        decayAreaPath.close()
        if useGradient {
            context?.drawLinearGradient(in: decayAreaPath.cgPath, startingWith: decayColor.cgColor,
                                        finishingWith: sustainColor.cgColor)

        } else {
            decayColor.setFill()
            decayAreaPath.fill()
        }

        context?.restoreGState()

        //// attackArea Drawing
        context?.saveGState()

        let attackAreaPath = UIBezierPath()
        attackAreaPath.move(to: initialPoint)
        attackAreaPath.addLine(to: highPointAxis)
        attackAreaPath.addLine(to: highPoint)
        attackAreaPath.addCurve(to: initialPoint,
                                controlPoint1: attackCurveControlPoint,
                                controlPoint2: initialPoint)
        attackAreaPath.close()
        if useGradient {
            context?.drawLinearGradient(in: attackAreaPath.cgPath, startingWith: attackColor.cgColor,
                                        finishingWith: decayColor.cgColor)

        } else {
            attackColor.setFill()
            attackAreaPath.fill()
        }

        context?.restoreGState()

        //// Curve Drawing
        context?.saveGState()

        let curvePath = UIBezierPath()
        curvePath.move(to: initialPoint)
        curvePath.addCurve(to: highPoint,
                           controlPoint1: initialPoint,
                           controlPoint2: attackCurveControlPoint)
        curvePath.addCurve(to: sustainPoint,
                           controlPoint1: highPoint,
                           controlPoint2: decayCurveControlPoint)
        curvePath.addLine(to: releasePoint)
        curvePath.addCurve(to: endPoint,
                           controlPoint1: releasePoint,
                           controlPoint2: releaseCurveControlPoint)
        curveColor.setStroke()
        curvePath.lineWidth = curveStrokeWidth
        curvePath.stroke()

        context?.restoreGState()

    }

    private func quadBezier(percent: CGFloat, start: CGFloat, control: CGFloat, end: CGFloat) -> CGFloat {
        let inv = 1.0 - percent
        let pow = inv * inv
        let powPercent = percent * percent
        let output = start * pow + 2.0 * control * inv * percent + end * powPercent
        return output
    }

    /// Draw the view
    override public func draw(_ rect: CGRect) {
        drawCurveCanvas(size: rect.size,
                        attack: CGFloat(attack),
                        decay: CGFloat(decay),
                        sustain: 1.0 - CGFloat(sustain),
                        release: CGFloat(release),
                        attackPadPercentage: attackPaddingPercent,
                        releasePadPercentage: releasePaddingPercent,
                        attackCurve: CGFloat(attackCurve),
                        decayCurve: CGFloat(decayCurve),
                        releaseCurve: CGFloat(releaseCurve))
    }
}

extension CGContext {

    func drawLinearGradient(
        in path: CGPath,
        startingWith startColor: CGColor,
        finishingWith endColor: CGColor,
        horizontal: Bool = true
    ) {
        guard let gradient = generateGradient(startColor: startColor, endColor: endColor)
        else { return }
        let rect = path.boundingBox
        let startPoint = getStartAndEndPoint(rect: rect, horizontal: horizontal).0
        let endPoint = getStartAndEndPoint(rect: rect, horizontal: horizontal).1

        saveGState()

        addPath(path)

        clipAndDrawGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint)

        restoreGState()
    }

    func drawLinearGradient(
        in rect: CGRect,
        startingWith startColor: CGColor,
        finishingWith endColor: CGColor,
        horizontal: Bool = true
    ) {
        guard let gradient = generateGradient(startColor: startColor, endColor: endColor)
        else { return }
        let startPoint = getStartAndEndPoint(rect: rect, horizontal: horizontal).0
        let endPoint = getStartAndEndPoint(rect: rect, horizontal: horizontal).1

        saveGState()

        addRect(rect)

        clipAndDrawGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint)

        restoreGState()
    }

    private func generateGradient( startColor: CGColor,
                                   endColor: CGColor) -> CGGradient? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations = [0.0, 1.0] as [CGFloat]
        let colors = [startColor, endColor] as CFArray
        return CGGradient( colorsSpace: colorSpace, colors: colors, locations: locations)
    }

    private func getStartAndEndPoint(rect: CGRect, horizontal: Bool = true) -> (CGPoint, CGPoint) {
        let startPoint = CGPoint(x: horizontal ? rect.minX : rect.midX, y: horizontal ? rect.midY : rect.minY)
        let endPoint = CGPoint(x: horizontal ? rect.maxX : rect.midX, y: horizontal ?  rect.midY : rect.maxY)
        return (startPoint, endPoint)
    }

    private func clipAndDrawGradient(gradient: CGGradient, startPoint: CGPoint, endPoint: CGPoint) {
        clip()
        drawLinearGradient(
            gradient,
            start: startPoint,
            end: endPoint,
            options: CGGradientDrawingOptions()
        )
    }
}

extension CGPoint {
    func midPoint(_ other: CGPoint) -> CGPoint {
        return CGPoint(x: (self.x + other.x) / 2.0,
                       y: (self.y + other.y) / 2.0)
    }
}


#else

import AVFoundation
import Cocoa

/// Call back for values for attack, decay, sustain, and release parameters
public typealias ADSRCallback = (AUValue, AUValue, AUValue, AUValue) -> Void

/// A click and draggable view of an ADSR Envelope (Atttack, Decay, Sustain, Release)
public class ADSRView: NSView {

    /// Attack Duration
    public var attackDuration: AUValue = 0.1
    /// Decay Duration
    public var decayDuration: AUValue = 0.1
    /// Sustain Level
    public var sustainLevel: AUValue = 0.1
    /// Release Duration
    public var releaseDuration: AUValue = 0.1

    var decaySustainTouchAreaPath = NSBezierPath()
    var attackTouchAreaPath = NSBezierPath()
    var releaseTouchAreaPath = NSBezierPath()

    /// Background Color
    public var backgroundColor = NSColor.black

    /// Callback to call as parameters change
    public var callback: ADSRCallback
    var currentDragArea = ""

    var lastPoint = CGPoint.zero

    /// React to mouse down
    override public func mouseDown(with theEvent: NSEvent) {
        let touchLocation = convert(theEvent.locationInWindow, from: nil)
        if decaySustainTouchAreaPath.contains(touchLocation) {
            currentDragArea = "ds"
        }
        if attackTouchAreaPath.contains(touchLocation) {
            currentDragArea = "a"
        }
        if releaseTouchAreaPath.contains(touchLocation) {
            currentDragArea = "r"
        }
        lastPoint = touchLocation
        needsDisplay = true
    }

    /// React to mouse dragging
    override public func mouseDragged(with theEvent: NSEvent) {
        let touchLocation = convert(theEvent.locationInWindow, from: nil)

        if currentDragArea != "" {
            if currentDragArea == "ds" {
                sustainLevel = 1.0 - AUValue(touchLocation.y) / AUValue(frame.height)
                decayDuration += AUValue(touchLocation.x - lastPoint.x) / 1_000.0
            }
            if currentDragArea == "a" {
                attackDuration += AUValue(touchLocation.x - lastPoint.x) / 1_000.0
                attackDuration -= AUValue(touchLocation.y - lastPoint.y) / 1_000.0
            }
            if currentDragArea == "r" {
                releaseDuration += AUValue(touchLocation.x - lastPoint.x) / 500.0
                releaseDuration -= AUValue(touchLocation.y - lastPoint.y) / 500.0
            }
        }
        if attackDuration < 0 { attackDuration = 0 }
        if decayDuration < 0 { decayDuration = 0 }
        if releaseDuration < 0 { releaseDuration = 0 }
        if sustainLevel < 0 { sustainLevel = 0 }
        if sustainLevel > 1 { sustainLevel = 1 }

        callback(attackDuration, decayDuration, sustainLevel, releaseDuration)
        lastPoint = touchLocation
        needsDisplay = true
    }

    /// Initialize with size and callback
    /// - Parameters:
    ///   - frame: View size
    ///   - callback: Callback to call as values change
    public init(frame: CGRect = CGRect(width: 440, height: 150),
                callback: @escaping ADSRCallback) {
        self.callback = callback
        super.init(frame: frame)
    }

    /// Required,  but unimplemented initializer
    /// - Parameter aDecoder: Decoder
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func drawCurveCanvas(size: NSSize = NSSize(width: 440, height: 151),
                         attackDurationMS: CGFloat = 456,
                         decayDurationMS: CGFloat = 262,
                         releaseDurationMS: CGFloat = 448,
                         sustainLevel: CGFloat = 0.583,
                         maxADFraction: CGFloat = 0.75) {
        //// General Declarations
        _ = NSGraphicsContext.current?.cgContext

        //// Color Declarations
        let attackColor = #colorLiteral(red: 0.767, green: 0, blue: 0, alpha: 1)
        let decayColor = #colorLiteral(red: 0.942, green: 0.648, blue: 0, alpha: 1)
        let sustainColor = #colorLiteral(red: 0.32, green: 0.8, blue: 0.616, alpha: 1)
        let releaseColor = #colorLiteral(red: 0.72, green: 0.519, blue: 0.888, alpha: 1)
        let bgColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        wantsLayer = true
        layer?.backgroundColor = bgColor.cgColor

        //// Variable Declarations
        let attackClickRoom = CGFloat(30) // to allow the attack to be clicked even if is zero
        let oneSecond: CGFloat = 0.7 * size.width
        let initialPoint = NSPoint(x: attackClickRoom, y: size.height)
        let curveStrokeWidth: CGFloat = min(max(1, size.height / 50.0), max(1, size.width / 100.0))
        let buffer = CGFloat(10) // curveStrokeWidth / 2.0 // make a little room for drwing the stroke
        let endAxes = NSPoint(x: size.width, y: size.height)
        let releasePoint = NSPoint(x: attackClickRoom + oneSecond,
                                   y: sustainLevel * (size.height - buffer) + buffer)
        let endPoint = NSPoint(x: releasePoint.x + releaseDurationMS / 1_000.0 * oneSecond,
                               y: size.height)
        let endMax = NSPoint(x: min(endPoint.x, size.width), y: buffer)
        let releaseAxis = NSPoint(x: releasePoint.x, y: endPoint.y)
        let releaseMax = NSPoint(x: releasePoint.x, y: buffer)
        let highPoint = NSPoint(x: attackClickRoom +
            min(oneSecond * maxADFraction, attackDurationMS / 1_000.0 * oneSecond),
                                y: buffer)
        let highPointAxis = NSPoint(x: highPoint.x, y: size.height)
        let highMax = NSPoint(x: highPoint.x, y: buffer)
        let sustainPoint = NSPoint(
            x: max(highPoint.x, attackClickRoom +
                min(oneSecond * maxADFraction,
                    (attackDurationMS + decayDurationMS) / 1_000.0 * oneSecond)),
            y: sustainLevel * (size.height - buffer) + buffer)
        let sustainAxis = NSPoint(x: sustainPoint.x, y: size.height)
        let initialMax = NSPoint(x: 0, y: buffer)

        let initialToHighControlPoint = NSPoint(x: initialPoint.x, y: highPoint.y)
        let highToSustainControlPoint = NSPoint(x: highPoint.x, y: sustainPoint.y)
        let releaseToEndControlPoint = NSPoint(x: releasePoint.x, y: endPoint.y)

        //// attackTouchArea Drawing
        NSGraphicsContext.saveGraphicsState()

        attackTouchAreaPath = NSBezierPath()
        attackTouchAreaPath.move(to: NSPoint(x: 0, y: size.height))
        attackTouchAreaPath.line(to: highPointAxis)
        attackTouchAreaPath.line(to: highMax)
        attackTouchAreaPath.line(to: initialMax)
        attackTouchAreaPath.line(to: NSPoint(x: 0, y: size.height))
        attackTouchAreaPath.close()
        backgroundColor.setFill()
        attackTouchAreaPath.fill()

        NSGraphicsContext.restoreGraphicsState()

        //// decaySustainTouchArea Drawing
        NSGraphicsContext.saveGraphicsState()

        decaySustainTouchAreaPath = NSBezierPath()
        decaySustainTouchAreaPath.move(to: highPointAxis)
        decaySustainTouchAreaPath.line(to: releaseAxis)
        decaySustainTouchAreaPath.line(to: releaseMax)
        decaySustainTouchAreaPath.line(to: highMax)
        decaySustainTouchAreaPath.line(to: highPointAxis)
        decaySustainTouchAreaPath.close()
        backgroundColor.setFill()
        decaySustainTouchAreaPath.fill()

        NSGraphicsContext.restoreGraphicsState()

        //// releaseTouchArea Drawing
        NSGraphicsContext.saveGraphicsState()

        releaseTouchAreaPath = NSBezierPath()
        releaseTouchAreaPath.move(to: releaseAxis)
        releaseTouchAreaPath.line(to: endAxes)
        releaseTouchAreaPath.line(to: endMax)
        releaseTouchAreaPath.line(to: releaseMax)
        releaseTouchAreaPath.line(to: releaseAxis)
        releaseTouchAreaPath.close()
        backgroundColor.setFill()
        releaseTouchAreaPath.fill()

        NSGraphicsContext.restoreGraphicsState()

        //// releaseArea Drawing
        NSGraphicsContext.saveGraphicsState()

        let releaseAreaPath = NSBezierPath()
        releaseAreaPath.move(to: releaseAxis)
        releaseAreaPath.curve(to: endPoint,
                              controlPoint1: releaseAxis,
                              controlPoint2: endPoint)
        releaseAreaPath.curve(to: releasePoint,
                              controlPoint1: releaseToEndControlPoint,
                              controlPoint2: releasePoint)
        releaseAreaPath.line(to: releaseAxis)
        releaseAreaPath.close()
        releaseColor.setFill()
        releaseAreaPath.fill()

        NSGraphicsContext.restoreGraphicsState()

        //// sustainArea Drawing
        NSGraphicsContext.saveGraphicsState()

        let sustainAreaPath = NSBezierPath()
        sustainAreaPath.move(to: sustainAxis)
        sustainAreaPath.line(to: releaseAxis)
        sustainAreaPath.line(to: releasePoint)
        sustainAreaPath.line(to: sustainPoint)
        sustainAreaPath.line(to: sustainAxis)
        sustainAreaPath.close()
        sustainColor.setFill()
        sustainAreaPath.fill()

        NSGraphicsContext.restoreGraphicsState()

        //// decayArea Drawing
        NSGraphicsContext.saveGraphicsState()

        let decayAreaPath = NSBezierPath()
        decayAreaPath.move(to: highPointAxis)
        decayAreaPath.line(to: sustainAxis)
        decayAreaPath.curve(to: sustainPoint,
                            controlPoint1: sustainAxis,
                            controlPoint2: sustainPoint)
        decayAreaPath.curve(to: highPoint,
                            controlPoint1: highToSustainControlPoint,
                            controlPoint2: highPoint)
        decayAreaPath.line(to: highPoint)
        decayAreaPath.close()
        decayColor.setFill()
        decayAreaPath.fill()

        NSGraphicsContext.restoreGraphicsState()

        //// attackArea Drawing
        NSGraphicsContext.saveGraphicsState()

        let attackAreaPath = NSBezierPath()
        attackAreaPath.move(to: initialPoint)
        attackAreaPath.line(to: highPointAxis)
        attackAreaPath.line(to: highPoint)
        attackAreaPath.curve(to: initialPoint,
                             controlPoint1: initialToHighControlPoint,
                             controlPoint2: initialPoint)
        attackAreaPath.close()
        attackColor.setFill()
        attackAreaPath.fill()

        NSGraphicsContext.restoreGraphicsState()

        //// Curve Drawing
        NSGraphicsContext.saveGraphicsState()

        let curvePath = NSBezierPath()
        curvePath.move(to: initialPoint)
        curvePath.curve(to: highPoint,
                        controlPoint1: initialPoint,
                        controlPoint2: initialToHighControlPoint)
        curvePath.curve(to: sustainPoint,
                        controlPoint1: highPoint,
                        controlPoint2: highToSustainControlPoint)
        curvePath.line(to: releasePoint)
        curvePath.curve(to: endPoint,
                        controlPoint1: releasePoint,
                        controlPoint2: releaseToEndControlPoint)
        NSColor.black.setStroke()
        curvePath.lineWidth = curveStrokeWidth
        curvePath.stroke()

        NSGraphicsContext.restoreGraphicsState()
    }

    /// Draw the ADSR View
    /// - Parameter rect: Rectangle to draw in
    override public func draw(_ rect: CGRect) {
        drawCurveCanvas(size: rect.size,
                        attackDurationMS: CGFloat(attackDuration * 1_000),
                        decayDurationMS: CGFloat(decayDuration * 1_000),
                        releaseDurationMS: CGFloat(releaseDuration * 500),
                        sustainLevel: CGFloat(1.0 - sustainLevel))
    }
}
#endif
