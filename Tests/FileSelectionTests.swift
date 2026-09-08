import Testing

struct FileSelectionTests {
    @Test func shiftClickDeselectsOnlyTheClickedItem() {
        var selection = FileSelection()
        let ids = ["a", "b", "c", "d"]
        selection.click("a", in: ids)
        selection.click("d", in: ids, extending: true)
        #expect(selection.ids == Set(ids))
        selection.click("b", in: ids, extending: true)
        #expect(selection.ids == ["a", "c", "d"])
        #expect(selection.cursor == "b")
        selection.click("b", in: ids, extending: true)
        #expect(selection.ids == ["b"])
        selection.click("b", in: ids, extending: true)
        #expect(selection.ids.isEmpty)
    }

    @Test func arrowsExtendAndContractFromAnchor() {
        var selection = FileSelection()
        let ids = ["a", "b", "c", "d"]
        selection.move(1, in: ids)
        #expect(selection.ids == ["a"])
        selection.move(1, in: ids, extending: true)
        selection.move(1, in: ids, extending: true)
        #expect(selection.ids == ["a", "b", "c"])
        #expect(selection.cursor == "c")
        selection.move(-1, in: ids, extending: true)
        #expect(selection.ids == ["a", "b"])
        selection.move(-1, in: ids)
        selection.move(-1, in: ids)
        #expect(selection.ids == ["a"])
        selection.move(1, in: [])
        #expect(selection.ids == ["a"])
    }

    @Test func selectsRangesInEitherDirection() {
        var selection = FileSelection()
        let ids = ["a", "b", "c", "d", "e"]
        selection.select("b", in: ids)
        selection.select("e", in: ids, extending: true)
        #expect(selection.ids == ["b", "c", "d", "e"])
        selection.select("a", in: ids, extending: true)
        #expect(selection.ids == ["a", "b"])
        selection.select("b", in: ids, contextMenu: true)
        #expect(selection.ids == ["a", "b"])
        selection.select("a", in: ids, toggling: true)
        #expect(selection.ids == ["b"])
        selection.select("b", in: ids, toggling: true)
        #expect(selection.ids.isEmpty)
    }

    @Test func missingAnchorStartsNewSelection() {
        var selection = FileSelection()
        selection.select("gone", in: ["gone"])
        selection.select("b", in: ["a", "b"], extending: true)
        #expect(selection.ids == ["b"])
    }
}
