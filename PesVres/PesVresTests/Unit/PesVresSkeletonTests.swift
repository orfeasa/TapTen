import Testing
@testable import PesVres

struct PesVresSkeletonTests {
    @Test
    func defaultGameSettingsAreValid() {
        let settings = GameSettings()

        #expect(settings.numberOfRounds == 5)
        #expect(settings.roundDurationSeconds == 60)
    }
}
