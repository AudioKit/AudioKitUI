// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/
/* 
 Dataflow overview:
 * FFTTap analyzed the sound and creates an array of frequencies and amplitudes 
   several times per second. As soon as the data is ready, a new slice is instantiated. 
   On init, the slice converts the array of measurements to an image and caches it.
   The conversion of data and creating an image takes quite some time and is 
   done only once.
* Drawing is done using UIGraphicsImageRenderer with context.fill primitives. 
   These are cached as UImage and layouted onto the view. 
 
 
Steps involved: 
 * FFTTap calls SpectrogramFlatModel with newly analyzed sound using 
    ``SpectrogramFlatModel/pushData(_ fftFloats: [Float])`` 
 * The model then creates a SpectrogramSlice and puts it into the queue.
 * Body of this view watches this queue and shows all slices in the queue.
 * Because the body and therefore each slice is redrawn on any update of 
    the queue, the drawing of the slice should be fast. Current implementation 
    of SpectrogramSlice caches an image of itself after drawing.
* The image is drawn pixel aligned on a CGContext. The image then is resized
   to fit into this view.
 
 
 Brief history of this class
 * Class was created using SpectrogramView as starting point
 * SpectrogramView looked/looks like coming from an 90ies japanese synth, 
    in a kind of 3D surface which is cool. Most common spectrograms or sonographs 
    have a flat look. 
 * The flat look makes it easier to analyze music, make voice fingerprints and compare bird songs
 * SpectrogramView had/has a major design flaw: on each update (as soon as new data arrived 
    from the FFT), all slices were completely redrawn from raw data. All recent measurements (80)
    are converted from an array of measurements to Paths with all the lines.
 * Measuring with Instruments showed that this takes a lot of time, therefore
   this implementation caches the resulting image.
 
 
 Suggested next steps on development:
 * Layout and draw the slices directly on a Canvas (instead of HStack) and independently move the Canvas left.
 * Make class compatible with macOS 
    - Drawing with Canvas instead of UIGraphicsImageRenderer 
      (caching of UIImage no longer needed if callback can draw directly on one Canvas)
    - CrossPlatformColor from Waveform.swift or Color.Resolved instead of UIColor for gradient lookup
 * Add some parameters that can be changed while the spectrogram is running
    - Pause so user can have a close look at the analyzed past
    - Gain or sensitivity
    - Speed of the rolling plot / detail frequency by adjusting fftSize
    - Min and max frequency shown
 
 
 Cause of inefficiency of this implementation
 * Each time a new slice arrives from FFTTap, the view gets a complete layout update.
 * Rendering of new slices is done on a background thread and involves too many steps
 * Frame rate is defined by how many samples come per second. This look ugly in case of less than 25 per second.
 * It somehow doesn't show the frequency range that is selected, so some cpu time 
    is wasted for calculating stuff that isn't shown. 
 * Some arrays are iterated several times in a row whereas it could be done in one enumeration. 
 
 Following possibilities to be considered for a more energy efficient implementation:
 * Only calc what is shown, enumerate array only once (see comment on captureAmplitudeFrequencyData()). 
 * Make the layouting independent of sample rate, just move the slices left with a continous, builtin animation.
 * Layout and draw the slices directly on a Canvas (instead of HStack) and independently move the Canvas left. 
 * To make it shown crisp, all images should be drawn and layouted pixel aligned (integral size and position).  
 * Try .drawingGroup() if it helps up the performance
 * Use ImageRenderer objectwillchange to create a stream of images
 * Use Sample Code from Apple of vDSP and Accellerate (macOS) and port it to iOS: 
    https://developer.apple.com/documentation/accelerate/visualizing_sound_as_an_audio_spectrogram
 * Spectrogram is actually kind of a Heatmap, so use SwiftUI.Chart
 * Use factory and emitter to emit new slice images (like in a particle system)
 * Measure performance impact when spreading on several threads or combine on main thread
 * Use Metal-API with shaders similar to what aurioTouch Sample Code by Apple did in OpenGL
 * Try to replace all CGPoint and CGPoint[] calculations using Accelerate or some other optimized library 
 * Measure efficiency and compare if it would make a difference to only use opaque colors in gradient
 * By all these possibilites to improve energy efficiency, don't forget the latency.
 * might be easy to make available in earlier versions than iOS 17, primarly because of .onChange(of:

 */

import AudioKit
import SwiftUI

#if !os(macOS) || targetEnvironment(macCatalyst)

/// Displays a rolling plot of the frequency spectrum. 
///
/// Each slice represents a point in time with the frequencies shown from bottom to top
/// at this moment. Each frequency-cell is colored according to the amplitude.
/// The spectrum is shown logarithmic so octaves have the same distance. 
/// 
/// This implementation is rather energy inefficent. You might not want to use it 
/// a central feature in your app. Furthermore it's not scientificicly correct, when displaying
/// white noise, it will not show a uniform distribution.

public struct SpectrogramFlatView: View {
    // this static var is a shortcut: better to have this in SpectrogramModel or SpectrogramFFTMetaData
    public static var gradientUIColors: [UIColor] =  [(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)), (#colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 0.6275583187)), (#colorLiteral(red: 0.4217140079, green: 0.6851614118, blue: 0.9599093795, alpha: 0.8245213468)), (#colorLiteral(red: 0.8122602105, green: 0.6033009887, blue: 0.8759307861, alpha: 1)), (#colorLiteral(red: 0.9826132655, green: 0.5594901443, blue: 0.4263145328, alpha: 1)), (#colorLiteral(red: 1, green: 0.2607713342, blue: 0.4242972136, alpha: 1))]
    @StateObject var spectrogram = SpectrogramFlatModel()
    let node: Node
    let backgroundColor: Color

    /// put only one color into the array for a monochrome view
    public init(node: Node,
                amplitudeColors: [Color] = [],
                backgroundColor: Color = Color.black) {
        self.node = node
        if amplitudeColors.count > 1 {
            Self.gradientUIColors = amplitudeColors.map { UIColor($0) }
        } else if amplitudeColors.count == 1 {
            Self.gradientUIColors = [UIColor(backgroundColor), UIColor(amplitudeColors[0])]
        }
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        return GeometryReader { geometry in
            ZStack {
                backgroundColor
                    .onAppear {
                        spectrogram.updateNode(node)
                    }
                HStack(spacing: 0.0) {
                    ForEach(spectrogram.slices.items) { slice in
                        slice
                    }
                    // flip it so the new slices come in right and move to the left
                    .scaleEffect(x: -1, y: 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }.onAppear {
                spectrogram.sliceSize = calcSliceSize(fromFrameSize: geometry.size)
            }
            .onChange(of: geometry.size) { newSize  in
                spectrogram.sliceSize = calcSliceSize(fromFrameSize: newSize)
            }
        }
    }

    func calcSliceSize(fromFrameSize frameSize: CGSize) -> CGSize {
        let outSize = CGSize(
            // even when we have non-integral width for a slice, the
            // resulting image will be integral in size but resizable
            // the HStack will then layout them not pixel aligned and stretched.
            // that's why we ceil/floor it: ceiling makes them a bit more precise. 
            // floor makes it more energy efficient. 
            // We did some measurements, it's hard to tell visually
            width: floor(frameSize.width / CGFloat(spectrogram.slices.maxItems)),
            height: frameSize.height
        )
        return outSize
    }
}

// MARK: Preview

struct SpectrogramFlatView_Previews: PreviewProvider {
    static var previews: some View {
        return SpectrogramFlatView(node: Mixer())
    }
}

#endif
