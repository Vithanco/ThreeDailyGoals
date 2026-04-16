import Foundation
import Testing

@testable import tdgCoreWidget

@Suite
struct ShortIdHelperTests {

    // MARK: - validatePrefix

    @Test
    func validatePrefix_validInput_returnsUppercased() {
        #expect(ShortIdHelper.validatePrefix("tdg") == "TDG")
        #expect(ShortIdHelper.validatePrefix("Biz") == "BIZ")
        #expect(ShortIdHelper.validatePrefix("PVT") == "PVT")
    }

    @Test
    func validatePrefix_twoChars_isValid() {
        #expect(ShortIdHelper.validatePrefix("AB") == "AB")
    }

    @Test
    func validatePrefix_fiveChars_isValid() {
        #expect(ShortIdHelper.validatePrefix("ABCDE") == "ABCDE")
    }

    @Test
    func validatePrefix_tooShort_returnsDefault() {
        #expect(ShortIdHelper.validatePrefix("A") == "TDG")
    }

    @Test
    func validatePrefix_tooLong_returnsDefault() {
        #expect(ShortIdHelper.validatePrefix("ABCDEF") == "TDG")
    }

    @Test
    func validatePrefix_nonAlpha_filtered() {
        #expect(ShortIdHelper.validatePrefix("T3G") == "TG")
    }

    @Test
    func validatePrefix_allDigits_returnsDefault() {
        #expect(ShortIdHelper.validatePrefix("123") == "TDG")
    }

    @Test
    func validatePrefix_empty_returnsDefault() {
        #expect(ShortIdHelper.validatePrefix("") == "TDG")
    }

    @Test
    func validatePrefix_withWhitespace_trimmed() {
        #expect(ShortIdHelper.validatePrefix("  TDG  ") == "TDG")
    }

    // MARK: - shortId

    @Test
    func shortId_producesCorrectFormat() {
        let uuid = UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!
        #expect(ShortIdHelper.shortId(from: uuid, prefix: "TDG") == "TDG-A1B2C3D4")
    }

    @Test
    func shortId_withDifferentPrefix() {
        let uuid = UUID(uuidString: "DEADBEEF-1234-5678-9ABC-DEF012345678")!
        #expect(ShortIdHelper.shortId(from: uuid, prefix: "BIZ") == "BIZ-DEADBEEF")
    }

    @Test
    func shortId_alwaysUppercaseHex() {
        let uuid = UUID(uuidString: "abcdef01-2345-6789-ABCD-EF0123456789")!
        let result = ShortIdHelper.shortId(from: uuid, prefix: "TDG")
        #expect(result == "TDG-ABCDEF01")
    }

    // MARK: - parseTaskId

    @Test
    func parseTaskId_fullUUID_returnsFullUUID() {
        let uuidString = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
        let result = ShortIdHelper.parseTaskId(uuidString)
        #expect(result == .fullUUID(UUID(uuidString: uuidString)!))
    }

    @Test
    func parseTaskId_prefixedShortId_returnsShortHex() {
        let result = ShortIdHelper.parseTaskId("TDG-A1B2C3D4")
        #expect(result == .shortHex("A1B2C3D4"))
    }

    @Test
    func parseTaskId_bareHex_returnsShortHex() {
        let result = ShortIdHelper.parseTaskId("A1B2C3D4")
        #expect(result == .shortHex("A1B2C3D4"))
    }

    @Test
    func parseTaskId_caseInsensitive() {
        let result = ShortIdHelper.parseTaskId("tdg-a1b2c3d4")
        #expect(result == .shortHex("A1B2C3D4"))
    }

    @Test
    func parseTaskId_differentPrefix() {
        let result = ShortIdHelper.parseTaskId("BIZ-DEADBEEF")
        #expect(result == .shortHex("DEADBEEF"))
    }

    @Test
    func parseTaskId_bareLowercaseHex() {
        let result = ShortIdHelper.parseTaskId("deadbeef")
        #expect(result == .shortHex("DEADBEEF"))
    }

    @Test
    func parseTaskId_invalid_tooShortHex_returnsNil() {
        #expect(ShortIdHelper.parseTaskId("TDG-SHORT") == nil)
    }

    @Test
    func parseTaskId_invalid_notHex_returnsNil() {
        #expect(ShortIdHelper.parseTaskId("TDG-GHIJKLMN") == nil)
    }

    @Test
    func parseTaskId_invalid_noPattern_returnsNil() {
        #expect(ShortIdHelper.parseTaskId("just some text") == nil)
    }

    @Test
    func parseTaskId_invalid_sevenCharHex_returnsNil() {
        #expect(ShortIdHelper.parseTaskId("A1B2C3D") == nil)
    }

    @Test
    func parseTaskId_invalid_nineCharHex_returnsNil() {
        #expect(ShortIdHelper.parseTaskId("A1B2C3D4E") == nil)
    }
}
