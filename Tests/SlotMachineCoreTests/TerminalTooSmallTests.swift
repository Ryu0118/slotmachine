@testable import SlotMachineCore
import Testing

struct TerminalTooSmallTests {
    @Test
    func messageStatesRequiredAndActualSize() {
        let error = TerminalTooSmall(neededColumns: 30, neededRows: 20, haveColumns: 10, haveRows: 5)
        let message = error.description
        #expect(message.contains("30×20"))
        #expect(message.contains("10×5"))
        #expect(message.contains("bigger"))
    }

    @Test
    func messageFallsBackWhenSizeIsUnknown() {
        let error = TerminalTooSmall(neededColumns: 30, neededRows: 20, haveColumns: nil, haveRows: nil)
        let message = error.description
        #expect(message.contains("30×20"))
        #expect(message.contains("smaller than that"))
        #expect(!message.contains("×5")) // no actual size when it couldn't be read
    }
}
