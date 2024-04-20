<div align=center>
<img src="https://github.com/AudioKit/Cookbook/raw/main/Cookbook/Cookbook/Assets.xcassets/audiokit-icon.imageset/audiokit-icon.png" width="20%"/>

# AudioKit User Interfaces

[![Build Status](https://github.com/AudioKit/AudioKitUI/workflows/CI/badge.svg)](https://github.com/AudioKit/AudioKitUI/actions?query=workflow%3ACI)
[![License](https://img.shields.io/github/license/AudioKit/AudioKitUI)](https://github.com/AudioKit/AudioKitUI/blob/main/LICENSE)
[![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAudioKit%2FAudioKitUI%2Fbadge%3Ftype%3Dswift-versions&label=)](https://swiftpackageindex.com/AudioKit/AudioKitUI)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAudioKit%2FAudioKitUI%2Fbadge%3Ftype%3Dplatforms&label=)](https://swiftpackageindex.com/AudioKit/AudioKitUI)
[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)
[![Twitter Follow](https://img.shields.io/twitter/follow/AudioKitPro.svg?style=social)](https://twitter.com/AudioKitPro)

</div>

Waveform plots and controls that can be used to jump start your AudioKit-powered app.

## Documentation

Complete API reference appears in the [AudioKit.io web site](https://www.audiokit.io/AudioKitUI/documentation/audiokitui)

## Requirements

We use SwiftUI so you need to target iOS 13+ and macOS 10.15+.

## Installation via Swift Package Manager

To add AudioKitUI to your Xcode project, select File -> Swift Packages -> Add Package Dependency. Enter `https://github.com/AudioKit/AudioKitUI` for the URL.

## Examples

Just like AudioKit, the example project for AudioKitUI is the [AudioKit Cookbook](https://github.com/AudioKit/Cookbook/).

## More!

Because some user interfaces are quite complex, and don't really have AudioKit as a dependency, they are in other repositories under the AudioKit umbrella:

* Controls: SwiftUI Knobs, Sliders, X-Y Pads, and more [github.com/AudioKit/Controls](https://github.com/AudioKit/Controls)
* Flow: Generic node graph editor [github.com/AudioKit/Flow](https://github.com/AudioKit/Flow) 
* Keyboard: SwiftUI music keyboard [github.com/AudioKit/Keyboard](https://github.com/AudioKit/Keyboard)
* Piano Roll: Touch oriented piano roll [github.com/AudioKit/PianoRoll](https://github.com/AudioKit/PianoRoll)
* PianoRollEditor: Logic Pro like piano roll editor [github.com/AudioKit/PianoRollEditor](https://github.com/AudioKit/PianoRollEditor)
* MIDITrackView: View representing a MIDI Track [github.com/AudioKit/MIDITrackView](https://github.com/AudioKit/MIDITrackView)
* Waveform: GPU accelerated waveform view [github.com/AudioKit/Waveform](https://github.com/AudioKit/Waveform)
