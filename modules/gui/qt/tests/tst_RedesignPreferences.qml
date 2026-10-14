// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtTest
import "../player/qml/redesign"

TestCase {
    id: testCase
    name: "JuxtopposedPreferences"
    width: 900; height: 600
    when: windowShown
    visible: true
    QtObject {
        id: store
        property int revision: 0
        property var values: ({resize: true, fastSeek: false, timeout: 1800})
        function value(name) { return values[name] }
        function describe(name) {
            return {kind: name === "timeout" ? "integer" : "bool", title: name, help: name === "fastSeek" ? "Seek to the exact frame." : "", choices: []}
        }
        function stage(name, value) {
            const next = Object.assign({}, values)
            next[name] = value
            values = next
            revision++
            return true
        }
        function reset(name) { stage(name, name === "timeout" ? 1800 : name === "resize") }
    }
    RedesignPreferencesCatalog { id: catalog }
    Column {
        width: parent.width
        RedesignPreferenceRow {
            id: resizeRow
            width: parent.width; backend: store; optionName: "resize"
            label: "Resize window to fit video"
            presentation: ({choices: [{label: "Never", value: false}, {label: "Always", value: true}]})
        }
        RedesignPreferenceRow {
            id: seekRow
            width: parent.width; backend: store; optionName: "fastSeek"
            label: "Seek precisely"; presentation: ({inverted: true})
        }
        RedesignPreferenceRow {
            id: delayRow
            width: parent.width; backend: store; optionName: "timeout"
            label: "Hide after"
            presentation: ({editor: "slider", from: 0, to: 10, factor: 0.001, step: 0.1, suffix: " s"})
        }
        RedesignSegmented {
            id: segmented
            property var lastValue
            model: [{label: "Dark", value: 2}, {label: "Light", value: 1}, {label: "System", value: 0}]
            currentValue: 2
            onActivated: value => { lastValue = value; currentValue = value }
        }
    }
    function cleanup() {
        findChild(resizeRow, "preferenceChoiceEditor").popup.close()
    }
    function init() {
        store.values = {resize: true, fastSeek: false, timeout: 1800}
        store.revision++
        wait(20)
    }
    function test_guidedChoiceWritesUnderlyingBoolean() {
        const choice = findChild(resizeRow, "preferenceChoiceEditor")
        compare(choice.currentIndex, 1)
        choice.forceActiveFocus()
        keyClick(Qt.Key_Up)
        compare(store.value("resize"), false)
    }
    function test_preciseSeekingInvertsFastSeekOption() {
        const toggle = findChild(seekRow, "preferenceToggleEditor")
        verify(toggle.checked)
        mouseClick(toggle)
        compare(store.value("fastSeek"), true)
        verify(!toggle.checked)
    }
    function test_toggleFollowsStoredValue() {
        const toggle = findChild(seekRow, "preferenceToggleEditor")
        compare(toggle.width, 68)
        compare(toggle.height, 32)
        mouseClick(toggle)
        verify(!toggle.checked)
        // A reset made elsewhere must still reach the toggle after it was clicked.
        store.reset("fastSeek")
        verify(toggle.checked)
        toggle.forceActiveFocus()
        keyClick(Qt.Key_Space)
        compare(store.value("fastSeek"), true)
        verify(!toggle.checked)
    }
    function test_rowsUseTheDesignSpacing() {
        // Design: 10 px of air around each control (toggle rows 42, dropdown rows 46).
        compare(seekRow.height, 42)
        compare(resizeRow.height, 46)
    }
    function test_infoButtonFollowsHelpText() {
        const info = findChild(seekRow, "preferenceInfo")
        verify(info.visible)
        compare(info.width, 18)
        compare(info.Accessible.description, "Seek to the exact frame.")
        verify(!findChild(resizeRow, "preferenceInfo").visible)
        mouseClick(info)
        verify(info.checked)
    }
    function test_dropdownListMarksCurrentChoice() {
        const choice = findChild(resizeRow, "preferenceChoiceEditor")
        compare(choice.displayText, "Always")
        mouseClick(choice)
        tryCompare(choice.popup, "opened", true)
        const list = choice.popup.contentItem
        compare(list.count, 2)
        tryVerify(() => list.itemAtIndex(0) !== null)
        mouseClick(list.itemAtIndex(0))
        tryCompare(choice.popup, "visible", false)
        compare(store.value("resize"), false)
        compare(choice.displayText, "Never")
    }
    function test_segmentedReportsChosenValue() {
        mouseClick(segmented, segmented.width * 5 / 6, segmented.height / 2)
        compare(segmented.lastValue, 0)
        mouseClick(segmented, segmented.width / 2, segmented.height / 2)
        compare(segmented.lastValue, 1)
    }
    function test_secondsSliderWritesMilliseconds() {
        const slider = findChild(delayRow, "preferenceSliderEditor")
        compare(slider.value, 1.8)
        mouseClick(slider, slider.width / 2, slider.height / 2)
        verify(store.value("timeout") >= 4900 && store.value("timeout") <= 5100)
    }
    function test_simpleAndAdvancedHaveDifferentContents() {
        const basicGeneral = catalog.sections.general.reduce((names, section) => names.concat(section.rows.map(row => row[0])), [])
        const advancedGeneral = catalog.advancedSections.general.reduce((names, section) => names.concat(section.rows.map(row => row[0])), [])
        verify(!basicGeneral.includes("stats"))
        verify(advancedGeneral.includes("stats"))
        const playback = catalog.sections.playback.reduce((names, section) => names.concat(section.rows.map(row => row[0])), [])
        verify(playback.includes("redesign-repeat"))
        verify(!playback.includes("repeat"))
        verify(!playback.includes("loop"))
        verify(!playback.includes("input-timeshift-path"))
        verify(catalog.advancedSections.playback[0].rows.some(row => row[0] === "input-timeshift-path"))
    }
}
