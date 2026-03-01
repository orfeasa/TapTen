import Testing
@testable import TapTen

struct TapTenSkeletonTests {
    @Test
    func defaultGameSettingsAreValid() {
        let settings = GameSettings()

        #expect(settings.numberOfRounds == 5)
        #expect(settings.roundDurationSeconds == 60)
    }
}
