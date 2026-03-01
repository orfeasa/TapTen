import SwiftUI

struct GameFlowPlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Game Flow", systemImage: "hourglass")
        } description: {
            Text("Round Intro, Pass Device, and Host Round screens will be added in the next milestone.")
        }
        .navigationTitle("Game Flow")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GameFlowPlaceholderView()
    }
}
