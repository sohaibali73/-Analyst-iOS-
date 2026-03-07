import Foundation

enum APIEndpoints {
    // MARK: - Base URL

    static let baseURL = "https://analystbypotomac.vercel.app"

    // MARK: - Core
    static let health = "/health"
    static let root = "/"

    // MARK: - Auth Endpoints

    enum Auth {
        static let register = "/auth/register"
        static let login = "/auth/login"
        static let logout = "/auth/logout"
        static let me = "/auth/me"
        static let refresh = "/auth/refresh-token"
        static let changePassword = "/auth/change-password"
        static let forgotPassword = "/auth/forgot-password"
        static let resetPassword = "/auth/reset-password"
        static let apiKeys = "/auth/api-keys"

        // Admin
        static let adminUsers = "/auth/admin/users"
        static func adminMakeAdmin(_ userId: String) -> String { "/auth/admin/users/\(userId)/make-admin" }
        static func adminRevokeAdmin(_ userId: String) -> String { "/auth/admin/users/\(userId)/revoke-admin" }
        static func adminDeactivate(_ userId: String) -> String { "/auth/admin/users/\(userId)/deactivate" }
        static func adminActivate(_ userId: String) -> String { "/auth/admin/users/\(userId)/activate" }
    }

    // MARK: - Chat Endpoints

    enum Chat {
        static let conversations = "/chat/conversations"
        static func conversation(_ id: String) -> String { "/chat/conversations/\(id)" }
        static func messages(_ conversationId: String) -> String { "/chat/conversations/\(conversationId)/messages" }
        static let sendMessage = "/chat/message"
        static let stream = "/chat/stream"
        static func upload(_ conversationId: String) -> String { "/chat/conversations/\(conversationId)/upload" }
        static let tts = "/chat/tts"
        static let ttsVoices = "/chat/tts/voices"
        static let tools = "/chat/tools"
        static let templateUpload = "/chat/template/upload"
        static let templates = "/chat/templates"
        static func presentation(_ id: String) -> String { "/chat/presentation/\(id)" }
    }

    // MARK: - AFL Endpoints

    enum AFL {
        static let generate = "/afl/generate"
        static let optimize = "/afl/optimize"
        static let debug = "/afl/debug"
        static let explain = "/afl/explain"
        static let validate = "/afl/validate"
        static let codes = "/afl/codes"
        static func code(_ id: String) -> String { "/afl/codes/\(id)" }
        static let history = "/afl/history"
        static func historyItem(_ id: String) -> String { "/afl/history/\(id)" }
        static let upload = "/afl/upload"
        static let files = "/afl/files"
        static func file(_ id: String) -> String { "/afl/files/\(id)" }
        static let presets = "/afl/settings/presets"
        static func preset(_ id: String) -> String { "/afl/settings/presets/\(id)" }
        static func presetSetDefault(_ id: String) -> String { "/afl/settings/presets/\(id)/set-default" }
    }

    // MARK: - Reverse Engineering Endpoints

    enum ReverseEngineer {
        static let start = "/reverse-engineer/start"
        static let continueConversation = "/reverse-engineer/continue"
        static func research(_ strategyId: String) -> String { "/reverse-engineer/research/\(strategyId)" }
        static func schematic(_ strategyId: String) -> String { "/reverse-engineer/schematic/\(strategyId)" }
        static func generateCode(_ strategyId: String) -> String { "/reverse-engineer/generate-code/\(strategyId)" }
        static func strategy(_ strategyId: String) -> String { "/reverse-engineer/strategy/\(strategyId)" }
        static let history = "/reverse-engineer/history"
        static func historyItem(_ id: String) -> String { "/reverse-engineer/history/\(id)" }
    }

    // MARK: - AI / Vercel Integration Endpoints

    enum AI {
        static let chat = "/api/ai/chat"
        static let completion = "/api/ai/completion"
        static let generateUI = "/api/ai/generate-ui"
        static let tools = "/api/ai/tools"
    }

    // MARK: - Brain / Knowledge Base Endpoints

    enum Brain {
        static let upload = "/brain/upload"
        static let uploadBatch = "/brain/upload-batch"
        static let uploadText = "/brain/upload-text"
        static let search = "/brain/search"
        static let documents = "/brain/documents"
        static func document(_ id: String) -> String { "/brain/documents/\(id)" }
        static let embed = "/brain/embed"
        static let stats = "/brain/stats"
    }

    // MARK: - Backtest Endpoints

    enum Backtest {
        static let analyze = "/backtest/analyze"
        static let upload = "/backtest/upload"
        static func backtest(_ id: String) -> String { "/backtest/\(id)" }
        static func strategy(_ id: String) -> String { "/backtest/strategy/\(id)" }
    }

    // MARK: - Researcher Endpoints

    enum Researcher {
        static let analyze = "/researcher/analyze"
        static let history = "/researcher/history"
        static func company(_ symbol: String) -> String { "/api/researcher/company/\(symbol)" }
        static func news(_ symbol: String) -> String { "/api/researcher/news/\(symbol)" }
        static let strategyAnalysis = "/api/researcher/strategy-analysis"
        static let macroContext = "/api/researcher/macro-context"
        static let search = "/api/researcher/search"
        static let trending = "/api/researcher/trending"
    }

    // MARK: - Content Endpoints

    enum Content {
        static let articles = "/content/articles"
        static func article(_ id: String) -> String { "/content/articles/\(id)" }
    }

    // MARK: - Training / Feedback

    enum Train {
        static let feedback = "/train/feedback"
    }

    // MARK: - Presentation / PPTX Endpoints

    enum Presentation {
        static let generate = "/pptx/generate"
        static let assemble = "/pptx/assemble"
        static let uploadImage = "/pptx/upload-image"
        static func download(_ filename: String) -> String { "/pptx/download/\(filename)" }
        static let templates = "/pptx/templates"
        static func chatPresentation(_ id: String) -> String { "/chat/presentation/\(id)" }
    }

    // MARK: - Skills Endpoints

    enum Skills {
        static let list = "/api/skills"
        static let categories = "/api/skills/categories"
        static func skill(_ slug: String) -> String { "/api/skills/\(slug)" }
        static func execute(_ slug: String) -> String { "/api/skills/\(slug)/execute" }
        static func stream(_ slug: String) -> String { "/api/skills/\(slug)/stream" }
        static func job(_ slug: String) -> String { "/api/skills/\(slug)/job" }
        static let jobs = "/api/skills/jobs"
        static func jobStatus(_ jobId: String) -> String { "/api/skills/jobs/\(jobId)" }
        static let multi = "/api/skills/multi"
    }

    // MARK: - File Download Endpoints

    enum Files {
        static func download(_ fileId: String) -> String { "/files/\(fileId)/download" }
        static func info(_ fileId: String) -> String { "/files/\(fileId)/info" }
        static let generated = "/files/generated"
    }

    // MARK: - Stock Data (yfinance)

    enum StockData {
        static func ticker(_ symbol: String) -> String { "/yfinance/ticker/\(symbol)" }
        static func historical(_ symbol: String) -> String { "/yfinance/historical/\(symbol)" }
        static func options(_ symbol: String) -> String { "/yfinance/options/\(symbol)" }
    }

    // MARK: - Upload Endpoints

    enum Upload {
        static let file = "/upload/file"
        static let files = "/upload/files"
        static func deleteFile(_ id: String) -> String { "/upload/files/\(id)" }
    }

    // MARK: - Admin Endpoints

    enum Admin {
        static let systemHealth = "/admin/health/system"
        static let database = "/admin/health/database"
        static let users = "/admin/users"
        static func makeAdmin(_ userId: String) -> String { "/admin/users/\(userId)/make-admin" }
        static func revokeAdmin(_ userId: String) -> String { "/admin/users/\(userId)/revoke-admin" }
        static func deactivate(_ userId: String) -> String { "/admin/users/\(userId)/deactivate" }
        static func activate(_ userId: String) -> String { "/admin/users/\(userId)/activate" }
    }
}
