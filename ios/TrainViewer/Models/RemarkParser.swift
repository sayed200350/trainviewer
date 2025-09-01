import Foundation

/// Parses transport remarks and warnings into structured format
struct RemarkParser {
    
    /// Parsed remark with structured information
    struct ParsedRemark {
        let type: String
        let displayText: String
        let affectsJourney: Bool
        let severity: Severity
        
        enum Severity {
            case info
            case warning
            case critical
        }
    }
    
    /// Parse an array of DB remarks into structured format
    func parseRemarks(_ remarks: [DBRemark]) -> [ParsedRemark] {
        return remarks.compactMap { parseRemark($0) }
    }
    
    /// Parse a single DB remark
    private func parseRemark(_ remark: DBRemark) -> ParsedRemark? {
        guard let type = remark.type else { return nil }
        
        let displayText = remark.summary ?? remark.text ?? "Unknown issue"
        let affectsJourney = determineIfAffectsJourney(type: type, code: remark.code)
        let severity = determineSeverity(type: type, code: remark.code)
        
        return ParsedRemark(
            type: type,
            displayText: displayText,
            affectsJourney: affectsJourney,
            severity: severity
        )
    }
    
    /// Determine if a remark affects the journey
    private func determineIfAffectsJourney(type: String, code: String?) -> Bool {
        let journeyAffectingTypes = [
            "warning",
            "status",
            "hint"
        ]
        
        let journeyAffectingCodes = [
            "text.realtime.journey.cancelled",
            "text.realtime.journey.delayed",
            "text.realtime.journey.platform.changed"
        ]
        
        return journeyAffectingTypes.contains(type.lowercased()) ||
               journeyAffectingCodes.contains(code ?? "")
    }
    
    /// Determine the severity of a remark
    private func determineSeverity(type: String, code: String?) -> ParsedRemark.Severity {
        if type.lowercased().contains("warning") || code?.contains("cancelled") == true {
            return .critical
        } else if type.lowercased().contains("hint") || code?.contains("delayed") == true {
            return .warning
        } else {
            return .info
        }
    }
}