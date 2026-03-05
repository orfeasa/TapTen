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
    static let tapTenPlayfulBlue = Color(uiColor: UIColor(red: 0.14, green: 0.56, blue: 0.97, alpha: 1.0))
    static let tapTenPlayfulPink = Color(uiColor: UIColor(red: 0.95, green: 0.39, blue: 0.58, alpha: 1.0))
    static let tapTenPlayfulOrange = Color(uiColor: UIColor(red: 0.99, green: 0.60, blue: 0.24, alpha: 1.0))
    static let tapTenPlayfulViolet = Color(uiColor: UIColor(red: 0.60, green: 0.49, blue: 0.93, alpha: 1.0))
    static let tapTenPlayfulMint = Color(uiColor: UIColor(red: 0.21, green: 0.74, blue: 0.63, alpha: 1.0))
}
