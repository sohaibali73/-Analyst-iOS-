import SwiftUI

// MARK: - Swipe-to-Delete Modifier

struct SwipeToDeleteModifier: ViewModifier {
    let onDelete: () -> Void
    var deleteLabel: String = "Delete"
    var deleteColor: Color = Color(hex: "DC2626")
    var threshold: CGFloat = -80

    @State private var offset: CGFloat = 0
    @State private var showDelete = false
    @GestureState private var dragOffset: CGFloat = 0

    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            // Delete background
            HStack {
                Spacer()
                Button {
                    HapticManager.shared.mediumImpact()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = -UIScreen.main.bounds.width
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        onDelete()
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text(deleteLabel.uppercased())
                            .font(.custom("Rajdhani-SemiBold", size: 10))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .frame(width: 80)
                    .frame(maxHeight: .infinity)
                    .background(deleteColor)
                }
                .buttonStyle(.plain)
            }
            .opacity(showDelete ? 1 : 0)

            // Main content
            content
                .offset(x: offset + dragOffset)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .updating($dragOffset) { value, state, _ in
                            let translation = value.translation.width
                            // Only allow left swipe
                            if translation < 0 {
                                state = translation
                            } else if offset < 0 {
                                // Allow dragging back
                                state = min(translation, -offset)
                            }
                        }
                        .onChanged { value in
                            let translation = value.translation.width
                            if translation < 0 {
                                showDelete = true
                            }
                        }
                        .onEnded { value in
                            let totalOffset = offset + value.translation.width
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if totalOffset < threshold {
                                    offset = threshold
                                    showDelete = true
                                    HapticManager.shared.lightImpact()
                                } else {
                                    offset = 0
                                    showDelete = false
                                }
                            }
                        }
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
        }
        .clipped()
    }
}

// MARK: - Swipe Action Item

struct SwipeActionItem {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
}

// MARK: - Multi-Action Swipe Modifier

struct SwipeActionsModifier: ViewModifier {
    let leadingActions: [SwipeActionItem]
    let trailingActions: [SwipeActionItem]
    var actionWidth: CGFloat = 72

    @State private var offset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0

    private var trailingThreshold: CGFloat {
        -actionWidth * CGFloat(trailingActions.count)
    }

    private var leadingThreshold: CGFloat {
        actionWidth * CGFloat(leadingActions.count)
    }

    func body(content: Content) -> some View {
        ZStack {
            // Leading actions (swipe right)
            if !leadingActions.isEmpty {
                HStack(spacing: 0) {
                    ForEach(leadingActions.indices, id: \.self) { index in
                        let item = leadingActions[index]
                        Button {
                            HapticManager.shared.mediumImpact()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = 0
                            }
                            item.action()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 16, weight: .medium))
                                Text(item.label.uppercased())
                                    .font(.custom("Rajdhani-SemiBold", size: 9))
                                    .tracking(0.5)
                            }
                            .foregroundColor(.white)
                            .frame(width: actionWidth)
                            .frame(maxHeight: .infinity)
                            .background(item.color)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .opacity(offset > 0 ? 1 : 0)
            }

            // Trailing actions (swipe left)
            if !trailingActions.isEmpty {
                HStack(spacing: 0) {
                    Spacer()
                    ForEach(trailingActions.indices, id: \.self) { index in
                        let item = trailingActions[index]
                        Button {
                            HapticManager.shared.mediumImpact()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = 0
                            }
                            item.action()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 16, weight: .medium))
                                Text(item.label.uppercased())
                                    .font(.custom("Rajdhani-SemiBold", size: 9))
                                    .tracking(0.5)
                            }
                            .foregroundColor(.white)
                            .frame(width: actionWidth)
                            .frame(maxHeight: .infinity)
                            .background(item.color)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .opacity(offset < 0 ? 1 : 0)
            }

            // Main content
            content
                .offset(x: offset + dragOffset)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .updating($dragOffset) { value, state, _ in
                            let translation = value.translation.width
                            let total = offset + translation

                            // Clamp within bounds
                            if !leadingActions.isEmpty && total > 0 {
                                state = translation
                            } else if !trailingActions.isEmpty && total < 0 {
                                state = translation
                            } else if offset != 0 {
                                state = translation
                            }
                        }
                        .onEnded { value in
                            let totalOffset = offset + value.translation.width
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if totalOffset < trailingThreshold / 2 && !trailingActions.isEmpty {
                                    offset = trailingThreshold
                                    HapticManager.shared.lightImpact()
                                } else if totalOffset > leadingThreshold / 2 && !leadingActions.isEmpty {
                                    offset = leadingThreshold
                                    HapticManager.shared.lightImpact()
                                } else {
                                    offset = 0
                                }
                            }
                        }
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
        }
        .clipped()
    }
}

// MARK: - View Extensions

extension View {
    /// Simple swipe-to-delete gesture modifier
    func swipeToDelete(
        label: String = "Delete",
        color: Color = Color(hex: "DC2626"),
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(SwipeToDeleteModifier(
            onDelete: onDelete,
            deleteLabel: label,
            deleteColor: color
        ))
    }

    /// Multi-action swipe modifier with leading and trailing actions
    func swipeActions(
        leading: [SwipeActionItem] = [],
        trailing: [SwipeActionItem] = [],
        actionWidth: CGFloat = 72
    ) -> some View {
        modifier(SwipeActionsModifier(
            leadingActions: leading,
            trailingActions: trailing,
            actionWidth: actionWidth
        ))
    }
}
