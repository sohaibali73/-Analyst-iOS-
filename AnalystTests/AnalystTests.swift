//
//  AnalystTests.swift
//  AnalystTests
//
//  Core model tests for Analyst app data types and utilities.
//

import XCTest
@testable import Analyst

final class AnalystTests: XCTestCase {

    // MARK: - API Endpoints Tests

    func testAPIEndpoints_baseURL() {
        XCTAssertFalse(APIEndpoints.baseURL.isEmpty)
        XCTAssertTrue(APIEndpoints.baseURL.hasPrefix("https://"))
    }

    func testAPIEndpoints_authPaths() {
        XCTAssertEqual(APIEndpoints.Auth.login, "/auth/login")
        XCTAssertEqual(APIEndpoints.Auth.register, "/auth/register")
        XCTAssertEqual(APIEndpoints.Auth.logout, "/auth/logout")
        XCTAssertEqual(APIEndpoints.Auth.me, "/auth/me")
        XCTAssertEqual(APIEndpoints.Auth.changePassword, "/auth/change-password")
    }

    func testAPIEndpoints_chatPaths() {
        XCTAssertEqual(APIEndpoints.Chat.conversations, "/chat/conversations")
        XCTAssertEqual(APIEndpoints.Chat.stream, "/chat/stream")
        XCTAssertEqual(APIEndpoints.Chat.conversation("abc"), "/chat/conversations/abc")
        XCTAssertEqual(APIEndpoints.Chat.messages("xyz"), "/chat/conversations/xyz/messages")
    }

    func testAPIEndpoints_aflPaths() {
        XCTAssertEqual(APIEndpoints.AFL.generate, "/afl/generate")
        XCTAssertEqual(APIEndpoints.AFL.optimize, "/afl/optimize")
        XCTAssertEqual(APIEndpoints.AFL.history, "/afl/history")
        XCTAssertEqual(APIEndpoints.AFL.historyItem("id1"), "/afl/history/id1")
    }

    func testAPIEndpoints_brainPaths() {
        XCTAssertEqual(APIEndpoints.Brain.upload, "/brain/upload")
        XCTAssertEqual(APIEndpoints.Brain.search, "/brain/search")
        XCTAssertEqual(APIEndpoints.Brain.documents, "/brain/documents")
        XCTAssertEqual(APIEndpoints.Brain.document("doc1"), "/brain/documents/doc1")
    }

    // MARK: - HTTPMethod Tests

    func testHTTPMethod_rawValues() {
        XCTAssertEqual(HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.post.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.put.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.patch.rawValue, "PATCH")
        XCTAssertEqual(HTTPMethod.delete.rawValue, "DELETE")
    }

    // MARK: - AFLGenerationResponse Tests

    func testAFLGenerationResponse_generatedCode_fromCode() {
        let response = AFLGenerationResponse(code: "Buy = Close > Open;", aflCode: nil, explanation: nil, stats: nil)
        XCTAssertEqual(response.generatedCode, "Buy = Close > Open;")
    }

    func testAFLGenerationResponse_generatedCode_fromAflCode() {
        let response = AFLGenerationResponse(code: nil, aflCode: "Sell = Close < Open;", explanation: nil, stats: nil)
        XCTAssertEqual(response.generatedCode, "Sell = Close < Open;")
    }

    func testAFLGenerationResponse_generatedCode_empty() {
        let response = AFLGenerationResponse(code: nil, aflCode: nil, explanation: nil, stats: nil)
        XCTAssertEqual(response.generatedCode, "")
    }

    // MARK: - BacktestRecommendation Tests

    func testBacktestRecommendation_id() {
        let rec = BacktestRecommendation(title: "Reduce position size", description: nil, priority: "high")
        XCTAssertEqual(rec.id, "Reduce position sizehigh")
    }

    // MARK: - PresentationTheme Tests

    func testPresentationTheme_allCases() {
        XCTAssertEqual(PresentationTheme.allCases.count, 4)
        XCTAssertEqual(PresentationTheme.dark.displayName, "Dark")
        XCTAssertEqual(PresentationTheme.light.displayName, "Light")
        XCTAssertEqual(PresentationTheme.corporate.displayName, "Corporate")
        XCTAssertEqual(PresentationTheme.potomac.displayName, "Potomac")
    }

    // MARK: - TabViewModel Tests

    func testTabViewModel_initialState() {
        let vm = TabViewModel()
        XCTAssertEqual(vm.selectedTab, .dashboard)
        XCTAssertNil(vm.previousTab)
    }

    func testTabViewModel_select() {
        let vm = TabViewModel()
        vm.select(.chat)
        XCTAssertEqual(vm.selectedTab, .chat)
        XCTAssertEqual(vm.previousTab, .dashboard)
    }

    func testTabViewModel_goBack() {
        let vm = TabViewModel()
        vm.select(.chat)
        vm.goBack()
        XCTAssertEqual(vm.selectedTab, .dashboard)
        XCTAssertNil(vm.previousTab)
    }

    func testTabViewModel_allTabs() {
        let tabs = TabViewModel.Tab.allCases
        XCTAssertEqual(tabs.count, 5)
        for tab in tabs {
            XCTAssertFalse(tab.icon.isEmpty)
            XCTAssertFalse(tab.selectedIcon.isEmpty)
            XCTAssertFalse(tab.rawValue.isEmpty)
        }
    }

    func testTabViewModel_allFeatures() {
        let features: [TabViewModel.Feature] = [.backtest, .research, .presentations]
        for feature in features {
            XCTAssertFalse(feature.icon.isEmpty)
            XCTAssertFalse(feature.iconColor.isEmpty)
            XCTAssertFalse(feature.rawValue.isEmpty)
        }
    }

    // MARK: - NetworkMonitor Tests

    func testNetworkMonitor_connectionTypes() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.wifi.rawValue, "WiFi")
        XCTAssertEqual(NetworkMonitor.ConnectionType.cellular.rawValue, "Cellular")
        XCTAssertEqual(NetworkMonitor.ConnectionType.wired.rawValue, "Wired")
        XCTAssertEqual(NetworkMonitor.ConnectionType.unknown.rawValue, "Unknown")
    }

    // MARK: - RetryHandler Configuration Tests

    func testRetryConfiguration_defaults() {
        let config = RetryHandler.Configuration.default
        XCTAssertEqual(config.maxRetries, 3)
        XCTAssertEqual(config.initialDelay, 1.0)
        XCTAssertEqual(config.maxDelay, 30.0)
        XCTAssertEqual(config.multiplier, 2.0)
        XCTAssertTrue(config.jitter)
    }

    func testRetryConfiguration_aggressive() {
        let config = RetryHandler.Configuration.aggressive
        XCTAssertEqual(config.maxRetries, 5)
        XCTAssertEqual(config.initialDelay, 0.5)
    }

    func testRetryConfiguration_conservative() {
        let config = RetryHandler.Configuration.conservative
        XCTAssertEqual(config.maxRetries, 2)
        XCTAssertFalse(config.jitter)
    }

    // MARK: - Message Reaction Tests

    func testMessageReactionType_allCases() {
        XCTAssertEqual(MessageReactionType.allCases.count, 4)
        for reaction in MessageReactionType.allCases {
            XCTAssertEqual(reaction.emoji, reaction.rawValue)
        }
    }

    // MARK: - ErrorResponse Tests

    func testErrorResponse_decodable() throws {
        let json = #"{"detail": "Not found"}"#.data(using: .utf8)!
        let response = try JSONDecoder().decode(ErrorResponse.self, from: json)
        XCTAssertEqual(response.detail, "Not found")
    }
}
