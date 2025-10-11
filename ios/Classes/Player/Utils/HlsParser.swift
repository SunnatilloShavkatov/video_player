//
//  HlsParser.swift
//  video_player
//
//  Created by AI Assistant
//

import Foundation

struct QualityVariant {
    let displayName: String   // "1080p", "720p", "Auto"
    let height: Int            // 1080, 720, -1 for Auto
    let width: Int             // 1920, 1280, -1 for Auto
    let bandwidth: Int         // bits per second
    let url: String            // variant playlist URL
}

class HlsParser {
    
    static func parseHlsMasterPlaylist(url: String, completion: @escaping ([QualityVariant]) -> Void) {
        guard let masterUrl = URL(string: url) else {
            completion([])
            return
        }
        
        let task = URLSession.shared.dataTask(with: masterUrl) { data, response, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }
            
            guard let playlistString = String(data: data, encoding: .utf8) else {
                completion([])
                return
            }
            
            let variants = parsePlaylistContent(playlistString: playlistString, baseURL: masterUrl)
            completion(variants)
        }
        task.resume()
    }
    
    private static func parsePlaylistContent(playlistString: String, baseURL: URL) -> [QualityVariant] {
        var variants: [QualityVariant] = []
        let lines = playlistString.components(separatedBy: .newlines)
        
        var currentBandwidth: Int?
        var currentResolution: String?
        
        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            // Look for EXT-X-STREAM-INF tag
            if line.hasPrefix("#EXT-X-STREAM-INF:") {
                // Parse attributes
                let attributes = parseAttributes(line: line)
                currentBandwidth = attributes["BANDWIDTH"] ?? nil
                currentResolution = parseResolution(line: line)
                
                // Get the next non-empty line which contains the variant URL
                var variantUrl = ""
                for j in (i + 1)..<lines.count {
                    let nextLine = lines[j].trimmingCharacters(in: .whitespaces)
                    if !nextLine.isEmpty && !nextLine.hasPrefix("#") {
                        variantUrl = nextLine
                        break
                    }
                }
                
                if !variantUrl.isEmpty, let bandwidth = currentBandwidth {
                    // Make URL absolute if it's relative
                    let absoluteUrl = resolveUrl(baseUrl: baseURL, relativeUrl: variantUrl)
                    
                    // Parse resolution to get height and width
                    var height = -1
                    var width = -1
                    if let resolution = currentResolution {
                        let components = resolution.split(separator: "x")
                        if components.count == 2 {
                            width = Int(components[0]) ?? -1
                            height = Int(components[1]) ?? -1
                        }
                    }
                    
                    // Create display name
                    let displayName = getDisplayName(height: height, bandwidth: bandwidth)
                    
                    if height > 0 {
                        let variant = QualityVariant(
                            displayName: displayName,
                            height: height,
                            width: width,
                            bandwidth: bandwidth,
                            url: absoluteUrl
                        )
                        variants.append(variant)
                    }
                }
                
                currentBandwidth = nil
                currentResolution = nil
            }
            i += 1
        }
        
        // Sort by height (highest first) and remove duplicates
        let uniqueVariants = variants.reduce(into: [Int: QualityVariant]()) { result, variant in
            if result[variant.height] == nil || variant.bandwidth > result[variant.height]!.bandwidth {
                result[variant.height] = variant
            }
        }.values.sorted { $0.height > $1.height }
        
        return uniqueVariants
    }
    
    private static func parseAttributes(line: String) -> [String: Int?] {
        var result: [String: Int?] = [:]
        
        // Remove the tag prefix
        let attributesString = line.replacingOccurrences(of: "#EXT-X-STREAM-INF:", with: "")
        
        // Parse BANDWIDTH
        if let bandwidthRange = attributesString.range(of: "BANDWIDTH=") {
            let remainingString = String(attributesString[bandwidthRange.upperBound...])
            let bandwidthString: String
            if let commaIndex = remainingString.firstIndex(of: ",") {
                bandwidthString = String(remainingString[..<commaIndex])
            } else {
                bandwidthString = remainingString.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            result["BANDWIDTH"] = Int(bandwidthString)
        }
        
        return result
    }
    
    private static func parseResolution(line: String) -> String? {
        if let resolutionRange = line.range(of: "RESOLUTION=") {
            let remainingString = String(line[resolutionRange.upperBound...])
            if let commaIndex = remainingString.firstIndex(of: ",") {
                return String(remainingString[..<commaIndex])
            } else {
                return remainingString.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
    
    private static func getDisplayName(height: Int, bandwidth: Int) -> String {
        if height > 0 {
            switch height {
            case 2160: return "2160p (4K)"
            case 1440: return "1440p (2K)"
            case 1080: return "1080p"
            case 720: return "720p"
            case 480, 540: return "480p"
            case 360: return "360p"
            case 240: return "240p"
            case 144: return "144p"
            default: return "\(height)p"
            }
        }
        
        // Fallback to bandwidth-based naming
        if bandwidth >= 7_000_000 {
            return "1080p"
        } else if bandwidth >= 4_000_000 {
            return "720p"
        } else if bandwidth >= 2_000_000 {
            return "480p"
        } else if bandwidth >= 1_000_000 {
            return "360p"
        } else {
            return "240p"
        }
    }
    
    private static func resolveUrl(baseUrl: URL, relativeUrl: String) -> String {
        if relativeUrl.hasPrefix("http://") || relativeUrl.hasPrefix("https://") {
            return relativeUrl
        }
        
        if let resolvedUrl = URL(string: relativeUrl, relativeTo: baseUrl) {
            return resolvedUrl.absoluteString
        }
        
        return relativeUrl
    }
}
