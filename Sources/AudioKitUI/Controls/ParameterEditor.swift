// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import SwiftUI
import AudioKit

/// Hack to get SwiftUI to poll and refresh our UI.
class Refresher: ObservableObject {
    @Published var version = 0
}

public struct ParameterEditor: View {
    var param: NodeParameter
    @StateObject var refresher = Refresher()

    public init(param: NodeParameter) {
        self.param = param
    }

    func getBinding() -> Binding<Float> {
        Binding(get: { param.value }, set: { param.value = $0; refresher.version += 1; })
    }

    func getIntBinding() -> Binding<Int> {
        Binding(get: { Int(param.value) }, set: { param.value = AUValue($0); refresher.version += 1; })
    }

    func intValues() -> Array<Int> {
        Array(Int(param.range.lowerBound)...Int(param.range.upperBound))
    }

    public var body: some View {
        VStack(alignment: .leading) {
            Text("\(param.def.name): \(param.value)").font(.caption)

            switch param.def.unit {
            case .boolean:
                Toggle(isOn: Binding(get: { param.value == 1.0 }, set: {
                    param.value = $0 ? 1.0 : 0.0; refresher.version += 1;
                }), label: { Text(param.def.name) })
            case .indexed:
                if param.range.upperBound - param.range.lowerBound < 5 {
                    Picker(param.def.name, selection: getIntBinding()) {
                        ForEach(intValues(), id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                } else {
                    Slider(value: getBinding(),
                           in: param.range,
                           step: 1.0,
                           label: { Text(param.def.name).frame(width: 200, alignment: .leading) },
                           minimumValueLabel: { Text(String(format: "%.0f", param.range.lowerBound)) },
                           maximumValueLabel: { Text(String(format: "%.0f", param.range.upperBound)) } )
                }
            default:
                Slider(value: getBinding(),
                       in: param.range,
                       label: { Text(param.def.name).frame(width: 200, alignment: .leading) },
                       minimumValueLabel: { Text(String(format: "%.2f", param.range.lowerBound)) },
                       maximumValueLabel: { Text(String(format: "%.2f", param.range.upperBound)) })
            }
        }
    }
}
