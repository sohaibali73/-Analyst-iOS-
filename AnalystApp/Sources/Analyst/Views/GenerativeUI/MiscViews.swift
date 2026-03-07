import SwiftUI

// MARK: - Live Sports Scores View

struct LiveSportsScoresResult {
    let games: [SportsGame]
    let sport: String?
    let league: String?
    let date: String?
    let error: String?
    let success: Bool
    
    static func from(toolCall: ToolCall) -> LiveSportsScoresResult {
        let args = toolCall.argumentsDict
        let result = toolCall.resultDict
        
        var gameList: [SportsGame] = []
        if let gamesArray = result["games"] as? [[String: Any]] {
            gameList = gamesArray.compactMap { SportsGame.from(dict: $0) }
        }
        
        return LiveSportsScoresResult(
            games: gameList,
            sport: result["sport"] as? String ?? args["sport"] as? String,
            league: result["league"] as? String ?? args["league"] as? String,
            date: result["date"] as? String,
            error: result["error"] as? String,
            success: result["success"] as? Bool ?? true
        )
    }
}

struct SportsGame {
    let sport: String?
    let league: String?
    let status: String?
    let homeTeam: String?
    let awayTeam: String?
    let homeAbbreviation: String?
    let awayAbbreviation: String?
    let homeScore: Int?
    let awayScore: Int?
    let period: String?
    let clock: String?
    let venue: String?
    let broadcast: String?
    let startTime: String?
    
    static func from(dict: [String: Any]) -> SportsGame? {
        return SportsGame(
            sport: dict["sport"] as? String,
            league: dict["league"] as? String,
            status: dict["status"] as? String,
            homeTeam: dict["home_team"] as? String,
            awayTeam: dict["away_team"] as? String,
            homeAbbreviation: dict["home_abbreviation"] as? String,
            awayAbbreviation: dict["away_abbreviation"] as? String,
            homeScore: dict["home_score"] as? Int,
            awayScore: dict["away_score"] as? Int,
            period: dict["period"] as? String,
            clock: dict["clock"] as? String,
            venue: dict["venue"] as? String,
            broadcast: dict["broadcast"] as? String,
            startTime: dict["start_time"] as? String
        )
    }
    
    var isLive: Bool {
        ["live", "in_progress", "in progress"].contains(status?.lowercased() ?? "")
    }
    
    var isFinal: Bool {
        ["final", "finished"].contains(status?.lowercased() ?? "")
    }
    
    var homeWin: Bool {
        isFinal && (homeScore ?? 0) > (awayScore ?? 0)
    }
    
    var awayWin: Bool {
        isFinal && (awayScore ?? 0) > (homeScore ?? 0)
    }
}

struct LiveSportsScoresView: View {
    let result: LiveSportsScoresResult
    
    @State private var expanded = true
    
    private var accentColor: Color {
        switch (result.league ?? result.sport ?? "").lowercased() {
        case "nba": return Color(hex: "F97316")
        case "nfl": return Color.chartGreen
        case "mlb": return Color.chartRed
        case "nhl": return Color.chartBlue
        case "soccer", "mls", "premier_league": return Color.chartPurple
        default: return Color.potomacYellow
        }
    }
    
    private var liveCount: Int {
        result.games.filter { $0.isLive }.count
    }
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Sports Error", error: error)
        } else if result.games.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "trophy")
                    .font(.system(size: 28))
                    .foregroundColor(accentColor.opacity(0.5))
                Text("No games found for \(result.league ?? result.sport ?? "Sports")")
                    .font(.quicksandRegular(13))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expanded.toggle()
                    }
                } label: {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(accentColor.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "trophy")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text((result.league ?? result.sport ?? "Sports").uppercased())
                                .font(.quicksandBold(15))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 4) {
                                Text("\(result.games.count) game\(result.games.count != 1 ? "s" : "")")
                                
                                if liveCount > 0 {
                                    Text("•")
                                    HStack(spacing: 3) {
                                        Circle()
                                            .fill(Color.chartGreen)
                                            .frame(width: 6, height: 6)
                                        Text("\(liveCount) live")
                                    }
                                    .foregroundColor(.chartGreen)
                                    .fontWeight(.semibold)
                                }
                                
                                if let date = result.date {
                                    Text("• \(date)")
                                }
                            }
                            .font(.quicksandRegular(11))
                            .foregroundColor(.white.opacity(0.4))
                        }
                        
                        Spacer()
                        
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(16)
                }
                .buttonStyle(.plain)
                
                if expanded {
                    VStack(spacing: 8) {
                        ForEach(Array(result.games.enumerated()), id: \.offset) { _, game in
                            GameCardView(game: game, accent: accentColor)
                        }
                    }
                    .padding(12)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e"), Color(hex: "0f0f23")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
        }
    }
}

struct GameCardView: View {
    let game: SportsGame
    let accent: Color
    
    private var statusColor: Color {
        switch game.status?.lowercased() {
        case "live", "in_progress", "in progress": return .chartGreen
        case "final", "finished": return Color(hex: "9CA3AF")
        case "halftime", "half": return .chartOrange
        case "scheduled", "upcoming": return .chartBlue
        default: return Color(hex: "9CA3AF")
        }
    }
    
    private var statusLabel: String {
        switch game.status?.lowercased() {
        case "live", "in_progress", "in progress": return "LIVE"
        case "final", "finished": return "FINAL"
        case "halftime", "half": return "HALF"
        case "scheduled", "upcoming": return "UPCOMING"
        default: return game.status?.uppercased() ?? "SCHEDULED"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status row
            HStack {
                HStack(spacing: 6) {
                    if game.isLive {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(statusLabel)
                        .font(.quicksandSemiBold(10))
                        .foregroundColor(statusColor)
                    
                    if let period = game.period {
                        Text(period)
                            .font(.quicksandRegular(10))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                Spacer()
                
                if let clock = game.clock {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(clock)
                            .font(.quicksandSemiBold(11))
                            .fontDesign(.monospaced)
                    }
                    .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.bottom, 12)
            
            // Teams
            VStack(spacing: 8) {
                TeamRowView(
                    name: game.awayTeam,
                    abbreviation: game.awayAbbreviation,
                    score: game.awayScore,
                    isWinner: game.awayWin
                )
                
                Divider().overlay(Color.white.opacity(0.06))
                
                TeamRowView(
                    name: game.homeTeam,
                    abbreviation: game.homeAbbreviation,
                    score: game.homeScore,
                    isWinner: game.homeWin
                )
            }
            
            // Footer
            if game.venue != nil || game.broadcast != nil {
                GameFooterView(venue: game.venue, broadcast: game.broadcast)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(game.isLive ? accent.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

struct GameFooterView: View {
    let venue: String?
    let broadcast: String?
    
    var body: some View {
        HStack {
            if let v = venue {
                Text(v)
            }
            if venue != nil && broadcast != nil {
                Text("•")
            }
            if let b = broadcast {
                Text(b)
            }
        }
        .font(.quicksandRegular(10))
        .foregroundColor(.white.opacity(0.3))
        .padding(.top, 10)
    }
}

struct TeamRowView: View {
    let name: String?
    let abbreviation: String?
    let score: Int?
    let isWinner: Bool
    
    var body: some View {
        HStack {
            TeamInitialsView(name: name ?? "TBD", abbreviation: abbreviation)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(name ?? "TBD")
                    .font(.quicksandSemiBold(14))
                    .foregroundColor(isWinner ? .white : .white.opacity(0.8))
                
                if let abbr = abbreviation {
                    Text(abbr)
                        .font(.quicksandRegular(10))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            
            Spacer()
            
            Text(score.map { "\($0)" } ?? "-")
                .font(.system(size: 22, weight: .heavy, design: .monospaced))
                .foregroundColor(isWinner ? .white : .white.opacity(0.6))
                .frame(minWidth: 36, alignment: .trailing)
        }
    }
}

struct TeamInitialsView: View {
    let name: String
    let abbreviation: String?
    
    private var initials: String {
        if let abbr = abbreviation {
            return abbr.uppercased()
        }
        return name.split(separator: " ").map { String($0.first ?? " ") }.joined().uppercased()
    }
    
    var body: some View {
        Text(initials)
            .font(.quicksandBold(12))
            .foregroundColor(.white.opacity(0.7))
            .frame(width: 36, height: 36)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

// MARK: - Presentation Card View

struct PresentationCardResult {
    let success: Bool
    let error: String?
    let presentationId: String?
    let filename: String?
    let title: String?
    let subtitle: String?
    let theme: String?
    let templateUsed: String?
    let templateId: String?
    let author: String?
    let slideCount: Int?
    let fileSizeKb: Int?
    let slides: [SlidePreview]
    let downloadUrl: String?
    let fetchTimeMs: Int?
    
    static func from(toolCall: ToolCall) -> PresentationCardResult {
        let result = toolCall.resultDict
        
        var slidePreviews: [SlidePreview] = []
        if let slidesArray = result["slides"] as? [[String: Any]] {
            slidePreviews = slidesArray.compactMap { SlidePreview.from(dict: $0) }
        }
        
        return PresentationCardResult(
            success: result["success"] as? Bool ?? true,
            error: result["error"] as? String,
            presentationId: result["presentation_id"] as? String,
            filename: result["filename"] as? String,
            title: result["title"] as? String,
            subtitle: result["subtitle"] as? String,
            theme: result["theme"] as? String,
            templateUsed: result["template_used"] as? String,
            templateId: result["template_id"] as? String,
            author: result["author"] as? String,
            slideCount: result["slide_count"] as? Int ?? slidePreviews.count,
            fileSizeKb: result["file_size_kb"] as? Int,
            slides: slidePreviews,
            downloadUrl: result["download_url"] as? String,
            fetchTimeMs: result["fetch_time_ms"] as? Int ?? result["_tool_time_ms"] as? Int
        )
    }
}

struct SlidePreview {
    let number: Int
    let title: String
    let bulletCount: Int
    let layout: String
    let hasNotes: Bool
    let previewText: String?
    
    static func from(dict: [String: Any]) -> SlidePreview? {
        return SlidePreview(
            number: dict["number"] as? Int ?? 0,
            title: dict["title"] as? String ?? "",
            bulletCount: dict["bullet_count"] as? Int ?? 0,
            layout: dict["layout"] as? String ?? "default",
            hasNotes: dict["has_notes"] as? Bool ?? false,
            previewText: dict["preview_text"] as? String
        )
    }
}

struct PresentationCardView: View {
    let result: PresentationCardResult
    
    @State private var expanded = false
    @State private var downloading = false
    
    private var themeAccent: Color {
        switch result.theme?.lowercased() {
        case "potomac": return .potomacYellow
        case "dark": return Color(hex: "82AAFF")
        case "light": return .chartBlue
        case "corporate": return Color(hex: "0066CC")
        default: return .potomacYellow
        }
    }
    
    var body: some View {
        if !result.success, let error = result.error {
            ErrorCardView(title: "Presentation Error", error: error)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeAccent.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "play.rectangle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeAccent)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.title ?? "Presentation")
                            .font(.quicksandSemiBold(15))
                            .foregroundColor(.white)
                        
                        if let subtitle = result.subtitle {
                            Text(subtitle)
                                .font(.quicksandRegular(12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(result.slideCount ?? result.slides.count) slides")
                            .font(.quicksandSemiBold(11))
                            .foregroundColor(.white.opacity(0.5))
                        
                        if let size = result.fileSizeKb {
                            Text("\(size) KB")
                                .font(.quicksandRegular(10))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
                .padding(20)
                
                // Slide thumbnails
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        // Title slide
                        ThumbnailSlideView(title: result.title ?? "Title", isTitle: true, accent: themeAccent)
                        
                        ForEach(result.slides.prefix(6), id: \.number) { slide in
                            ThumbnailSlideView(title: slide.title, preview: slide.previewText, accent: themeAccent)
                        }
                        
                        if result.slides.count > 6 {
                            Text("+\(result.slides.count - 6)")
                                .font(.quicksandSemiBold(10))
                                .foregroundColor(.white.opacity(0.4))
                                .frame(width: 40, height: 50)
                                .background(Color.white.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 14)
                
                // Tags
                HStack(spacing: 8) {
                    if let template = result.templateUsed {
                        HStack(spacing: 4) {
                            Image(systemName: "paintbrush")
                            Text("BRAND: \(template)")
                        }
                        .font(.quicksandSemiBold(10))
                        .foregroundColor(.chartGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.chartGreen.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else if let theme = result.theme {
                        HStack(spacing: 4) {
                            Image(systemName: "paintpalette")
                            Text("\(theme.uppercased()) THEME")
                        }
                        .font(.quicksandSemiBold(10))
                        .foregroundColor(themeAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeAccent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    if let author = result.author {
                        Text("by \(author)")
                            .font(.quicksandRegular(10))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    if let time = result.fetchTimeMs {
                        Text("\(time)ms")
                            .font(.quicksandRegular(10))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                
                // Expandable slides
                if !result.slides.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            Text(expanded ? "Hide" : "Show")
                            Text("slide details")
                        }
                        .font(.quicksandSemiBold(11))
                        .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, expanded ? 10 : 14)
                    
                    if expanded {
                        VStack(spacing: 6) {
                            ForEach(result.slides, id: \.number) { slide in
                                SlideRowView(slide: slide, accent: themeAccent)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                    }
                }
                
                // Download button
                Button {
                    // Download action (would need actual implementation)
                    downloading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        downloading = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 16))
                        Text(downloading ? "Downloading..." : "Download \(result.filename ?? "Presentation")")
                            .font(.quicksandSemiBold(14))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [themeAccent, themeAccent.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(downloading)
                .opacity(downloading ? 0.7 : 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
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
            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
        }
    }
}

struct ThumbnailSlideView: View {
    let title: String
    var preview: String?
    var isTitle: Bool = false
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isTitle {
                Rectangle()
                    .fill(accent)
                    .frame(width: 40, height: 1)
                
                Text(title)
                    .font(.quicksandSemiBold(6))
                    .foregroundColor(accent)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            } else {
                Text(title)
                    .font(.quicksandSemiBold(6))
                    .foregroundColor(accent)
                    .lineLimit(1)
                
                if let preview = preview {
                    Text(preview)
                        .font(.quicksandRegular(5))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(3)
                }
            }
        }
        .padding(4)
        .frame(width: 80, height: 50)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isTitle ? accent.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

struct SlideRowView: View {
    let slide: SlidePreview
    let accent: Color
    
    private var layoutIcon: String {
        switch slide.layout {
        case "two_column": return "rectangle.split.2x1"
        case "blank": return "rectangle"
        default: return "rectangle.3.group"
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(slide.number)")
                .font(.quicksandSemiBold(10))
                .foregroundColor(accent)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(slide.title)
                    .font(.quicksandSemiBold(12))
                    .foregroundColor(.white)
                
                if let preview = slide.previewText {
                    Text("• \(preview)")
                        .font(.quicksandRegular(10))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: layoutIcon)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))
                
                if slide.bulletCount > 0 {
                    Text("\(slide.bulletCount) pts")
                        .font(.quicksandRegular(9))
                        .foregroundColor(.white.opacity(0.3))
                }
                
                if slide.hasNotes {
                    Image(systemName: "note.text")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .padding(8)
        .padding(.horizontal, 4)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}