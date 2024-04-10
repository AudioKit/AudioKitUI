import SwiftUI

// MARK: MorphableShape

struct MorphableShape: Shape {
    var controlPoints: AnimatableVector

    var animatableData: AnimatableVector {
        set { controlPoints = newValue }
        get { return controlPoints }
    }

    func point(x: Double, y: Double, rect: CGRect) -> CGPoint {
        // vector values are expected to by in the range of 0...1
        return CGPoint(x: Double(rect.width) * x, y: Double(rect.height) * y)
    }

    func path(in rect: CGRect) -> Path {
        return Path { path in

            path.move(to: self.point(x: self.controlPoints.values[0],
                                     y: self.controlPoints.values[1], rect: rect))

            var i = 2
            while i < self.controlPoints.values.count - 1 {
                path.addLine(to: self.point(x: self.controlPoints.values[i],
                                            y: self.controlPoints.values[i + 1], rect: rect))
                i += 2
            }
        }
    }
}

/// Return points at a given offset and create AnimatableVector for control points
extension Path {
    /// return point at the curve
    func point(at offset: CGFloat) -> CGPoint {
        let limitedOffset = min(max(offset, 0), 1)
        guard limitedOffset > 0 else { return cgPath.currentPoint }
        return trimmedPath(from: 0, to: limitedOffset).cgPath.currentPoint
    }

    /// return control points along the path
    func controlPoints(count: Int) -> AnimatableVector {
        var retPoints = [Double]()
        for index in 0 ..< count {
            let pathOffset = Double(index) / Double(count)
            let pathPoint = point(at: CGFloat(pathOffset))
            retPoints.append(Double(pathPoint.x))
            retPoints.append(Double(pathPoint.y))
        }
        return AnimatableVector(with: retPoints)
    }
}

// MARK: AnimatableVector

struct AnimatableVector: VectorArithmetic {
    var values: [Double] // vector values

    init(count: Int = 1) {
        values = [Double](repeating: 0.0, count: count)
        magnitudeSquared = 0.0
    }

    init(with values: [Double]) {
        self.values = values
        magnitudeSquared = 0
        recomputeMagnitude()
    }

    func computeMagnitude() -> Double {
        // compute square magnitued of the vector
        // = sum of all squared values
        var sum = 0.0

        for index in 0 ..< values.count {
            sum += values[index] * values[index]
        }

        return Double(sum)
    }

    mutating func recomputeMagnitude() {
        magnitudeSquared = computeMagnitude()
    }

    // MARK: VectorArithmetic

    var magnitudeSquared: Double // squared magnitude of the vector

    mutating func scale(by rhs: Double) {
        // scale vector with a scalar
        // = each value is multiplied by rhs
        for index in 0 ..< values.count {
            values[index] *= rhs
        }
        magnitudeSquared = computeMagnitude()
    }

    // MARK: AdditiveArithmetic

    // zero is identity element for aditions
    // = all values are zero
    static var zero = AnimatableVector()

    static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        var retValues = [Double]()

        for index in 0 ..< min(lhs.values.count, rhs.values.count) {
            retValues.append(lhs.values[index] + rhs.values[index])
        }

        return AnimatableVector(with: retValues)
    }

    static func += (lhs: inout AnimatableVector, rhs: AnimatableVector) {
        for index in 0 ..< min(lhs.values.count, rhs.values.count) {
            lhs.values[index] += rhs.values[index]
        }
        lhs.recomputeMagnitude()
    }

    static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        var retValues = [Double]()

        for index in 0 ..< min(lhs.values.count, rhs.values.count) {
            retValues.append(lhs.values[index] - rhs.values[index])
        }

        return AnimatableVector(with: retValues)
    }

    static func -= (lhs: inout AnimatableVector, rhs: AnimatableVector) {
        for index in 0 ..< min(lhs.values.count, rhs.values.count) {
            lhs.values[index] -= rhs.values[index]
        }
        lhs.recomputeMagnitude()
    }
}
