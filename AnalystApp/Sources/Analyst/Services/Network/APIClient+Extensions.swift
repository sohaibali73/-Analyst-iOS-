import Foundation

// MARK: - AFL Extended Methods

extension APIClient {

    /// Optimizes existing AFL code.
    func optimizeAFL(code: String) async throws -> AFLGenerationResponse {
        guard !code.isEmpty else { throw APIError.clientError("Code cannot be empty.") }
        let body: [String: Any] = ["code": code]
        let data = try await performRequest(.post, APIEndpoints.AFL.optimize, body: body)
        return try decoder.decode(AFLGenerationResponse.self, from: data)
    }

    /// Debugs AFL code with an optional error message for context.
    func debugAFL(code: String, errorMessage: String? = nil) async throws -> AFLGenerationResponse {
        guard !code.isEmpty else { throw APIError.clientError("Code cannot be empty.") }
        var body: [String: Any] = ["code": code]
        if let err = errorMessage { body["error_message"] = err }
        let data = try await performRequest(.post, APIEndpoints.AFL.debug, body: body)
        return try decoder.decode(AFLGenerationResponse.self, from: data)
    }

    /// Explains AFL code in natural language.
    func explainAFL(code: String) async throws -> AFLExplainResponse {
        guard !code.isEmpty else { throw APIError.clientError("Code cannot be empty.") }
        let body: [String: Any] = ["code": code]
        let data = try await performRequest(.post, APIEndpoints.AFL.explain, body: body)
        return try decoder.decode(AFLExplainResponse.self, from: data)
    }

    /// Validates AFL code for syntax and logical errors.
    func validateAFL(code: String) async throws -> AFLValidationResponse {
        guard !code.isEmpty else { throw APIError.clientError("Code cannot be empty.") }
        let body: [String: Any] = ["code": code]
        let data = try await performRequest(.post, APIEndpoints.AFL.validate, body: body)
        return try decoder.decode(AFLValidationResponse.self, from: data)
    }

    /// Fetches a paginated list of AFL codes.
    func getAFLCodes(limit: Int = 50) async throws -> [AFLHistoryEntry] {
        let data = try await performRequest(.get, APIEndpoints.AFL.codes, queryItems: ["limit": min(limit, 100)])
        return (try? decoder.decode([AFLHistoryEntry].self, from: data)) ?? []
    }

    /// Fetches a single AFL code entry by ID.
    func getAFLCode(id: String) async throws -> AFLHistoryEntry {
        guard !id.isEmpty else { throw APIError.clientError("Invalid AFL code ID.") }
        let data = try await performRequest(.get, APIEndpoints.AFL.code(id))
        return try decoder.decode(AFLHistoryEntry.self, from: data)
    }

    /// Deletes an AFL code entry.
    func deleteAFLCode(id: String) async throws {
        guard !id.isEmpty else { throw APIError.clientError("Invalid AFL code ID.") }
        _ = try await performRequest(.delete, APIEndpoints.AFL.code(id))
    }

    // MARK: - AFL Presets

    /// Fetches all AFL presets.
    func getAFLPresets() async throws -> [AFLPreset] {
        let data = try await performRequest(.get, APIEndpoints.AFL.presets)
        return (try? decoder.decode([AFLPreset].self, from: data)) ?? []
    }

    /// Creates a new AFL preset.
    func createAFLPreset(_ preset: [String: Any]) async throws -> AFLPreset {
        let data = try await performRequest(.post, APIEndpoints.AFL.presets, body: preset)
        return try decoder.decode(AFLPreset.self, from: data)
    }

    /// Updates an existing AFL preset.
    func updateAFLPreset(id: String, _ preset: [String: Any]) async throws -> AFLPreset {
        guard !id.isEmpty else { throw APIError.clientError("Invalid preset ID.") }
        let data = try await performRequest(.put, APIEndpoints.AFL.preset(id), body: preset)
        return try decoder.decode(AFLPreset.self, from: data)
    }

    /// Deletes an AFL preset.
    func deleteAFLPreset(id: String) async throws {
        guard !id.isEmpty else { throw APIError.clientError("Invalid preset ID.") }
        _ = try await performRequest(.delete, APIEndpoints.AFL.preset(id))
    }

    /// Sets a preset as the default AFL preset.
    func setDefaultAFLPreset(id: String) async throws {
        guard !id.isEmpty else { throw APIError.clientError("Invalid preset ID.") }
        _ = try await performRequest(.post, APIEndpoints.AFL.presetSetDefault(id))
    }
}

// MARK: - Reverse Engineering Methods

extension APIClient {

    /// Starts a new reverse engineering session.
    func startReverseEngineering(query: String, message: String? = nil, description: String? = nil) async throws -> ReverseEngineerResponse {
        guard !query.isEmpty else { throw APIError.clientError("Query cannot be empty.") }
        var body: [String: Any] = ["query": query]
        if let m = message { body["message"] = m }
        if let d = description { body["description"] = d }
        let data = try await performRequest(.post, APIEndpoints.ReverseEngineer.start, body: body)
        return try decoder.decode(ReverseEngineerResponse.self, from: data)
    }

    /// Continues an existing reverse engineering conversation.
    func continueReverseEngineering(strategyId: String, message: String) async throws -> ReverseEngineerResponse {
        guard !strategyId.isEmpty else { throw APIError.clientError("Invalid strategy ID.") }
        guard !message.isEmpty else { throw APIError.clientError("Message cannot be empty.") }
        let body: [String: Any] = ["strategy_id": strategyId, "message": message]
        let data = try await performRequest(.post, APIEndpoints.ReverseEngineer.continueConversation, body: body)
        return try decoder.decode(ReverseEngineerResponse.self, from: data)
    }

    /// Triggers research phase for a reverse engineering strategy.
    func reverseEngineerResearch(strategyId: String) async throws -> ReverseEngineerResponse {
        guard !strategyId.isEmpty else { throw APIError.clientError("Invalid strategy ID.") }
        let data = try await performRequest(.post, APIEndpoints.ReverseEngineer.research(strategyId))
        return try decoder.decode(ReverseEngineerResponse.self, from: data)
    }

    /// Generates a schematic for a reverse engineering strategy.
    func reverseEngineerSchematic(strategyId: String) async throws -> ReverseEngineerSchematicResponse {
        guard !strategyId.isEmpty else { throw APIError.clientError("Invalid strategy ID.") }
        let data = try await performRequest(.post, APIEndpoints.ReverseEngineer.schematic(strategyId))
        return try decoder.decode(ReverseEngineerSchematicResponse.self, from: data)
    }

    /// Generates code from a reverse engineering strategy.
    func reverseEngineerGenerateCode(strategyId: String) async throws -> ReverseEngineerCodeResponse {
        guard !strategyId.isEmpty else { throw APIError.clientError("Invalid strategy ID.") }
        let data = try await performRequest(.post, APIEndpoints.ReverseEngineer.generateCode(strategyId))
        return try decoder.decode(ReverseEngineerCodeResponse.self, from: data)
    }

    /// Fetches a specific reverse engineering strategy.
    func getReverseEngineerStrategy(strategyId: String) async throws -> ReverseEngineerResponse {
        guard !strategyId.isEmpty else { throw APIError.clientError("Invalid strategy ID.") }
        let data = try await performRequest(.get, APIEndpoints.ReverseEngineer.strategy(strategyId))
        return try decoder.decode(ReverseEngineerResponse.self, from: data)
    }

    /// Fetches reverse engineering history.
    func getReverseEngineerHistory(limit: Int = 50) async throws -> [ReverseEngineerResponse] {
        let data = try await performRequest(.get, APIEndpoints.ReverseEngineer.history, queryItems: ["limit": min(limit, 100)])
        return (try? decoder.decode([ReverseEngineerResponse].self, from: data)) ?? []
    }

    /// Deletes a reverse engineering history entry.
    func deleteReverseEngineerHistory(id: String) async throws {
        guard !id.isEmpty else { throw APIError.clientError("Invalid history ID.") }
        _ = try await performRequest(.delete, APIEndpoints.ReverseEngineer.historyItem(id))
    }
}

// MARK: - Skills Methods

extension APIClient {

    /// Fetches available skills, optionally filtered by category.
    func getSkills(category: String? = nil) async throws -> SkillsListResponse {
        var query: [String: Any]?
        if let cat = category { query = ["category": cat] }
        let data = try await performRequest(.get, APIEndpoints.Skills.list, queryItems: query)
        return try decoder.decode(SkillsListResponse.self, from: data)
    }

    /// Fetches skill categories.
    func getSkillCategories() async throws -> SkillCategoriesResponse {
        let data = try await performRequest(.get, APIEndpoints.Skills.categories)
        return try decoder.decode(SkillCategoriesResponse.self, from: data)
    }

    /// Fetches details for a specific skill.
    func getSkillDetails(slug: String) async throws -> Skill {
        guard !slug.isEmpty else { throw APIError.clientError("Invalid skill slug.") }
        let data = try await performRequest(.get, APIEndpoints.Skills.skill(slug))
        return try decoder.decode(Skill.self, from: data)
    }

    /// Executes a skill synchronously.
    func executeSkill(slug: String, message: String, extraContext: String? = nil) async throws -> SkillExecutionResponse {
        guard !slug.isEmpty else { throw APIError.clientError("Invalid skill slug.") }
        guard !message.isEmpty else { throw APIError.clientError("Message cannot be empty.") }
        var body: [String: Any] = ["message": message, "stream": false]
        if let ctx = extraContext { body["extra_context"] = ctx }
        let data = try await performRequest(.post, APIEndpoints.Skills.execute(slug), body: body)
        return try decoder.decode(SkillExecutionResponse.self, from: data)
    }

    /// Submits a skill job for background execution.
    func submitSkillJob(slug: String, message: String, extraContext: String? = nil) async throws -> SkillJobResponse {
        guard !slug.isEmpty else { throw APIError.clientError("Invalid skill slug.") }
        guard !message.isEmpty else { throw APIError.clientError("Message cannot be empty.") }
        var body: [String: Any] = ["message": message]
        if let ctx = extraContext { body["extra_context"] = ctx }
        let data = try await performRequest(.post, APIEndpoints.Skills.job(slug), body: body)
        return try decoder.decode(SkillJobResponse.self, from: data)
    }

    /// Checks the status of a skill job.
    func getSkillJobStatus(jobId: String) async throws -> SkillJobStatusResponse {
        guard !jobId.isEmpty else { throw APIError.clientError("Invalid job ID.") }
        let data = try await performRequest(.get, APIEndpoints.Skills.jobStatus(jobId))
        return try decoder.decode(SkillJobStatusResponse.self, from: data)
    }

    /// Fetches all skill jobs.
    func getSkillJobs() async throws -> [SkillJobStatusResponse] {
        let data = try await performRequest(.get, APIEndpoints.Skills.jobs)
        return (try? decoder.decode([SkillJobStatusResponse].self, from: data)) ?? []
    }
}

// MARK: - File Download Methods

extension APIClient {

    /// Downloads a file by ID, returning the data and optional filename.
    func downloadFile(fileId: String) async throws -> (Data, String?) {
        guard !fileId.isEmpty else { throw APIError.clientError("Invalid file ID.") }
        let url = baseURL.appendingPathComponent(APIEndpoints.Files.download(fileId))
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        if let token = accessToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await session.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        let filename = httpResponse.value(forHTTPHeaderField: "Content-Disposition")?
            .components(separatedBy: "filename=").last?.trimmingCharacters(in: .init(charactersIn: "\""))
        return (data, filename)
    }

    /// Fetches file information by ID.
    func getFileInfo(fileId: String) async throws -> FileInfoResponse {
        guard !fileId.isEmpty else { throw APIError.clientError("Invalid file ID.") }
        let data = try await performRequest(.get, APIEndpoints.Files.info(fileId))
        return try decoder.decode(FileInfoResponse.self, from: data)
    }

    /// Fetches all generated files.
    func getGeneratedFiles() async throws -> GeneratedFilesResponse {
        let data = try await performRequest(.get, APIEndpoints.Files.generated)
        return try decoder.decode(GeneratedFilesResponse.self, from: data)
    }
}

// MARK: - Stock Data Methods

extension APIClient {

    /// Fetches ticker data for a stock symbol.
    func getStockTicker(symbol: String) async throws -> [String: AnyCodable] {
        guard !symbol.isEmpty else { throw APIError.clientError("Stock symbol is required.") }
        let data = try await performRequest(.get, APIEndpoints.StockData.ticker(symbol.uppercased()))
        return try decoder.decode([String: AnyCodable].self, from: data)
    }

    /// Fetches historical data for a stock symbol.
    func getStockHistorical(symbol: String) async throws -> [String: AnyCodable] {
        guard !symbol.isEmpty else { throw APIError.clientError("Stock symbol is required.") }
        let data = try await performRequest(.get, APIEndpoints.StockData.historical(symbol.uppercased()))
        return try decoder.decode([String: AnyCodable].self, from: data)
    }

    /// Fetches options data for a stock symbol.
    func getStockOptions(symbol: String) async throws -> [String: AnyCodable] {
        guard !symbol.isEmpty else { throw APIError.clientError("Stock symbol is required.") }
        let data = try await performRequest(.get, APIEndpoints.StockData.options(symbol.uppercased()))
        return try decoder.decode([String: AnyCodable].self, from: data)
    }
}

// MARK: - Backtest Methods

extension APIClient {

    /// Analyzes backtest results with AI.
    func analyzeBacktest(results: String, code: String) async throws -> [String: AnyCodable] {
        guard !results.isEmpty else { throw APIError.clientError("Backtest results are required.") }
        let body: [String: Any] = ["results": results, "code": code]
        let data = try await performRequest(.post, APIEndpoints.Backtest.analyze, body: body)
        return try decoder.decode([String: AnyCodable].self, from: data)
    }
}

// MARK: - Researcher Extended Methods

extension APIClient {

    /// Fetches researcher history.
    func getResearcherHistory() async throws -> [[String: AnyCodable]] {
        let data = try await performRequest(.get, APIEndpoints.Researcher.history)
        return (try? decoder.decode([[String: AnyCodable]].self, from: data)) ?? []
    }

    /// Submits a research analysis request.
    func analyzeResearch(body: [String: Any]) async throws -> [String: AnyCodable] {
        let data = try await performRequest(.post, APIEndpoints.Researcher.analyze, body: body)
        return try decoder.decode([String: AnyCodable].self, from: data)
    }
}

// MARK: - Presentation Methods

extension APIClient {

    /// Generates a presentation from a brief.
    func generatePresentation(brief: String, deckFamily: String? = nil, uploadedImages: [String]? = nil) async throws -> PresentationResponse {
        guard !brief.isEmpty else { throw APIError.clientError("Presentation brief is required.") }
        var body: [String: Any] = ["brief": brief]
        if let family = deckFamily { body["deck_family"] = family }
        if let images = uploadedImages { body["uploaded_images"] = images }
        let data = try await performRequest(.post, APIEndpoints.Presentation.generate, body: body)
        return try decoder.decode(PresentationResponse.self, from: data)
    }

    /// Fetches presentation templates.
    func getPresentationTemplates() async throws -> [[String: AnyCodable]] {
        let data = try await performRequest(.get, APIEndpoints.Presentation.templates)
        return (try? decoder.decode([[String: AnyCodable]].self, from: data)) ?? []
    }
}

// MARK: - Chat Extended Methods

extension APIClient {

    /// Sends a non-streaming chat message.
    func sendMessage(conversationId: String, content: String) async throws -> ChatMessageResponse {
        guard !conversationId.isEmpty else { throw APIError.clientError("Invalid conversation ID.") }
        guard !content.isEmpty else { throw APIError.clientError("Message content cannot be empty.") }
        let body: [String: Any] = ["content": content, "conversation_id": conversationId]
        let data = try await performRequest(.post, APIEndpoints.Chat.sendMessage, body: body)
        return try decoder.decode(ChatMessageResponse.self, from: data)
    }

    /// Uploads a file to a conversation.
    func uploadToConversation(conversationId: String, fileData: Data, filename: String) async throws -> ChatUploadResponse {
        guard !conversationId.isEmpty else { throw APIError.clientError("Invalid conversation ID.") }
        guard !fileData.isEmpty else { throw APIError.clientError("File data is empty.") }
        guard !filename.isEmpty else { throw APIError.clientError("Filename cannot be empty.") }

        let url = baseURL.appendingPathComponent(APIEndpoints.Chat.upload(conversationId))
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        if let token = accessToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let boundary = UUID().uuidString
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body
        let (responseData, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        try validateResponse(http, data: responseData)
        return try decoder.decode(ChatUploadResponse.self, from: responseData)
    }

    /// Converts text to speech audio.
    func textToSpeech(text: String, voice: String = "en-US-AriaNeural") async throws -> Data {
        guard !text.isEmpty else { throw APIError.clientError("Text cannot be empty.") }
        let url = baseURL.appendingPathComponent(APIEndpoints.Chat.tts)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = accessToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["text": text, "voice": voice])
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }
        return data
    }

    /// Fetches available TTS voices.
    func getTTSVoices() async throws -> [[String: AnyCodable]] {
        let data = try await performRequest(.get, APIEndpoints.Chat.ttsVoices)
        return (try? decoder.decode([[String: AnyCodable]].self, from: data)) ?? []
    }

    /// Fetches available chat tools.
    func getChatTools() async throws -> [[String: AnyCodable]] {
        let data = try await performRequest(.get, APIEndpoints.Chat.tools)
        return (try? decoder.decode([[String: AnyCodable]].self, from: data)) ?? []
    }
}

// MARK: - Auth Extended Methods

extension APIClient {

    /// Sends a forgot password email.
    func forgotPassword(email: String) async throws {
        guard !email.isEmpty else { throw APIError.clientError("Email is required.") }
        _ = try await performRequest(.post, APIEndpoints.Auth.forgotPassword, body: ["email": email])
    }

    /// Resets a password using a reset token.
    func resetPassword(token: String, newPassword: String) async throws {
        guard !token.isEmpty else { throw APIError.clientError("Reset token is required.") }
        guard newPassword.count >= 8 else { throw APIError.clientError("Password must be at least 8 characters.") }
        _ = try await performRequest(.post, APIEndpoints.Auth.resetPassword, body: ["token": token, "new_password": newPassword])
    }

    /// Refreshes the authentication token.
    func refreshToken() async throws -> AuthResponse {
        let data = try await performRequest(.post, APIEndpoints.Auth.refresh)
        let response = try decoder.decode(AuthResponse.self, from: data)
        try storeToken(response.accessToken)
        return response
    }

    /// Checks the status of configured API keys.
    func getAPIKeyStatus() async throws -> APIKeyStatusResponse {
        let data = try await performRequest(.get, APIEndpoints.Auth.apiKeys)
        return try decoder.decode(APIKeyStatusResponse.self, from: data)
    }

    /// Updates external API keys (Claude, Tavily).
    func updateAPIKeys(claudeKey: String?, tavilyKey: String?) async throws {
        var body: [String: Any] = [:]
        if let k = claudeKey { body["claude_api_key"] = k }
        if let k = tavilyKey { body["tavily_api_key"] = k }
        guard !body.isEmpty else { throw APIError.clientError("No API keys to update.") }
        _ = try await performRequest(.put, APIEndpoints.Auth.apiKeys, body: body)
    }
}

// MARK: - Content Methods

extension APIClient {

    /// Fetches all articles.
    func getArticles() async throws -> [[String: AnyCodable]] {
        let data = try await performRequest(.get, APIEndpoints.Content.articles)
        return (try? decoder.decode([[String: AnyCodable]].self, from: data)) ?? []
    }

    /// Creates a new article.
    func createArticle(body: [String: Any]) async throws -> [String: AnyCodable] {
        let data = try await performRequest(.post, APIEndpoints.Content.articles, body: body)
        return try decoder.decode([String: AnyCodable].self, from: data)
    }

    /// Deletes an article by ID.
    func deleteArticle(id: String) async throws {
        guard !id.isEmpty else { throw APIError.clientError("Invalid article ID.") }
        _ = try await performRequest(.delete, APIEndpoints.Content.article(id))
    }
}

// MARK: - Feedback / Training Methods

extension APIClient {

    /// Submits feedback for training.
    func submitFeedback(body: [String: Any]) async throws {
        _ = try await performRequest(.post, APIEndpoints.Train.feedback, body: body)
    }

    /// Fetches submitted feedback.
    func getFeedback() async throws -> [[String: AnyCodable]] {
        let data = try await performRequest(.get, APIEndpoints.Train.feedback)
        return (try? decoder.decode([[String: AnyCodable]].self, from: data)) ?? []
    }
}

// MARK: - Health Check

extension APIClient {

    /// Performs a health check on the API server.
    func healthCheck() async throws -> HealthResponse {
        let data = try await performRequest(.get, APIEndpoints.health)
        return try decoder.decode(HealthResponse.self, from: data)
    }
}
