import Foundation

extension String {
    
    enum ConsoleTextColor {
        case `standard`
        case red
    }
    
    func consoleText(color: ConsoleTextColor) -> String {
        switch color {
        case .red:
            return "\u{001B}[0;31m" + self
        default:
            return self
        }
    }
}
