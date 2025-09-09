import Foundation

/// Structured parsing of HAFAS/transport.rest remarks
final class RemarkParser {
    
    /// Classification of remark severity
    enum RemarkSeverity: Int, Comparable {
        case info = 0
        case warning = 1
        case disruption = 2
        case critical = 3
        
        static func < (lhs: RemarkSeverity, rhs: RemarkSeverity) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
        var displayName: String {
            switch self {
            case .info: return "Info"
            case .warning: return "Warning"
            case .disruption: return "Disruption"
            case .critical: return "Critical"
            }
        }
    }
    
    /// Classification of remark categories
    enum RemarkCategory: String, CaseIterable {
        case schedule = "schedule"
        case platform = "platform"
        case cancellation = "cancellation"
        case delay = "delay"
        case replacement = "replacement"
        case construction = "construction"
        case strike = "strike"
        case weather = "weather"
        case technical = "technical"
        case capacity = "capacity"
        case accessibility = "accessibility"
        case general = "general"
        case disruption = "disruption"
        
        var displayName: String {
            switch self {
            case .schedule: return "Schedule Change"
            case .platform: return "Platform Change"
            case .cancellation: return "Cancellation"
            case .delay: return "Delay"
            case .replacement: return "Replacement Service"
            case .construction: return "Construction"
            case .strike: return "Strike/Labor Action"
            case .weather: return "Weather"
            case .technical: return "Technical Issues"
            case .capacity: return "Capacity Issues"
            case .accessibility: return "Accessibility"
            case .general: return "General Info"
            case .disruption: return "Service Disruption"
            }
        }
        
        var severity: RemarkSeverity {
            switch self {
            case .schedule, .general, .accessibility: return .info
            case .platform, .delay, .capacity: return .warning
                    case .construction, .weather, .technical, .disruption: return .disruption
        case .cancellation, .replacement, .strike: return .critical
            }
        }
    }
    
    /// Parsed remark with structured information
    struct ParsedRemark {
        let originalRemark: DBRemark
        let category: RemarkCategory
        let severity: RemarkSeverity
        let displayText: String
        let affectsJourney: Bool
        
        init(originalRemark: DBRemark, category: RemarkCategory, severity: RemarkSeverity? = nil, displayText: String? = nil, affectsJourney: Bool = true) {
            self.originalRemark = originalRemark
            self.category = category
            self.severity = severity ?? category.severity
            self.displayText = displayText ?? originalRemark.text ?? originalRemark.summary ?? "Unknown issue"
            self.affectsJourney = affectsJourney
        }
    }
    
    /// Parse a collection of DB remarks into structured format
    func parseRemarks(_ remarks: [DBRemark]) -> [ParsedRemark] {
        return remarks.compactMap { remark in
            parseRemark(remark)
        }.sorted { $0.severity > $1.severity } // Most severe first
    }
    
    /// Parse a single remark
    private func parseRemark(_ remark: DBRemark) -> ParsedRemark? {
        // First try to categorize by remark type/code if available
        if let category = categorizeByTypeOrCode(remark) {
            return ParsedRemark(originalRemark: remark, category: category)
        }
        
        // Fall back to text-based categorization
        let text = (remark.text ?? "") + " " + (remark.summary ?? "")
        let normalizedText = text.lowercased()
        
        let category = categorizeByText(normalizedText)
        let severity = determineSeverityFromText(normalizedText, defaultCategory: category)
        
        return ParsedRemark(
            originalRemark: remark,
            category: category,
            severity: severity,
            affectsJourney: determineJourneyImpact(normalizedText, category: category)
        )
    }
    
    /// Categorize remark by type or code field
    private func categorizeByTypeOrCode(_ remark: DBRemark) -> RemarkCategory? {
        // HAFAS provides structured type/code information
        let type = remark.type?.lowercased() ?? ""
        let code = remark.code?.lowercased() ?? ""
        
        // Common HAFAS type mappings
        let typeMapping: [String: RemarkCategory] = [
            "cancel": .cancellation,
            "cancellation": .cancellation,
            "delay": .delay,
            "platform": .platform,
            "replacement": .replacement,
            "construction": .construction,
            "strike": .strike,
            "warning": .general,
            "info": .general,
            "disruption": .disruption
        ]
        
        // Check type first
        if let category = typeMapping[type] {
            return category
        }
        
        // Check code patterns
        if code.contains("cancel") { return .cancellation }
        if code.contains("delay") { return .delay }
        if code.contains("platform") { return .platform }
        if code.contains("replacement") || code.contains("bus") { return .replacement }
        if code.contains("construction") || code.contains("work") { return .construction }
        if code.contains("strike") { return .strike }
        
        return nil
    }
    
    /// Categorize remark by text content
    private func categorizeByText(_ text: String) -> RemarkCategory {
        // Cancellation indicators
        if text.contains("cancelled") || text.contains("canceled") || 
           text.contains("ausfall") || text.contains("entfällt") {
            return .cancellation
        }
        
        // Platform change indicators
        if text.contains("platform") || text.contains("gleis") ||
           text.contains("track") || text.contains("bahnsteig") {
            return .platform
        }
        
        // Delay indicators
        if text.contains("delay") || text.contains("verspätet") ||
           text.contains("später") || text.contains("minutes late") {
            return .delay
        }
        
        // Replacement service indicators
        if text.contains("replacement") || text.contains("ersatz") ||
           text.contains("bus") || text.contains("rail replacement") {
            return .replacement
        }
        
        // Construction indicators
        if text.contains("construction") || text.contains("bauarbeit") ||
           text.contains("maintenance") || text.contains("repair") ||
           text.contains("engineering work") {
            return .construction
        }
        
        // Strike indicators
        if text.contains("strike") || text.contains("streik") ||
           text.contains("industrial action") || text.contains("labor") {
            return .strike
        }
        
        // Weather indicators
        if text.contains("weather") || text.contains("wetter") ||
           text.contains("storm") || text.contains("snow") ||
           text.contains("ice") || text.contains("wind") {
            return .weather
        }
        
        // Technical indicators
        if text.contains("technical") || text.contains("technisch") ||
           text.contains("signal") || text.contains("power") ||
           text.contains("equipment") || text.contains("system") {
            return .technical
        }
        
        // Capacity indicators
        if text.contains("overcrowded") || text.contains("capacity") ||
           text.contains("full") || text.contains("überfüllt") {
            return .capacity
        }
        
        // Accessibility indicators
        if text.contains("wheelchair") || text.contains("accessible") ||
           text.contains("elevator") || text.contains("lift") ||
           text.contains("barrier-free") || text.contains("barrierefrei") {
            return .accessibility
        }
        
        return .general
    }
    
    /// Determine severity from text content
    private func determineSeverityFromText(_ text: String, defaultCategory: RemarkCategory) -> RemarkSeverity {
        // Critical severity indicators
        if text.contains("cancelled") || text.contains("canceled") ||
           text.contains("no service") || text.contains("suspended") ||
           text.contains("major delay") || text.contains("significant delay") {
            return .critical
        }
        
        // Disruption severity indicators
        if text.contains("disruption") || text.contains("disrupted") ||
           text.contains("severe delay") || text.contains("long delay") ||
           text.contains("alternative") || text.contains("diversion") {
            return .disruption
        }
        
        // Warning severity indicators
        if text.contains("minor delay") || text.contains("short delay") ||
           text.contains("expect") || text.contains("possible") ||
           text.contains("may be") || text.contains("platform change") {
            return .warning
        }
        
        // Use category default if no specific severity indicators found
        return defaultCategory.severity
    }
    
    /// Determine if remark affects journey planning
    private func determineJourneyImpact(_ text: String, category: RemarkCategory) -> Bool {
        // Non-journey affecting categories
        switch category {
        case .accessibility, .capacity:
            return false
        case .general:
            // Check if it's just informational
            if text.contains("information") || text.contains("please note") ||
               text.contains("reminder") || text.contains("advice") {
                return false
            }
        default:
            break
        }
        
        // Journey affecting indicators
        if text.contains("delay") || text.contains("cancel") ||
           text.contains("replacement") || text.contains("disruption") ||
           text.contains("platform change") || text.contains("reroute") {
            return true
        }
        
        return true // Default to affecting journey for safety
    }
    
    /// Get summary statistics for parsed remarks
    func getRemarkSummary(_ parsedRemarks: [ParsedRemark]) -> RemarkSummary {
        let journeyAffecting = parsedRemarks.filter { $0.affectsJourney }
        let maxSeverity = parsedRemarks.map { $0.severity }.max() ?? .info
        
        let categoryCount = Dictionary(grouping: parsedRemarks) { $0.category }
            .mapValues { $0.count }
        
        return RemarkSummary(
            totalRemarks: parsedRemarks.count,
            journeyAffectingRemarks: journeyAffecting.count,
            maxSeverity: maxSeverity,
            categoryBreakdown: categoryCount,
            hasCriticalIssues: maxSeverity == .critical,
            hasJourneyDisruption: journeyAffecting.contains { $0.severity >= .disruption }
        )
    }
}

/// Summary of remark analysis
struct RemarkSummary {
    let totalRemarks: Int
    let journeyAffectingRemarks: Int
    let maxSeverity: RemarkParser.RemarkSeverity
    let categoryBreakdown: [RemarkParser.RemarkCategory: Int]
    let hasCriticalIssues: Bool
    let hasJourneyDisruption: Bool
    
    /// Check if journey should be filtered out based on remarks
    func shouldFilterJourney() -> Bool {
        return hasCriticalIssues || 
               (hasJourneyDisruption && journeyAffectingRemarks > 2)
    }
    
    /// Get user-friendly summary text
    func getSummaryText() -> String? {
        guard journeyAffectingRemarks > 0 else { return nil }
        
        if hasCriticalIssues {
            return "Service cancelled or severely disrupted"
        } else if hasJourneyDisruption {
            return "Service disrupted - expect delays"
        } else if maxSeverity >= .warning {
            return "Minor delays possible"
        }
        
        return nil
    }
}
