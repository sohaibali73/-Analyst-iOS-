import Foundation

// MARK: - AFL Extended Methods

extension APIClient {

    func optimizeAFL(code: String) async throws -> AFLGenerationResponse {
        let body: [String: Any] = ["code": code]
        let data = try await performRequest(.post, APIEndpoints.AFL.optimize, body: body)
        return try decoder.decode(AFLGenerationResponse.self, from: data)
    }

    func debugAFL(code: String, errorMessage: String? = nil) async throws -> AFLGenerationResponse {
        var body: [String: Any] = ["code": code]
        if let err = errorMessage { body["error_message"] = err }
        let data = try await performRequest(.post, APIEndpoints.AFL.debug, body: body)
        return try decoder.decode(AFLGenerationResponse.self, from: data)
    }

    func explainAFL(code: String) async throws -> AFLExplainResponse {
        let body: [String: Any] = ["code": code]
        let data = try await performRequest(.post, APIEndpoints.AFL.explain, body: body)
        return try decoder.decode(AFLExplainResponse.self, from: data)
    }

    func validateAFL(code: String) async throws -> AFLValidationResponse {
        let body: [String: Any] = ["code": code]
        let data = try await performRequest(.post, APIEndpoints.AFL.validate, body: body)
        return try decoder.decode(AFLValidationResponse.self, from: data)
    }

    func getAFLCodes(limit: Int = 50) async throws -> [AFLHistoryEntry] {
        let data = try await performRequest(.get, APIEndpoints.AFL.codes, queryItems: ["limit": limit])
        return (try? decoder.decode([AFLHistoryEntry].self, from: data)) ?? []
    }

    func getAFLCode(id: String) async throws -> AFLHistoryEntry {
        let data = try await performRequest(.get, APIEndpoints.AFL.code(id))
        return try decoder.decode(AFLHistoryEntry.self, from: data)
    }

    func deleteAFLCode(id: String) async throws {
        _ = try await performRequest(.delete, APIEndpoints.AFL.code(id))
    }

    // MARK: - AFL Presets

    func getAFLPresets() async throws -> [AFLPreset] {
        let data = try await performRequest(.get, APIEndpoints.AFL.presets)
        return (try? decoder.decode([AFLPreset].self, from: data)) ?? []
    }

    func createAFLPreset(_ preset: [String: Any]) async throws -> AFLPreset {
        let data = try await performRequest(.post, APIEndpoints.AFL.presets, body: preset)
        return try decoder.decode(AFLPreset.self, from: data)
    }

    func updateAFLPreset(id: String, _ preset: [String: Any]) async throws -> AFLPreset {
        let data = try await performRequest(.put, APIEndpoints.AFL.preset(id), body: preset)
        return try decoder.decode(AFLPreset.self, from: data)
    }

    func deleteAFLPreset(id: String) async throws {
        _ = try await performRequest(.delete, APIEndpoints.AFL.preset(id))
    }

    func setDefaultAFLPreset(id: String) async throws {
        _ = try await performRequest(.post, APIEndpoints.AFL.presetSetDefault(id))
    }
}

// MARK: - Reverse Engineering Methods

extension APIClient {

    func startReverseEngineering(query: String, message: String? = nil, description: String? = nil) async throws -> ReverseEngineerResponse {
        var body: [String: Any] = ["query": query]
        if let m = message { body["message"] = m }
        if let d = description { body["description"] = d }
        let data = try await performRequest(.post, APIEndpoints.ReverseEngineer.start, body: body)
        return try decoder.decode(ReverseEngineerResponse.self, from: data)
    }

    func continueReverseEngineering(strategyId: String, message: String) async throws -> ReverseEngineerResponse {
        let body: [String: Any] = ["strategy_id": strategyId, "message": message]
        let data = try await performRequest(.post, APIEndpoints.ReverseEngineer.continueConversation, body: body)
        return try decoder.decode(ReverseEngineerResponse.self, from: data)
    }

    func reverseEngineerResearch(strategyId: String) async throws -> ReverseEngineerResponse {
        let data = try await performRequest(.post, APIEndpoints.ReverseEngineer.research(strategyId))
        return try decoder.decode(ReverseEngineerResponse.self, from: data)
    }

    func reverseEngineerSchematic(strategyId: String) async throws -> ReverseEngineerSchematicResponse {
        let data = try await performRequest(.post, APIEndpoints.ReverseEngineer.schematic(strategyId))
        return try decoder.decode(ReverseEngineerSchematicResponse.self, from: data)
    }

    func reverseEngineerGenerateCode(strategyId: String) async throws -> ReverseEngineerCodeResponse {
        let data = try await performRequest(.post, APIEndpoints.ReverseEngineer.generateCode(strategyId))
        return try decoder.decode(ReverseEngineerCodeResponse.self, from: data)
    }

    func getReverseEngineerStrategy(strategyId: String) async throws -> ReverseEngineerResponse {
        let data = try await performRequest(.get, APIEndpoints.ReverseEngineer.strategy(strategyId))
        return try decoder.decode(ReverseEngineerResponse.self, from: data)
    }

    func getReverseEngineerHistory(limit: Int = 50) async throws -> [ReverseEngineerResponse] {
        let data = try await performRequest(.get, APIEndpoints.ReverseEngineer.history, queryItems: ["limit": limit])
        return (try? decoder.decode([ReverseEngineerResponse].self, from: data)) ?? []
    }

    func deleteReverseEngineerHistory(id: String) async throws {
        _ = try await performRequest(.delete, APIEndpoints.ReverseEngineer.historyItem(id))
    }
}

// MARK: - Skills Methods

extension APIClient {

    func getSkills(category: String? = nil) async throws -> SkillsListResponse {
        var query: [String: Any]? = nil
        if let cat = category { query = ["category": cat] }
        let data = try await performRequest(.get, APIEndpoints.Skills.list, queryItems: query)
        return try decoder.decode(SkillsListResponse.self, from: data)
    }

    func getSkillCategories() async throws -> SkillCategoriesResponse {
        let data = try await performRequest(.get, APIEndpoints.Skills.categories)
        return try decoder.decode(SkillCategoriesResponse.self, from: data)
    }

    func getSkillDetails(slug: String) async throws -> Skill {
        let data = try await performRequest(.get, APIEndpoints.Skills.skill(slug))
        return try decoder.decode(Skill.self, from: data)
    }

    func executeSkill(slug: String, message: String, extraContext: String? = nil) async throws -> SkillExecutionResponse {
        var body: [String: Any] = ["message": message, "stream": false]
        if let ctx = extraContext { body["extra_context"] = ctx }
        let data = try await performRequest(.post, APIEndpoints.Skills.execute(slug), body: body)
        return try decoder.decode(SkillExecutionResponse.self, from: data)
    }

    func submitSkillJob(slug: String, message: String, extraContext: String? = nil) async throws -> SkillJobResponse {
        var body: [String: Any] = ["message": message]
        if let ctx = extraContext { body["extra_context"] = ctx }
        let data = try await performRequest(.post, APIEndpoints.Skills.job(slug), body: body)
        return try decoder.decode(SkillJobResponse.self, from: data)
    }

    func getSkillJobStatus(jobId: String) async throws -> SkillJobStatusResponse {
        let data = try await performRequest(.get, APIEndpoints.Skills.jobStatus(jobId))
        return try decoder.decode(SkillJobStatusResponse.self, from: data)
    }

    func getSkillJobs() async throws -> [SkillJobStatusResponse] {
        let data = try await performRequest(.get, APIEndpoints.Skills.jobs)
        return (try? decoder.decode([SkillJobStatusResponse].self, from: data)) ?? []
    }
}

// MARK: - File Download Methods

extension APIClient {

    func downloadFile(fileId: String) async throws -> (Data, String?) {
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

    func getFileInfo(fileId: String) async throws -> FileInfoResponse {
        let data = try await performRequest(.get, APIEndpoints.Files.info(fileId))
        return try decoder.decode(FileInfoResponse.self, from: data)
    }

    func getGeneratedFiles() async throws -> GeneratedFilesResponse {
        let data = try await performRequest(.get, APIEndpoints.Files.generated)
        return try decoder.decode(GeneratedFilesResponse.self, from: data)
    }
}

// MARK: - Stock Data Methods

extension APIClient {

    func getStockTicker(symbol: String) async throws -> [String: AnyCodable] {
        let data = try await performRequest(.get, APIEndpoints.StockData.ticker(symbol))
        return try decoder.decode([String: AnyCodable].self, from: data)
    }

    func getStockHistorical(symbol: String) async throws -> [String: AnyCodable] {
        let data = try await performRequest(.get, APIEndpoints.StockData.historical(symbol))
        return try decoder.decode([String: AnyCodable].self, from: data)
    }

    func getStockOptions(symbol: String) async throws -> [String: AnyCodable] {
        let data = try await performRequest(.get, APIEndpoints.StockData.options(symbol))
        return try decoder.decode([String: AnyCodable].self, from: data)
    }
}

// MARK: - Backtest Methods

extension APIClient {

    func analyzeBacktest(results: String, code: String) async throws -> [String: AnyCodable] {
        let body: [String: Any] = ["results": results, "code": code]
        let data = try await performRequest(.post, APIEndpoints.Backtest.analyze, body: body)
        return try decoder.decode([String: AnyCodable].self, from: data)
    }
}

// MARK: - Researcher Extended Methods

extension APIClient {

    func getResearcherHistory() async throws -> [[String: AnyCodable]] {
        let data = try await performRequest(.get, APIEndpoints.Researcher.history)
        return (try? decoder.decode([[String: AnyCodable]].self, from: data)) ?? []
    }

    func analyzeResearch(body: [String: Any]) async throws -> [String: AnyCodable] {
        let data = try await performRequest(.post, APIEndpoints.Researcher.analyze, body: body)
        return try decoder.decode([String: AnyCodable].self, from: data)
    }
}

// MARK: - Presentation Methods

extension APIClient {

    func generatePresentation(brief: String, deckFamily: String? = nil, uploadedImages: [String]? = nil) async throws -> PresentationResponse {
        var body: [String: Any] = ["brief": brief]
        if let family = deckFamily { body["deck_family"] = family }
        if let images = uploadedImages { body["uploaded_images"] = images }
        let data = try await performRequest(.post, APIEndpoints.Presentation.generate, body: body)
        return try decoder.decode(PresentationResponse.self, from: data)
    }

    func getPresentationTemplates() async throws -> [[String: AnyCodable]] {
        let data = try await performRequest(.get, APIEndpoints.Presentation.templates)
        return (try? decoder.decode([[String: AnyCodable]].self, from: data)) ?? []
    }
}

// MARK: - Chat Extended Methods

extension APIClient {

    func sendMessage(conversationId: String, content: String) async throws -> ChatMessageResponse {
        let body: [String: Any] = ["content": content, "conversation_id": conversationId]
        let data = try await performRequest(.post, APIEndpoints.Chat.sendMessage, body: body)
        return try decoder.decode(ChatMessageResponse.self, from: data)
    }

    func uploadToConversation(conversationId: String, fileData: Data, filename: String) async throws -> ChatUploadResponse {
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

    func textToSpeech(text: String, voice: String = "en-US-AriaNeural") async throws -> Data {
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

    func getTTSVoices() async throws -> [[String: AnyCodable]] {
        let data = try await performRequest(.get, APIEndpoints.Chat.ttsVoices)
        return (try? decoder.decode([[String: AnyCodable]].self, from: data)) ?? []
    }

    func getChatTools() async throws -> [[String: AnyCodable]] {
        let data = try await performRequest(.get, APIEndpoints.Chat.tools)
        return (try? decoder.decode([[String: AnyCodable]].self, from: data)) ?? []
    }
}

// MARK: - Auth Extended Methods

extension APIClient {

    func forgotPassword(email: String) async throws {
        _ = try await performRequest(.post, APIEndpoints.Auth.forgotPassword, body: ["email": email])
    }

    func resetPassword(token: String, newPassword: String) async throws {
        _ = try await performRequest(.post, APIEndpoints.Auth.resetPassword, body: ["token": token, "new_password": newPassword])
    }

    func refreshToken() async throws -> AuthResponse {
        let data = try await performRequest(.post, APIEndpoints.Auth.refresh)
        let response = try decoder.decode(AuthResponse.self, from: data)
        try storeToken(response.accessToken)
        return response
    }

    func getAPIKeyStatus() async throws -> APIKeyStatusResponse {
        let data = try await performRequest(.get, APIEndpoints.Auth.apiKeys)
        return try decoder.decode(APIKeyStatusResponse.self, from: data)
    }

    func updateAPIKeys(claudeKey: String?, tavilyKey: String?) async throws {
        var body: [String: Any] = [:]
        if let k = claudeKey { body["claude_api_key"] = k }
        if let k = tavilyKey { body["tavily_api_key"] = k }
        _ = try await performRequest(.put, APIEndpoints.Auth.apiKeys, body: body)
    }
}

// MARK: - Content Methods

extension APIClient {

    func getArticles() async throws -> [[String: AnyCodable]] {
        let data = try await performRequest(.get, APIEndpoints.Content.articles)
        return (try? decoder.decode([[String: AnyCodable]].self, from: data)) ?? []
    }

    func createArticle(body: [String: Any]) async throws -> [String: AnyCodable] {
        let data = try await performRequest(.post, APIEndpoints.Content.articles, body: body)
        return try decoder.decode([String: AnyCodable].self, from: data)
    }

    func deleteArticle(id: String) async throws {
        _ = try await performRequest(.delete, APIEndpoints.Content.article(id))
    }
}

// MARK: - Feedback / Training Methods

extension APIClient {

    func submitFeedback(body: [String: Any]) async throws {
        _ = try await performRequest(.post, APIEndpoints.Train.feedback, body: body)
    }

    func getFeedback() async throws -> [[String: AnyCodable]] {
        let data = try await performRequest(.get, APIEndpoints.Train.feedback)
        return (try? decoder.decode([[String: AnyCodable]].self, from: data)) ?? []
    }
}

// MARK: - Health Check

extension APIClient {

    func healthCheck() async throws -> HealthResponse {
        let data = try await performRequest(.get, APIEndpoints.health)
        return try decoder.decode(HealthResponse.self, from: data)
    }
}

// MARK: - Internal: Expose request method for extensions

extension APIClient {

    /// Public request method for use in extensions (delegates to private `request`)
    func performRequest(
        _ method: HTTPMethod,
        _ endpoint: String,
        body: [String: Any]? = nil,
        queryItems: [String: Any]? = nil
    ) async throws -> Data {
        var url = baseURL.appendingPathComponent(endpoint)
        if let queryItems = queryItems {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = queryItems.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            url = components.url!
        }
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = accessToken { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body = body { req.httpBody = try? JSONSerialization.data(withJSONObject: body) }
        print("🌐 REQUEST: \(method.rawValue) \(url.absoluteString)")
        let (data, response) = try await session.data(for: req)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        print("🌐 RESPONSE STATUS: \(httpResponse.statusCode)")
        try validateResponse(httpResponse, data: data)
        return data
    }
}
