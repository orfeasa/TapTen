import SwiftUI

struct HomeView: View {
    let viewModel: HomeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                NavigationLink {
                    NewGameView(viewModel: NewGameViewModel())
                } label: {
                    Label("Start New Game", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                infoCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.large)
        .background(
            LinearGradient(
                colors: [
                    Color.tapTenWarmBackground,
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel())
    }
}

private extension HomeView {
    var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fast mouths. Faster taps.")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            Text("One phone, two teams, one loud room. The host listens, taps, and keeps the clock honest.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var infoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How To Play")
                .font(.headline)

            featureRow(icon: "person.2.fill", text: "Team A guesses while Team B hosts, then you switch.")
            featureRow(icon: "list.number", text: "Each round has one prompt and 10 possible answers.")
            featureRow(icon: "timer", text: "Tap fast, trust your ears, beat the timer.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.tapTenWarmCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func featureRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
