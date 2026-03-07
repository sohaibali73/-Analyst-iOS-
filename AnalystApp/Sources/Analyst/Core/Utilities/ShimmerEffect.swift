import SwiftUI

// MARK: - Shimmer Effect Modifier

/// A shimmer effect for loading states
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    let bounce: Bool
    
    init(duration: Double = 1.5, bounce: Bool = false) {
        self.duration = duration
        self.bounce = bounce
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    let gradient = LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.3), location: 0.3),
                            .init(color: .white.opacity(0.5), location: 0.5),
                            .init(color: .white.opacity(0.3), location: 0.7),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    
                    let width = geometry.size.width
                    let offset = phase * (width + width)
                    
                    gradient
                        .frame(width: width)
                        .offset(x: offset - width)
                        .mask(content)
                }
            )
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: bounce)
                ) {
                    phase = 1
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Applies a shimmer effect to the view
    func shimmer(duration: Double = 1.5, bounce: Bool = false) -> some View {
        modifier(ShimmerEffect(duration: duration, bounce: bounce))
    }
}

// MARK: - Skeleton View

/// A skeleton placeholder view with shimmer effect
struct SkeletonView: View {
    let cornerRadius: CGFloat
    let height: CGFloat?
    let width: CGFloat?
    
    init(
        cornerRadius: CGFloat = 8,
        height: CGFloat? = nil,
        width: CGFloat? = nil
    ) {
        self.cornerRadius = cornerRadius
        self.height = height
        self.width = width
    }
    
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shimmer()
    }
}

// MARK: - Skeleton Shapes

/// Skeleton for text lines
struct SkeletonText: View {
    let lines: Int
    let lineSpacing: CGFloat
    
    init(lines: Int = 2, lineSpacing: CGFloat = 8) {
        self.lines = lines
        self.lineSpacing = lineSpacing
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            ForEach(0..<lines, id: \.self) { index in
                SkeletonView(
                    cornerRadius: 4,
                    height: 14,
                    width: index == lines - 1 ? 180 : nil
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Skeleton for avatar/circle
struct SkeletonAvatar: View {
    let size: CGFloat
    
    init(size: CGFloat = 40) {
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.08))
            .frame(width: size, height: size)
            .shimmer()
    }
}

/// Skeleton for a card
struct SkeletonCard: View {
    let height: CGFloat
    
    init(height: CGFloat = 120) {
        self.height = height
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                SkeletonAvatar(size: 44)
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonView(cornerRadius: 4, height: 16, width: 120)
                    SkeletonView(cornerRadius: 4, height: 12, width: 80)
                }
                Spacer()
            }
            SkeletonText(lines: 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

/// Skeleton for chat message
struct SkeletonChatMessage: View {
    let isUser: Bool
    
    init(isUser: Bool = false) {
        self.isUser = isUser
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !isUser {
                SkeletonAvatar(size: 28)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                SkeletonText(lines: isUser ? 1 : 3)
            }
            .frame(maxWidth: 280, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(isUser ? 0 : 0.04))
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 16,
                    bottomLeadingRadius: isUser ? 4 : 16,
                    bottomTrailingRadius: isUser ? 16 : 4,
                    topTrailingRadius: 16
                )
            )
            
            if isUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 14)
    }
}

/// Skeleton for stock card
struct SkeletonStockCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonView(cornerRadius: 4, height: 14, width: 100)
                    SkeletonView(cornerRadius: 4, height: 22, width: 60)
                }
                Spacer()
                SkeletonView(cornerRadius: 12, height: 28, width: 80)
            }
            .padding(20)
            
            // Price
            SkeletonView(cornerRadius: 4, height: 40, width: 150)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            
            Divider().overlay(Color.white.opacity(0.08))
            
            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonView(cornerRadius: 4, height: 10, width: 50)
                        SkeletonView(cornerRadius: 4, height: 16, width: 70)
                    }
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

/// Skeleton for document row
struct SkeletonDocumentRow: View {
    var body: some View {
        HStack(spacing: 14) {
            SkeletonView(cornerRadius: 10, height: 44, width: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                SkeletonView(cornerRadius: 4, height: 16, width: 180)
                SkeletonView(cornerRadius: 4, height: 12, width: 120)
            }
            
            Spacer()
            
            SkeletonView(cornerRadius: 8, height: 24, width: 24)
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview("Skeletons") {
    ZStack {
        Color(hex: "0D0D0D").ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 24) {
                // Text skeleton
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Skeleton")
                        .font(.quicksandBold(14))
                        .foregroundColor(.white.opacity(0.5))
                    SkeletonText(lines: 3)
                }
                
                // Card skeleton
                VStack(alignment: .leading, spacing: 8) {
                    Text("Card Skeleton")
                        .font(.quicksandBold(14))
                        .foregroundColor(.white.opacity(0.5))
                    SkeletonCard()
                }
                
                // Chat skeleton
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chat Skeleton")
                        .font(.quicksandBold(14))
                        .foregroundColor(.white.opacity(0.5))
                    SkeletonChatMessage(isUser: false)
                    SkeletonChatMessage(isUser: true)
                }
                
                // Stock card skeleton
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stock Card Skeleton")
                        .font(.quicksandBold(14))
                        .foregroundColor(.white.opacity(0.5))
                    SkeletonStockCard()
                }
                
                // Document row skeleton
                VStack(alignment: .leading, spacing: 8) {
                    Text("Document Row Skeleton")
                        .font(.quicksandBold(14))
                        .foregroundColor(.white.opacity(0.5))
                    SkeletonDocumentRow()
                    SkeletonDocumentRow()
                }
            }
            .padding(20)
        }
    }
    .preferredColorScheme(.dark)
}