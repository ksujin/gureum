//
//  HangulComposer.swift
//  OSX
//
//  Created by Jeong YunWon on 2018. 8. 13..
//  Copyright © 2018년 youknowone.org. All rights reserved.
//

import Foundation

/*!
 @brief  libhangul을 사용하는 합성기

 libhangul의 input context를 사용하는 합성기이다. -init 로는 두벌식 합성기가 설정된다.

 @coclass HGInputContext
 */
@objcMembers public class HangulComposer: NSObject {
    let _inputContext: HGInputContext
    var _commitString: String
    
    init?(keyboardIdentifier: String) {
        self._commitString = String()
        guard let inputContext = HGInputContext(keyboardIdentifier: keyboardIdentifier) else {
            return nil
        }
        self._inputContext = inputContext
        super.init()
    }

    /*!
     @brief  현재 context의 배열을 바꾼다.
     @param  identifier  libhangul의 @ref hangul_ic_select_keyboard 를 참고한다.
     */
    public func setKeyboardWithIdentifier(_ identifier :String) {
        self._inputContext.setKeyboardWithIdentifier(identifier)
    }

    var inputContext: HGInputContext{
        get{
            return self._inputContext;
        }
    }

    var commitString: String {
        get{
            return self._commitString;
        }
    }

    // CIMComposerDelegate

    public func inputController(_ controller: CIMInputController!, inputText string: String!, key keyCode: Int, modifiers flags: NSEvent.ModifierFlags, client sender: Any!) -> CIMInputTextProcessResult {
        // libhangul은 backspace를 키로 받지 않고 별도로 처리한다.
        if (keyCode == kVK_Delete) {
            return self._inputContext.backspace() ? CIMInputTextProcessResult.processed : CIMInputTextProcessResult.notProcessed
        }

        if (keyCode > 50 || keyCode == kVK_Delete || keyCode == kVK_Return || keyCode == kVK_Tab || keyCode == kVK_Space) {
            //dlog(DEBUG_HANGULCOMPOSER, @" ** ESCAPE from outbound keyCode: %lu", keyCode);
            return CIMInputTextProcessResult.notProcessedAndNeedsCommit;
        }

        var string = string!
        // 한글 입력에서 캡스락 무시
        if flags.contains(.capsLock) {
            if !flags.contains(.shift) {
                string = string.lowercased();
            }
        }
        let handled = self._inputContext.process(string.first!.unicodeScalars.first!.value)
        let UCSString = self._inputContext.commitUCSString;
        // dassert(UCSString);
        let recentCommitString = HangulComposerCombination.commitStringByCombinationMode(withUCSString: UCSString)
        self._commitString += recentCommitString
        // dlog(DEBUG_HANGULCOMPOSER, @"HangulComposer -inputText: string %@ (%@ added)", self->_commitString, recentCommitString);
        return handled ? .processed : .notProcessedAndNeedsCancel;
    }

    public func inputController(_ controller: CIMInputController!, commandString string: String!, key keyCode: Int, modifiers flags: NSEvent.ModifierFlags, client sender: Any!) -> CIMInputTextProcessResult {
        assert(false)
        return .notProcessed;
    }

    public func composedString() -> String! {
        let preedit = self._inputContext.preeditUCSString
        return HangulComposerCombination.composedStringByCombinationMode(withUCSString: preedit)
    }

    public func originalString() -> String! {
        let preedit = self._inputContext.preeditUCSString
        return HangulComposerCombination.commitStringByCombinationMode(withUCSString: preedit)
    }

    public func dequeueCommitString() -> String! {
        let queuedCommitString = self._commitString
        self._commitString = ""
        return queuedCommitString
    }

    public func cancelComposition() {
        let flushedString: String! = HangulComposerCombination.commitStringByCombinationMode(withUCSString: self._inputContext.flushUCSString())
        self._commitString += flushedString
    }

    public func clearContext() {
        self._inputContext.reset()
        self._commitString = ""
    }

    public func hasCandidates() -> Bool {
        return false
    }

    public func inputController(_ controller: CIMInputController!, command string: String!, key keyCode: Int, modifier flags: NSEvent.ModifierFlags, client sender: Any!) -> CIMInputTextProcessResult {
        return CIMInputTextProcessResult.notProcessed
    }

    #if DEBUG
    public func candidateSelected(_ candidateString: NSAttributedString!) {
        assert(false)
    }

    public func candidateSelectionChanged(_ candidateString: NSAttributedString!) {
        assert(false)
    }
    #endif
}
