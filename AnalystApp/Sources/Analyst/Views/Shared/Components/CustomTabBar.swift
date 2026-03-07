import SwiftUI

// MARK: - Custom Floating Tab Bar

struct CustomTabBar: View {
    @Environment(TabViewModel.self) private var tabVM
    @State private var hoveredTab: TabViewModel.Tab?
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabViewModel.Tab.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: tabVM.selectedTab == tab,
                    isHovered: hoveredTab == tab
                ) {
                    if tabVM.selectedTab == tab {
                        // If same tab, still trigger haptic
                        HapticManager.shared.selection()
                    } else {
                        tabVM.select(tab)
                    }
                }
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.15)) {
                        hoveredTab = hovering ? tab : nil
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
}

// MARK: - Tab Bar Item

struct TabBarItem: View {
    let tab: TabViewModel.Tab
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void
    
    @State private var badgeCount: Int = 0
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Active indicator background
                    if isSelected {
                        Circle()
                            .fill(Color.potomacYellow.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Icon
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .potomacYellow : .white.opacity(0.5))
                        .scaleEffect(isSelected ? 1.15 : isHovered ? 1.08 : 1.0)
                        .animation(AnimationProvider.bouncy, value: isSelected)
                        .animation(AnimationProvider.quick, value: isHovered)
                    
                    // Badge
                    if badgeCount > 0 {
                        BadgeView(count: badgeCount)
                            .offset(x: 14, y: -12)
                    }
                }
                
                // Label
                Text(tab.rawValue)
                    .font(.quicksandSemiBold(10))
                    .foregroundColor(isSelected ? .potomacYellow : .white.opacity(0.35))
                    .opacity(isSelected ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(AnimationProvider.quick, value: isPressed)
    }
    
    @State private var isPressed = false
    
    var gesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in isPressed = true }
            .onEnded { _ in
                isPressed = false
                action()
            }
    }
}

// MARK: - Badge View

struct BadgeView: View {
    let count: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.chartRed)
                .frame(width: 18, height: 18)
            
            Text(count > 99 ? "99+" : "\(count)")
                .font(.quicksandBold(10))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Tab Bar Container Modifier

struct TabBarContainerModifier: ViewModifier {
    @Environment(TabViewModel.self) private var tabVM
    @Binding var selectedTab: TabViewModel.Tab
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            
            CustomTabBar()
        }
        .ignoresSafeArea(.keyboard)
    }
}

extension View {
    /// Wraps the view with a custom floating tab bar
    func customTabBar(selectedTab: Binding<TabViewModel.Tab>) -> some View {
        modifier(TabBarContainerModifier(selectedTab: selectedTab))
    }
}

// MARK: - Animated Tab Transition

struct TabTransitionModifier: ViewModifier {
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isSelected ? 1 : 0)
            .offset(y: isSelected ? 0 : 8)
            .animation(AnimationProvider.smooth, value: isSelected)
    }
}

extension View {
    /// Applies a fade and slide transition based on selection state
    func tabTransition(isSelected: Bool) -> some View {
        modifier(TabTransitionModifier(isSelected: isSelected))
    }
}

// MARK: - Preview

#Preview("Custom Tab Bar") {
    ZStack {
        Color(hex: "0D0D0D").ignoresSafeArea()
        
        VStack {
            Spacer()
            
            Text("Content Area")
                .font(.rajdhaniBold(24))
                .foregroundColor(.white.opacity(0.3))
            
            Spacer()
        }
        
        CustomTabBar()
            .environment(TabViewModel())
    }
    .preferredColorScheme(.dark)
}