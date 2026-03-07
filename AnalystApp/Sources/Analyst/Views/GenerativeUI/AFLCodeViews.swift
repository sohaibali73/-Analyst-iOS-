import SwiftUI

// MARK: - AFL Generate Card

struct AFLGenerateResult {
    let success: Bool
    let error: String?
    let description: String?
    let strategyType: String?
    let aflCode: String?
    let explanation: String?
    let toolTimeMs: Int?
    
    static func from(toolCall: ToolCall) -> AFLGenerateResult {
        let result = toolCall.resultDict
        
        return AFLGenerateResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            description: result["description"] as? String ?? toolCall.argumentsDict["description"] as? String,
            strategyType: result["strategy_type"] as? String,
            aflCode: result["afl_code"] as? String,
            explanation: result["explanation"] as? String,
            toolTimeMs: result["_tool_time_ms"] as? Int
        )
    }
}

struct AFLGenerateCardView: View {
    let result: AFLGenerateResult
    
    @State private var copied = false
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "AFL Generation Failed", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.potomacYellow)
                    
                    Text("AFL Code Generated")
                        .font(.quicksandSemiBold(13))
                        .foregroundColor(.potomacYellow)
                    
                    if let strategyType = result.strategyType {
                        Text(strategyType)
                            .font(.quicksandSemiBold(11))
                            .foregroundColor(.potomacYellow)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.potomacYellow.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    if let time = result.toolTimeMs {
                        Text("\(time)ms")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    
                    Button {
                        if let code = result.aflCode {
                            ClipboardManager.copy()
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copied = false
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12))
                            Text(copied ? "Copied!" : "Copy")
                                .font(.quicksandSemiBold(11))
                        }
                        .foregroundColor(copied ? .chartGreen : .white.opacity(0.5))
                    }
                }
                .padding(16)
                
                if let description = result.description {
                    Text(description)
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.6))
                        .italic()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
                
                // Code
                ScrollView {
                    Text(result.aflCode ?? "No code generated")
                        .font(.firaCode(12))
                        .foregroundColor(Color(hex: "E6EDF3"))
                        .lineSpacing(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .frame(maxHeight: 350)
                .background(Color(hex: "0d1117"))
                
                if let explanation = result.explanation {
                    Divider().overlay(Color.white.opacity(0.06))
                    
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "book")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(explanation)
                            .font(.quicksandRegular(13))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(4)
                    }
                    .padding(16)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.potomacYellow.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - AFL Validate Card

struct AFLValidateResult {
    let success: Bool
    let valid: Bool
    let error: String?
    let errors: [String]
    let warnings: [String]
    let lineCount: Int?
    let hasBuySell: Bool?
    let hasPlot: Bool?
    let toolTimeMs: Int?
    
    static func from(toolCall: ToolCall) -> AFLValidateResult {
        let result = toolCall.resultDict
        
        return AFLValidateResult(
            success: result["success"] as? Bool ?? true,
            valid: result["valid"] as? Bool ?? result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            errors: result["errors"] as? [String] ?? [],
            warnings: result["warnings"] as? [String] ?? [],
            lineCount: result["line_count"] as? Int,
            hasBuySell: result["has_buy_sell"] as? Bool,
            hasPlot: result["has_plot"] as? Bool,
            toolTimeMs: result["_tool_time_ms"] as? Int
        )
    }
}

struct AFLValidateCardView: View {
    let result: AFLValidateResult
    
    private var isValid: Bool {
        result.valid && result.errors.isEmpty
    }
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "AFL Validation Failed", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: isValid ? "checkmark.shield" : "xmark.shield")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isValid ? .chartGreen : .chartRed)
                    
                    Text(isValid ? "AFL Code Valid ✓" : "AFL Validation Issues")
                        .font(.quicksandSemiBold(13))
                        .foregroundColor(isValid ? .chartGreen : .chartRed)
                    
                    Spacer()
                    
                    if let time = result.toolTimeMs {
                        Text("\(time)ms")
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(16)
                
                // Stats
                HStack(spacing: 8) {
                    if let lineCount = result.lineCount {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                            Text("\(lineCount) lines")
                        }
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    if result.hasBuySell == true {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Buy/Sell")
                        }
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(.chartGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.chartGreen.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    if result.hasPlot == true {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("Plot")
                        }
                        .font(.quicksandSemiBold(12))
                        .foregroundColor(.chartPurple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.chartPurple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                // Errors
                if !result.errors.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(result.errors, id: \.self) { error in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.chartRed)
                                
                                Text(error)
                                    .font(.quicksandRegular(12))
                                    .foregroundColor(Color(hex: "F97583"))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                
                // Warnings
                if !result.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(result.warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.chartOrange)
                                
                                Text(warning)
                                    .font(.quicksandRegular(12))
                                    .foregroundColor(Color(hex: "D29922"))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .background(Color(hex: "0d1117"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isValid ? Color.chartGreen.opacity(0.3) : Color.chartRed.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - AFL Debug Card

struct AFLDebugResult {
    let success: Bool
    let error: String?
    let errorMessage: String?
    let fixedCode: String?
    let toolTimeMs: Int?
    
    static func from(toolCall: ToolCall) -> AFLDebugResult {
        let result = toolCall.resultDict
        
        return AFLDebugResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            errorMessage: result["error_message"] as? String,
            fixedCode: result["fixed_code"] as? String,
            toolTimeMs: result["_tool_time_ms"] as? Int
        )
    }
}

struct AFLDebugCardView: View {
    let result: AFLDebugResult
    
    @State private var copied = false
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "AFL Debug Failed", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "ladybug")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.chartPurple)
                    
                    Text("AFL Code Debugged & Fixed")
                        .font(.quicksandSemiBold(13))
                        .foregroundColor(.chartPurple)
                    
                    Spacer()
                    
                    Button {
                        if let code = result.fixedCode {
                            ClipboardManager.copy()
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copied = false
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12))
                            Text(copied ? "Copied!" : "Copy")
                                .font(.quicksandSemiBold(11))
                        }
                        .foregroundColor(copied ? .chartGreen : .white.opacity(0.5))
                    }
                }
                .padding(16)
                
                if let errorMessage = result.errorMessage {
                    Text("Original error: \(errorMessage)")
                        .font(.quicksandRegular(12))
                        .foregroundColor(Color(hex: "F97583"))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
                
                // Fixed code
                ScrollView {
                    Text(result.fixedCode ?? "No fixed code")
                        .font(.firaCode(12))
                        .foregroundColor(Color(hex: "E6EDF3"))
                        .lineSpacing(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .frame(maxHeight: 350)
                .background(Color(hex: "0d1117"))
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.chartPurple.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - AFL Explain Card

struct AFLExplainResult {
    let success: Bool
    let error: String?
    let explanation: String?
    
    static func from(toolCall: ToolCall) -> AFLExplainResult {
        let result = toolCall.resultDict
        
        return AFLExplainResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            explanation: result["explanation"] as? String
        )
    }
}

struct AFLExplainCardView: View {
    let result: AFLExplainResult
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "AFL Explanation Failed", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "book")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.chartBlue)
                    
                    Text("AFL Code Explanation")
                        .font(.quicksandSemiBold(13))
                        .foregroundColor(.chartBlue)
                }
                .padding(16)
                
                ScrollView {
                    Text(result.explanation ?? "No explanation available")
                        .font(.quicksandRegular(13))
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(5)
                        .padding(16)
                }
                .frame(maxHeight: 400)
            }
            .background(Color(hex: "0d1117"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.chartBlue.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - AFL Sanity Check Card

struct AFLSanityCheckResult {
    let success: Bool
    let error: String?
    let originalValid: Bool?
    let totalIssuesFound: Int?
    let autoFixed: Bool?
    let fixesApplied: [String]
    let fixedCode: String?
    let fixedValid: Bool?
    
    static func from(toolCall: ToolCall) -> AFLSanityCheckResult {
        let result = toolCall.resultDict
        
        return AFLSanityCheckResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            originalValid: result["original_valid"] as? Bool,
            totalIssuesFound: result["total_issues_found"] as? Int,
            autoFixed: result["auto_fixed"] as? Bool,
            fixesApplied: result["fixes_applied"] as? [String] ?? [],
            fixedCode: result["fixed_code"] as? String,
            fixedValid: result["fixed_valid"] as? Bool
        )
    }
}

struct AFLSanityCheckCardView: View {
    let result: AFLSanityCheckResult
    
    @State private var copied = false
    
    private var wasFixed: Bool {
        result.autoFixed == true && result.originalValid == false && result.fixedValid == true
    }
    
    private var headerColor: Color {
        if wasFixed { return .chartGreen }
        if result.success { return .chartGreen }
        return .chartRed
    }
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "AFL Sanity Check Failed", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(headerColor)
                    
                    Text(wasFixed ? "AFL Sanity Check — Auto-Fixed ✓" : result.originalValid == true ? "AFL Sanity Check — Clean ✓" : "AFL Sanity Check — Issues Found")
                        .font(.quicksandSemiBold(13))
                        .foregroundColor(headerColor)
                    
                    Spacer()
                    
                    if result.fixedCode != nil {
                        Button {
                            if let code = result.fixedCode {
                                ClipboardManager.copy()
                                copied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copied = false
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 12))
                                Text(copied ? "Copied!" : "Copy")
                                    .font(.quicksandSemiBold(11))
                            }
                            .foregroundColor(copied ? .chartGreen : .white.opacity(0.5))
                        }
                    }
                }
                .padding(16)
                
                // Issues count
                if let count = result.totalIssuesFound, count > 0 {
                    Text("Found **\(count)** issue\(count != 1 ? "s" : "")\(wasFixed ? " — all auto-fixed!" : "")")
                        .font(.quicksandRegular(13))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
                
                // Fixes applied
                if !result.fixesApplied.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(result.fixesApplied, id: \.self) { fix in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(.chartGreen)
                                
                                Text(fix)
                                    .font(.quicksandRegular(12))
                                    .foregroundColor(.chartGreen)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                
                // Fixed code
                if let code = result.fixedCode {
                    ScrollView {
                        Text(code)
                            .font(.firaCode(12))
                            .foregroundColor(Color(hex: "E6EDF3"))
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                    }
                    .frame(maxHeight: 250)
                    .background(Color(hex: "0d1117"))
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(headerColor.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Code Execution View

struct CodeExecutionResult {
    let success: Bool
    let error: String?
    let output: String?
    let traceback: String?
    let variables: [String: String]?
    let code: String?
    let description: String?
    let toolTimeMs: Int?
    
    static func from(toolCall: ToolCall) -> CodeExecutionResult {
        let result = toolCall.resultDict
        
        var vars: [String: String]?
        if let variablesDict = result["variables"] as? [String: Any] {
            vars = variablesDict.mapValues { String(describing: $0) }
        }
        
        return CodeExecutionResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            output: result["output"] as? String,
            traceback: result["traceback"] as? String,
            variables: vars,
            code: result["code"] as? String,
            description: result["description"] as? String,
            toolTimeMs: result["_tool_time_ms"] as? Int
        )
    }
}

struct CodeExecutionView: View {
    let result: CodeExecutionResult
    
    @State private var showVars = false
    @State private var showCode = false
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "terminal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(result.success ? .chartGreen : .chartRed)
                
                Text(result.success ? "Code Executed Successfully" : "Execution Error")
                    .font(.quicksandSemiBold(13))
                    .foregroundColor(result.success ? .chartGreen : .chartRed)
                
                Image(systemName: result.success ? "checkmark.circle" : "xmark.circle")
                    .font(.system(size: 12))
                    .foregroundColor(result.success ? .chartGreen : .chartRed)
                
                Spacer()
                
                if let time = result.toolTimeMs {
                    Text("\(time)ms")
                        .font(.quicksandRegular(11))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Button {
                    let text = result.output ?? result.error ?? ""
                    ClipboardManager.copy()
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(copied ? .chartGreen : .white.opacity(0.5))
                }
            }
            .padding(16)
            .background(
                result.success
                    ? LinearGradient(colors: [Color.chartGreen.opacity(0.15), Color.chartGreen.opacity(0.05)], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [Color.chartRed.opacity(0.15), Color.chartRed.opacity(0.05)], startPoint: .leading, endPoint: .trailing)
            )
            
            // Output
            VStack(alignment: .leading, spacing: 0) {
                if let description = result.description {
                    Text(description)
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.5))
                        .italic()
                        .padding(.bottom, 8)
                }
                
                Text(result.success ? (result.output ?? "No output") : (result.error ?? "Unknown error"))
                    .font(.firaCode(13))
                    .foregroundColor(result.success ? Color(hex: "E6EDF3") : Color(hex: "F97583"))
                    .lineSpacing(3)
                
                if let traceback = result.traceback {
                    Text(traceback)
                        .font(.firaCode(11))
                        .foregroundColor(Color(hex: "F97583").opacity(0.7))
                        .lineSpacing(2)
                        .padding(.top, 12)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "0d1117"))
            
            // Variables
            if let vars = result.variables, !vars.isEmpty {
                DisclosureGroup(isExpanded: $showVars) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(vars.keys.sorted()), id: \.self) { key in
                            HStack(spacing: 8) {
                                Text(key)
                                    .foregroundColor(Color(hex: "79C0FF"))
                                Text("=")
                                    .foregroundColor(.white.opacity(0.3))
                                Text(vars[key] ?? "")
                                    .foregroundColor(Color(hex: "A5D6FF"))
                            }
                            .font(.firaCode(12))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showVars ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12))
                        Text("Variables (\(vars.count))")
                    }
                    .font(.quicksandSemiBold(12))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.white.opacity(0.03))
            }
            
            // Source code
            if let code = result.code {
                DisclosureGroup(isExpanded: $showCode) {
                    Text(code)
                        .font(.firaCode(12))
                        .foregroundColor(Color(hex: "E6EDF3"))
                        .lineSpacing(2)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showCode ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12))
                        Text("Source Code")
                    }
                    .font(.quicksandSemiBold(12))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.white.opacity(0.03))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(result.success ? Color.chartGreen.opacity(0.3) : Color.chartRed.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Code Sandbox View

struct CodeSandboxResult {
    let code: String
    let language: String
    let title: String?
    let description: String?
    let output: String?
    let editable: Bool?
    let files: [CodeFile]?
    
    static func from(toolCall: ToolCall) -> CodeSandboxResult {
        let args = toolCall.argumentsDict
        let result = toolCall.resultDict
        
        var codeFiles: [CodeFile]?
        if let filesArray = result["files"] as? [[String: Any]] {
            codeFiles = filesArray.compactMap { CodeFile.from(dict: $0) }
        }
        
        return CodeSandboxResult(
            code: result["code"] as? String ?? args["code"] as? String ?? "",
            language: result["language"] as? String ?? args["language"] as? String ?? "python",
            title: result["title"] as? String,
            description: result["description"] as? String,
            output: result["output"] as? String,
            editable: result["editable"] as? Bool,
            files: codeFiles
        )
    }
}

struct CodeFile {
    let name: String
    let code: String
    let language: String?
    
    static func from(dict: [String: Any]) -> CodeFile? {
        guard let name = dict["name"] as? String,
              let code = dict["code"] as? String else { return nil }
        
        return CodeFile(name: name, code: code, language: dict["language"] as? String)
    }
}

struct CodeSandboxView: View {
    let result: CodeSandboxResult
    
    @State private var code: String
    @State private var output: String
    @State private var isRunning = false
    @State private var copied = false
    @State private var showOutput = false
    @State private var activeFile = 0
    
    init(result: CodeSandboxResult) {
        self.result = result
        _code = State(initialValue: result.code)
        _output = State(initialValue: result.output ?? "")
    }
    
    private var languageStyle: (bg: Color, text: Color) {
        switch result.language.lowercased() {
        case "python": return (Color(hex: "3572A5").opacity(0.2), Color(hex: "3572A5"))
        case "javascript": return (Color(hex: "F1E05A").opacity(0.2), Color(hex: "F1E05A"))
        case "typescript": return (Color(hex: "3178C6").opacity(0.2), Color(hex: "3178C6"))
        case "afl": return (Color.potomacYellow.opacity(0.2), .potomacYellow)
        default: return (Color.gray.opacity(0.2), .gray)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.chartGreen)
                
                Text(result.title ?? "Code Sandbox")
                    .font(.quicksandSemiBold(13))
                    .foregroundColor(.white)
                
                Text(result.language.uppercased())
                    .font(.quicksandSemiBold(10))
                    .foregroundColor(languageStyle.text)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(languageStyle.bg)
                    .clipShape(Capsule())
                
                Spacer()
                
                Button {
                    // Simulate run
                    isRunning = true
                    showOutput = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        output = "[\(result.language)] Code executed successfully.\n\nNote: Server-side execution not connected."
                        isRunning = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                        Text(isRunning ? "Running..." : "Run")
                    }
                    .font(.quicksandSemiBold(11))
                    .foregroundColor(isRunning ? .chartGreen : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isRunning ? Color.chartGreen.opacity(0.2) : Color.chartGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .disabled(isRunning)
                
                Button {
                    ClipboardManager.copy()
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(copied ? .chartGreen : .white.opacity(0.5))
                        .padding(6)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(12)
            .background(Color(hex: "161b22"))
            
            if let description = result.description {
                Text(description)
                    .font(.quicksandRegular(12))
                    .foregroundColor(.white.opacity(0.5))
                    .italic()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.02))
            }
            
            // Code
            ScrollView {
                Text(code)
                    .font(.firaCode(13))
                    .foregroundColor(Color(hex: "E6EDF3"))
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .frame(maxHeight: 300)
            .background(Color(hex: "0d1117"))
            
            // Output
            if showOutput {
                Divider().overlay(Color.white.opacity(0.06))
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Image(systemName: "terminal")
                            .font(.system(size: 12))
                        Text("Output")
                            .font(.quicksandSemiBold(12))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.02))
                    
                    Text(output)
                        .font(.firaCode(12))
                        .foregroundColor(output.hasPrefix("Error") ? Color(hex: "F97583") : Color(hex: "7EE787"))
                        .lineSpacing(3)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "010409"))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
    }
}
