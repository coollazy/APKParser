import Foundation

extension FileManager {
    func moveItem(atPath a: String, toPath b: String, override: Bool = false) throws {
        if override && fileExists(atPath: b) {
            try removeItem(atPath: b)
        }
        try moveItem(atPath: a, toPath: b)
        
    }
    
    func copyItem(atPath a: String, toPath b: String, override: Bool = false) throws {
        if override && fileExists(atPath: b) {
            try removeItem(atPath: b)
        }
        try copyItem(atPath: a, toPath: b)
    }
}
