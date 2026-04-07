import SwiftUI

struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .tint(.tapTenPlayfulOrange)
        .task {
            await QuestionFeedbackSubmissionService.shared.flushPendingReportsIfPossible()
            _ = await QuestionCalibrationSubmissionService.shared.submitPendingEventsIfPossible()
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else {
                return
            }

            Task {
                await QuestionFeedbackSubmissionService.shared.flushPendingReportsIfPossible()
                _ = await QuestionCalibrationSubmissionService.shared.submitPendingEventsIfPossible()
            }
        }
    }
}

#Preview {
    AppRootView()
}
