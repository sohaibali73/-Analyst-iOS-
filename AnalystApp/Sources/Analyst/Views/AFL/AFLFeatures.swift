import SwiftUI

// MARK: - AFL Template System

/// Pre-built AFL strategy templates
enum AFLTemplate: String, CaseIterable, Identifiable {
    case movingAverageCrossover = "Moving Average Crossover"
    case rsiOverbought = "RSI Overbought/Oversold"
    case bollingerBands = "Bollinger Bands Breakout"
    case macdSignal = "MACD Signal Cross"
    case volumeBreakout = "Volume Breakout"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .movingAverageCrossover: return "arrow.left.arrow.right"
        case .rsiOverbought: return "gauge"
        case .bollingerBands: return "waveform.path"
        case .macdSignal: return "signal"
        case .volumeBreakout: return "chart.bar.fill"
        }
    }
    
    var description: String {
        switch self {
        case .movingAverageCrossover:
            return "Buy when fast MA crosses above slow MA, sell on opposite cross"
        case .rsiOverbought:
            return "Buy when RSI is oversold, sell when overbought"
        case .bollingerBands:
            return "Buy on lower band bounce, sell on upper band touch"
        case .macdSignal:
            return "Trade on MACD line crossing the signal line"
        case .volumeBreakout:
            return "Enter when volume exceeds threshold with price movement"
        }
    }
    
    var parameters: [AFLParameter] {
        switch self {
        case .movingAverageCrossover:
            return [
                AFLParameter(name: "FastMA", type: .number, defaultValue: 10, min: 5, max: 50),
                AFLParameter(name: "SlowMA", type: .number, defaultValue: 20, min: 10, max: 200),
                AFLParameter(name: "MAType", type: .options, defaultValue: "SMA", options: ["SMA", "EMA", "WMA"])
            ]
        case .rsiOverbought:
            return [
                AFLParameter(name: "RSIPeriod", type: .number, defaultValue: 14, min: 5, max: 30),
                AFLParameter(name: "Overbought", type: .number, defaultValue: 70, min: 60, max: 90),
                AFLParameter(name: "Oversold", type: .number, defaultValue: 30, min: 10, max: 40)
            ]
        case .bollingerBands:
            return [
                AFLParameter(name: "Period", type: .number, defaultValue: 20, min: 10, max: 50),
                AFLParameter(name: "StdDev", type: .number, defaultValue: 2.0, min: 1.0, max: 3.0),
                AFLParameter(name: "MAType", type: .options, defaultValue: "SMA", options: ["SMA", "EMA"])
            ]
        case .macdSignal:
            return [
                AFLParameter(name: "FastPeriod", type: .number, defaultValue: 12, min: 5, max: 26),
                AFLParameter(name: "SlowPeriod", type: .number, defaultValue: 26, min: 12, max: 52),
                AFLParameter(name: "SignalPeriod", type: .number, defaultValue: 9, min: 5, max: 20)
            ]
        case .volumeBreakout:
            return [
                AFLParameter(name: "VolumePeriod", type: .number, defaultValue: 20, min: 10, max: 50),
                AFLParameter(name: "VolumeMultiplier", type: .number, defaultValue: 2.0, min: 1.5, max: 5.0),
                AFLParameter(name: "PriceChange", type: .number, defaultValue: 3.0, min: 1.0, max: 10.0)
            ]
        }
    }
}

// MARK: - AFL Parameter

struct AFLParameter: Identifiable {
    let id = UUID()
    let name: String
    let type: ParameterType
    let defaultValue: Any
    let min: Double?
    let max: Double?
    let options: [String]?
    
    init(name: String, type: ParameterType, defaultValue: Any, min: Double? = nil, max: Double? = nil, options: [String]? = nil) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.min = min
        self.max = max
        self.options = options
    }
    
    enum ParameterType {
        case number
        case options
        case boolean
        case text
    }
}

// MARK: - Template Picker View

struct AFLTemplatePicker: View {
    @Binding var selectedTemplate: AFLTemplate?
    let onSelect: (AFLTemplate) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AFLTemplate.allCases) { template in
                    AFLTemplateCard(
                        template: template,
                        isSelected: selectedTemplate == template
                    ) {
                        selectedTemplate = template
                        onSelect(template)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct AFLTemplateCard: View {
    let template: AFLTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: template.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .black : .potomacYellow)
                
                Text(template.rawValue)
                    .font(.quicksandSemiBold(12))
                    .foregroundColor(isSelected ? .black : .white)
                    .lineLimit(1)
                
                Text(template.description)
                    .font(.quicksandRegular(10))
                    .foregroundColor(isSelected ? .black.opacity(0.6) : .white.opacity(0.4))
                    .lineLimit(2)
            }
            .frame(width: 140, height: 100, alignment: .leading)
            .padding(12)
            .background(isSelected ? Color.potomacYellow : Color.white.opacity(0.04))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.potomacYellow : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Parameter Input View

struct AFLParameterInputView: View {
    let parameter: AFLParameter
    @Binding var value: Any
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(parameter.name)
                .font(.quicksandSemiBold(12))
                .foregroundColor(.white.opacity(0.7))
            
            switch parameter.type {
            case .number:
                if let min = parameter.min, let max = parameter.max {
                    SliderWithInput(
                        value: Binding(
                            get: { value as? Double ?? parameter.defaultValue as? Double ?? 0 },
                            set: { value = $0 }
                        ),
                        range: min...max
                    )
                } else {
                    HStack {
                        TextField("Value", text: Binding(
                            get: { String(describing: value) },
                            set: { value = Double($0) ?? parameter.defaultValue }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                }
                
            case .options:
                if let options = parameter.options {
                    Picker("", selection: Binding(
                        get: { value as? String ?? parameter.defaultValue as? String ?? "" },
                        set: { value = $0 }
                    )) {
                        ForEach(options, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
            case .boolean:
                Toggle("", isOn: Binding(
                    get: { value as? Bool ?? false },
                    set: { value = $0 }
                ))
                .toggleStyle(.switch)
                
            case .text:
                TextField("Enter value", text: Binding(
                    get: { value as? String ?? "" },
                    set: { value = $0 }
                ))
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}

struct SliderWithInput: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        HStack(spacing: 12) {
            Slider(value: $value, in: range)
                .tint(.potomacYellow)
            
            Text(String(format: "%.1f", value))
                .font(.quicksandSemiBold(12))
                .foregroundColor(.potomacYellow)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

// MARK: - AFL History View

struct AFLHistoryView: View {
    @State private var history: [AFLHistoryItem] = []
    @State private var selectedItem: AFLHistoryItem?
    
    var body: some View {
        List {
            ForEach(history) { item in
                AFLHistoryItemRow(item: item)
                    .onTapGesture {
                        selectedItem = item
                    }
            }
            .onDelete(perform: deleteItems)
        }
        .listStyle(.plain)
    }
    
    private func deleteItems(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
    }
}

struct AFLHistoryItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let code: String
    let createdAt: Date
    let template: String?
    
    init(title: String, code: String, template: String? = nil) {
        self.id = UUID()
        self.title = title
        self.code = code
        self.createdAt = Date()
        self.template = template
    }
}

struct AFLHistoryItemRow: View {
    let item: AFLHistoryItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 16))
                .foregroundColor(.potomacYellow)
                .frame(width: 32, height: 32)
                .background(Color.potomacYellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.quicksandSemiBold(13))
                    .foregroundColor(.white)
                
                Text(item.createdAt, style: .relative)
                    .font(.quicksandRegular(11))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Code Preview with Actions

struct AFLCodePreview: View {
    let code: String
    @State private var isCopied = false
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("AFL")
                    .font(.firaCode(10))
                    .foregroundColor(.potomacYellow.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.potomacYellow.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Button {
                    copyCode()
                } label: {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundColor(isCopied ? .green : .white.opacity(0.5))
                }
                
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.03))
            
            // Code
            ScrollView {
                Text(code)
                    .font(.firaCode(12))
                    .foregroundColor(.white.opacity(0.85))
                    .textSelection(.enabled)
                    .padding()
            }
            .frame(maxHeight: 300)
        }
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [code])
        }
    }
    
    private func copyCode() {
        UIPasteboard.general.string = code
        HapticManager.shared.success()
        
        withAnimation(AnimationProvider.quick) {
            isCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(AnimationProvider.quick) {
                isCopied = false
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Strategy Validation View

struct AFLValidationView: View {
    let errors: [AFLError]
    let warnings: [AFLWarning]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !errors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Errors")
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(.chartRed)
                    
                    ForEach(errors) { error in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.chartRed)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(error.message)
                                    .font(.quicksandRegular(12))
                                    .foregroundColor(.white)
                                
                                if let line = error.line {
                                    Text("Line \(line)")
                                        .font(.quicksandRegular(10))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.chartRed.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            if !warnings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Warnings")
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(.chartOrange)
                    
                    ForEach(warnings) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.chartOrange)
                            
                            Text(warning.message)
                                .font(.quicksandRegular(12))
                                .foregroundColor(.white)
                        }
                        .padding(10)
                        .background(Color.chartOrange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct AFLError: Identifiable {
    let id = UUID()
    let message: String
    let line: Int?
    
    init(message: String, line: Int? = nil) {
        self.message = message
        self.line = line
    }
}

struct AFLWarning: Identifiable {
    let id = UUID()
    let message: String
}