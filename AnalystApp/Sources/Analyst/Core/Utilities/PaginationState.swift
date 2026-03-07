import Foundation

// MARK: - Pagination Configuration

struct PaginationConfiguration {
    let pageSize: Int
    let prefetchThreshold: Int
    
    static let `default` = PaginationConfiguration(pageSize: 20, prefetchThreshold: 5)
    static let conversations = PaginationConfiguration(pageSize: 20, prefetchThreshold: 5)
    static let documents = PaginationConfiguration(pageSize: 20, prefetchThreshold: 5)
}

// MARK: - Pagination State

/// Generic pagination state for list views
@Observable
final class PaginationState<Item: Identifiable & Sendable> {
    // MARK: - Properties
    
    var items: [Item] = []
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var hasMore: Bool = true
    var error: Error?
    
    private(set) var cursor: String?
    private let pageSize: Int
    private var lastCursor: String?
    private let prefetchThreshold: Int
    
    private let fetchFunction: (String?, Int) async throws -> PageResult<Item>
    
    // MARK: - Init
    
    init(
        config: PaginationConfiguration = .default,
        fetchFunction: @escaping (String?, Int) async throws -> PageResult<Item>
    ) {
        self.pageSize = config.pageSize
        self.prefetchThreshold = config.prefetchThreshold
        self.fetchFunction = fetchFunction
    }
    
    // MARK: - Actions
    
    @MainActor
    func loadFirstPage() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        cursor = nil
        
        do {
            let result = try await fetchFunction(nil, pageSize)
            items = result.items
            cursor = result.nextCursor
            hasMore = result.hasMore
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadMore() async {
        guard !isLoading && !isLoadingMore && hasMore && cursor != nil else { return }
        
        isLoadingMore = true
        lastCursor = cursor
        
        do {
            let result = try await fetchFunction(cursor, pageSize)
            
            // Only append if cursor hasn't changed (avoid duplicates from race conditions)
            if lastCursor == cursor {
                items.append(contentsOf: result.items)
                cursor = result.nextCursor
                hasMore = result.hasMore
            }
        } catch {
            self.error = error
        }
        
        isLoadingMore = false
    }
    
    @MainActor
    func refresh() async {
        cursor = nil
        hasMore = true
        await loadFirstPage()
    }
    
    @MainActor
    func reset() {
        items = []
        cursor = nil
        hasMore = true
        error = nil
        isLoading = false
        isLoadingMore = false
    }
    
    // MARK: - Item Management
    
    func append(_ item: Item) {
        items.insert(item, at: 0)
    }
    
    func remove(id: Item.ID) {
        items.removeAll { $0.id == id }
    }
    
    func update(_ item: Item) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }
    
    // MARK: - Prefetch Check
    
    func shouldPrefetch(currentIndex: Int) -> Bool {
        return currentIndex >= items.count - prefetchThreshold && hasMore && !isLoadingMore
    }
}

// MARK: - Page Result

struct PageResult<Item> {
    let items: [Item]
    let nextCursor: String?
    let hasMore: Bool
    
    init(items: [Item], nextCursor: String? = nil, hasMore: Bool = true) {
        self.items = items
        self.nextCursor = nextCursor
        self.hasMore = hasMore
    }
}

// MARK: - Infinite Scroll View

import SwiftUI

struct InfiniteScrollView<Item: Identifiable & Sendable, ItemView: View>: View {
    @State private var state: PaginationState<Item>
    let itemView: (Item) -> ItemView
    
    init(
        state: PaginationState<Item>,
        @ViewBuilder itemView: @escaping (Item) -> ItemView
    ) {
        self._state = State(initialValue: state)
        self.itemView = itemView
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(state.items.enumerated()), id: \.element.id) { index, item in
                    itemView(item)
                        .onAppear {
                            if state.shouldPrefetch(currentIndex: index) {
                                Task { await state.loadMore() }
                            }
                        }
                }
                
                if state.isLoadingMore {
                    LoadingStateView(message: "Loading more...")
                        .padding()
                }
                
                if !state.hasMore && !state.items.isEmpty {
                    Text("— End of list —")
                        .font(.quicksandRegular(12))
                        .foregroundColor(.white.opacity(0.3))
                        .padding()
                }
            }
        }
        .refreshable {
            await state.refresh()
        }
        .task {
            if state.items.isEmpty {
                await state.loadFirstPage()
            }
        }
    }
}