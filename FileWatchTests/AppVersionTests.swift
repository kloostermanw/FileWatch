//
//  AppVersionTests.swift
//  FileWatchTests
//
//  Created by Wiebe Kloosterman on 21/07/2026.
//

import Testing
@testable import FileWatch

@Suite struct AppVersionTests {
    @Test func stripsLeadingVAndComparesNumerically() {
        #expect(AppVersion("v1.2.0") == AppVersion("1.2.0"))
        #expect(AppVersion("V2.0.0") == AppVersion("2.0.0"))
    }

    @Test func missingTrailingComponentEqualsZero() {
        #expect(AppVersion("1.2") == AppVersion("1.2.0"))
        #expect(AppVersion("1") == AppVersion("1.0.0"))
    }

    @Test func ordersComponentByComponent() {
        #expect(AppVersion("1.2.0") < AppVersion("1.10.0"))
        #expect(AppVersion("1.2.3") < AppVersion("1.3.0"))
        #expect(AppVersion("2.0.0") > AppVersion("1.9.9"))
    }

    @Test func isNewerReflectsStrictOrdering() {
        #expect(AppVersion("1.2.4").isNewer(than: AppVersion("1.2.0")))
        #expect(!AppVersion("1.2.0").isNewer(than: AppVersion("1.2.0")))
        #expect(!AppVersion("1.1.0").isNewer(than: AppVersion("1.2.0")))
    }

    @Test func nonNumericComponentsParseAsZero() {
        #expect(AppVersion("1.x.3") == AppVersion("1.0.3"))
    }
}
