import SwiftUI

struct AppRootView: View {
    var body: some View {
        NavigationStack {
            HomeView(viewModel: HomeViewModel())
        }
        .tint(.tapTenPlayfulOrange)
    }
}

#Preview {
    AppRootView()
}
