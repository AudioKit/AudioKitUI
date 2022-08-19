// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKitUI/

import AudioKit
import AudioUnit
import SwiftUI

class ParameterEditorModel: ObservableObject {
    @Published var value: AUValue = 0 {
        didSet {
            if let param = param {
                param.value = value
            }
        }
    }

    var paramToken: AUParameterObserverToken?

    var param: NodeParameter? {
        didSet {
            guard let param = param else { return }
            value = param.value
            paramToken = param.parameter.token { [weak self] _, newValue in
                DispatchQueue.main.async {
                    self?.value = newValue
                }
            }
        }
    }
}

public struct ParameterEditor: View {
    var param: NodeParameter
    @StateObject var model = ParameterEditorModel()

    public init(param: NodeParameter) {
        self.param = param
    }

    func getIntBinding() -> Binding<Int> {
        Binding(get: { Int(model.value) }, set: { model.value = AUValue($0) })
    }

    func intValues() -> [Int] {
        Array(Int(param.range.lowerBound) ... Int(param.range.upperBound))
    }

    public var body: some View {
        VStack(alignment: .leading) {
            Text("\(param.def.name): \(param.value)").font(.caption)

            switch param.def.unit {
            case .boolean:
                Toggle(isOn: Binding(get: { param.value == 1.0 }, set: {
                    param.value = $0 ? 1.0 : 0.0
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
                    Slider(value: $model.value,
                           in: param.range,
                           step: 1.0,
                           label: { Text(param.def.name).frame(width: 200, alignment: .leading) },
                           minimumValueLabel: { Text(String(format: "%.0f", param.range.lowerBound)) },
                           maximumValueLabel: { Text(String(format: "%.0f", param.range.upperBound)) })
                }
            default:
                Slider(value: $model.value,
                       in: param.range,
                       label: { Text(param.def.name).frame(width: 200, alignment: .leading) },
                       minimumValueLabel: { Text(String(format: "%.2f", param.range.lowerBound)) },
                       maximumValueLabel: { Text(String(format: "%.2f", param.range.upperBound)) })
            }
        }.onAppear {
            model.param = param
        }
    }
}
