import SwiftUI
import UIKit

extension Color {
    static let tapTenWarmBackground = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return .systemGroupedBackground
        }
        return UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
    })

    static let tapTenWarmCard = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return .secondarySystemGroupedBackground
        }
        return UIColor(red: 0.97, green: 0.94, blue: 0.89, alpha: 1.0)
    })

    static let tapTenCelebrationGold = Color(uiColor: UIColor(red: 0.95, green: 0.78, blue: 0.28, alpha: 1.0))
    static let tapTenRevealGreen = Color(uiColor: UIColor(red: 0.29, green: 0.64, blue: 0.44, alpha: 1.0))
}
