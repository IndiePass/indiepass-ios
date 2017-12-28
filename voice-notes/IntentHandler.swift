//
//  IntentHandler.swift
//  voice-notes
//
//  Created by Edward Hinkle on 11/14/17.
//  Copyright © 2017 Studio H, LLC. All rights reserved.
//

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        return self
    }
    
}

extension IntentHandler: INCreateNoteIntentHandling {
    
    public func handle(intent: INCreateNoteIntent, completion: @escaping (INCreateNoteIntentResponse) -> Swift.Void) {
        
        let defaults = UserDefaults(suiteName: "group.software.studioh.indigenous")
        
        if let activeAccount = defaults?.integer(forKey: "defaultAccount"),
            let micropubAccounts = defaults?.array(forKey: "micropubAccounts") as? [Data],
            let micropubDetails = try? JSONDecoder().decode(IndieAuthAccount.self, from: micropubAccounts[activeAccount]) {
        
            print("siri data")
            print((intent.content as? INTextNoteContent)!.text!)

            if let noteContent = intent.content as? INTextNoteContent,
                let noteText = noteContent.text {
                sendMicropub(note: noteText, forUser: micropubDetails) { () in
                    print("micropub should be complete")
                }
            }
            
            // Save the context.
    //        do {
    //            try context.save()
    //
            let noteTitle = intent.title ?? INSpeakableString(spokenPhrase: "")
            
                let response = INCreateNoteIntentResponse(code: INCreateNoteIntentResponseCode.success, userActivity: nil)
            response.createdNote = INNote(title: noteTitle, contents: [intent.content!], groupName: nil, createdDateComponents: nil, modifiedDateComponents: nil, identifier: nil)

                completion(response)
    //        } catch {
    //
    //            completion(INCreateNoteIntentResponse(code: INCreateNoteIntentResponseCode.failure, userActivity: nil))
    //        }
        }
        
    }
    
    public func confirm(intent: INCreateNoteIntent, completion: @escaping (INCreateNoteIntentResponse) -> Swift.Void) {
        completion(INCreateNoteIntentResponse(code: INCreateNoteIntentResponseCode.ready, userActivity: nil))
    }
    
    public func resolveTitle(forCreateNote intent: INCreateNoteIntent, with completion: @escaping (INStringResolutionResult) -> Swift.Void) {
        let result: INStringResolutionResult
        
        if let title = intent.title?.spokenPhrase, title.count > 0 {
            result = INStringResolutionResult.success(with: title)
        } else {
            result = INStringResolutionResult.notRequired()
        }
        
        completion(result)
    }
    
    
    public func resolveContent(for intent: INCreateNoteIntent, with completion: @escaping (INNoteContentResolutionResult) -> Swift.Void) {
        let result: INNoteContentResolutionResult
        
        if let content = intent.content {
            result = INNoteContentResolutionResult.success(with: content)
        } else {
            result = INNoteContentResolutionResult.needsValue()
        }
        
        completion(result)
    }
    
    
    public func resolveGroupName(for intent: INCreateNoteIntent, with completion: @escaping (INSpeakableStringResolutionResult) -> Swift.Void) {
        completion(INSpeakableStringResolutionResult.notRequired())
    }
    
}

