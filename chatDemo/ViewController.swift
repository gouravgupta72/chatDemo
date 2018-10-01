//
//  ViewController.swift
//  chatDemo
//
//  Created by Gourav Gupta on 28/09/18.
//  Copyright © 2018 eKincare. All rights reserved.
//

import UIKit
import Ably

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension AppDelegate: AblyChatHandlerProtocol{
    func chatModel(_ chatModel: AblyChatHandler, connectionStateChanged: ARTConnectionStateChange) {
        
    }
    
    func chatModelLoadingHistory(_ chatModel: AblyChatHandler) {
        
    }
    
    func chatModelDidFinishSendingMessage(_ chatModel: AblyChatHandler) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, didReceiveMessage message: ARTMessage) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, didReceiveMessageFailed message: Dictionary<String, Any>) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, didReceiveError error: ARTErrorInfo) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, historyDidLoadWithMessages: [ARTBaseMessage]) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, membersDidUpdate: [ARTPresenceMessage], presenceMessage: ARTPresenceMessage) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, incomingText message: Dictionary<String, Any>) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, doctorTyping message: Dictionary<String, Any>) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, doctorJoin message: Dictionary<String, Any>) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, chatEnd message: Dictionary<String, Any>) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, doctorAttachment message: Dictionary<String, Any>) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, patientAttachment message: Dictionary<String, Any>) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, prescription message: Dictionary<String, Any>) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, doctorJoinVideo message: Dictionary<String, Any>) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, endVideoCall message: Dictionary<String, Any>) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, startVideoCall message: Dictionary<String, Any>) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, rejectVideoCall message: Dictionary<String, Any>) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, acceptVideoCall message: Dictionary<String, Any>) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, userJoined message: String, channelName: String) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, userLeft message: String, channelName: String) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, isDoctorOnline: Bool) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, presenceUpdateTyping: Bool, lastReadMessage: String, lastDeliveredMessage: String) {
        
    }
    
    func chatModel(_ chatModel: AblyChatHandler, requestRejected message: Dictionary<String, Any>) {
        
    }
}
