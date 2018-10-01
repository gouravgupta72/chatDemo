import Foundation
import Ably

enum messageRecepentStatus:String {
    case SUBMIT = "submit"
    case SENT = "sent"
    case DELIVERED = "delivered"
    case READ = "read"
    case FAILED = "failed"
    case UPLOAD = "uploading"
}

let userType    =   "customer"
public protocol AblyChatHandlerProtocol {
    func chatModel(_ chatModel: AblyChatHandler, connectionStateChanged: ARTConnectionStateChange)
    func chatModelLoadingHistory(_ chatModel: AblyChatHandler)
    func chatModelDidFinishSendingMessage(_ chatModel: AblyChatHandler)
    func chatModel(_ chatModel: AblyChatHandler, didReceiveMessage message: ARTMessage)
    func chatModel(_ chatModel: AblyChatHandler, didReceiveMessageFailed message: Dictionary<String, Any>)
    func chatModel(_ chatModel: AblyChatHandler, didReceiveError error: ARTErrorInfo)
    func chatModel(_ chatModel: AblyChatHandler, historyDidLoadWithMessages: [ARTBaseMessage])
    func chatModel(_ chatModel: AblyChatHandler, membersDidUpdate: [ARTPresenceMessage], presenceMessage: ARTPresenceMessage)
    func chatModel(_ chatModel:AblyChatHandler, incomingText message:Dictionary<String, Any>)
    func chatModel(_ chatModel:AblyChatHandler, doctorTyping message:Dictionary<String, Any>)
    func chatModel(_ chatModel:AblyChatHandler, doctorJoin message:Dictionary<String, Any>)
    func chatModel(_ chatModel:AblyChatHandler, chatEnd message:Dictionary<String, Any>)
    func chatModel(_ chatModel:AblyChatHandler, doctorAttachment message:Dictionary<String, Any>)
    func chatModel(_ chatModel:AblyChatHandler, patientAttachment message:Dictionary<String, Any>)
    func chatModel(_ chatModel:AblyChatHandler, prescription message:Dictionary<String, Any>)
    func chatModel(_ chatModel:AblyChatHandler, doctorJoinVideo message:Dictionary<String, Any>)
    func chatModel(_ chatModel:AblyChatHandler, endVideoCall message:Dictionary<String, Any>)
    func chatModel(_ chatModel:AblyChatHandler, startVideoCall message:Dictionary<String, Any>)
    func chatModel(_ chatModel:AblyChatHandler, rejectVideoCall message:Dictionary<String, Any>)
    func chatModel(_ chatModel:AblyChatHandler, acceptVideoCall message:Dictionary<String, Any>)
    func chatModel(_ chatModel:AblyChatHandler, userJoined message:String, channelName: String)
    func chatModel(_ chatModel:AblyChatHandler, userLeft message:String, channelName: String)
    func chatModel(_ chatModel:AblyChatHandler, isDoctorOnline: Bool)
    func chatModel(_ chatModel:AblyChatHandler, presenceUpdateTyping:Bool, lastReadMessage:String, lastDeliveredMessage:String)
    func chatModel(_ chatModel:AblyChatHandler, requestRejected message:Dictionary<String, Any>)
}

open class AblyChatHandler {
    fileprivate var ablyClientOptions: ARTClientOptions
    public var ablyRealtime: ARTRealtime?
    fileprivate var channel: ARTRealtimeChannel?
    
    
    var clientId = String()
    open var delegate: AblyChatHandlerProtocol?
    open var hasAppJoined = false
    
    public init(clientId: String) {
        ablyClientOptions = ARTClientOptions()
        ablyClientOptions.clientId  =   "testusers"
        ablyClientOptions.logLevel = .verbose
        ablyClientOptions.autoConnect = false
    }
    
    public func connectAbly(client_id:String){
        self.clientId = client_id
        ablyClientOptions = ARTClientOptions(key: self.clientId)
        ablyClientOptions.clientId  =   "testusers"
        ablyClientOptions.autoConnect = true
        let client = ARTRealtime(options: ablyClientOptions)
        client.connection.connect()
        
        NotificationCenter.default.addObserver(self, selector: #selector(AblyChatHandler.applicationWillResignActiveEventReceived(_:)),
                                               name: NSNotification.Name(rawValue: "applicationWillResignActive"),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AblyChatHandler.applicationWillEnterForegroundEventReceived(_:)),
                                               name: NSNotification.Name(rawValue: "applicationWillEnterForeground"),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AblyChatHandler.applicationWillEnterForegroundEventReceived(_:)),
                                               name: NSNotification.Name(rawValue: "applicationDidBecomeActive"),
                                               object: nil)
    }
    
    func isConnectionOpen() -> Bool {
        if self.ablyRealtime?.connection.state == nil {
           return false
        }
        return true
    }
    
    open func connect() {
        detachHandlers()
//        let key = ARTCrypto.generateRandomKey(256)
//        let options = ARTChannelOptions(cipherKey: key as ARTCipherKeyCompatible)
        self.ablyRealtime = ARTRealtime(options: self.ablyClientOptions)
        self.ablyRealtime?.connection.connect()
        
        let realtime = self.ablyRealtime!
        
        realtime.connection.on { stateChange in
            
            if let stateChange = stateChange
            {
                self.delegate?.chatModel(self, connectionStateChanged: stateChange)
                
                print(stateChange.current)
                
                switch stateChange.current {
                    case .disconnected:
                        self.attemptReconnect(5000)
                        break
                    case .suspended:
                        self.attemptReconnect(15000)
                        break
                    case .connected:
                        self.channel?.unsubscribe()
                        self.channel?.presence.unsubscribe()
                        self.channel = self.ablyRealtime?.channels.get("Gourav_test")
    //                    self.channel = self.ablyRealtime?.channels.get((self.result?.customerId)!, options: options)
//                        APPDELEGATE.registerForNotificationAbly(ably: self.ablyRealtime!)
                        self.joinChannel()
                        break
                    case .initialized:
                        break
                    case .connecting:
                        break
                    case .closing:
                        break
                    case .closed:
                        break
                    case .failed:
                        self.attemptReconnect(15000)
                        break
                }
            }
        }
    }
    
    // Explicitly reconnect to Ably and joins channel
    open func reconnect() {
        self.connect()
    };
    
    // Leaves channel by disconnecting from Ably
    open func disconnect() {
        if self.isConnectionOpen() {
            guard let channel = self.channel else { return }
            self.submitLeavePresence(channel: channel)
            self.ablyRealtime?.connection.close()
        }
    };
    
    var Timestamp: String {
        return "\(Int((NSDate().timeIntervalSince1970 * 1000.0).rounded()))"
    }
    
    open func publishMessage(_ message: String, _ consult_id : String, messageID:String) {
        let messageForServer = ["intentName": "incoming_text",
                                "uniqueId"  : messageID,
                                "consultation_request_id" : consult_id,
                                "payload": [
                                    "text": message
            ],
                                "user": [
                                    "type": "customer"
            ]
            ]as [String: Any]
        
        let convertedMessage = self.convertToString(dictionaryData: messageForServer)
        
        self.channel?.publish(self.clientId, data: convertedMessage) { error in
            guard error == nil else {
                self.delegate?.chatModel(self, didReceiveMessageFailed: messageForServer)
                self.signalError(error!)
                return
            }
            self.delegate?.chatModelDidFinishSendingMessage(self)
        }
    }
    
    open func updateUserProfile(typing: Bool,consultID: String,  read_messageID: String,  delivered_massageID : String) {
        let messageForServer = ["lastReadMessage"  : read_messageID,
                                "deliveredMessage" : delivered_massageID,
                                "consultation_request_id"   : consultID,
                                "typing": typing,
                                "user": [
                                    "type": userType
                                ]
            ]as [String: Any]
        
        let convertedMessage = self.convertToString(dictionaryData: messageForServer)

        guard let channel = self.channel else { return }
        // Enter this client with data and update once entered
        channel.presence.update(convertedMessage)
    }
    
    open func publishAttachement(_ message: [String : Any]) {
        let convertedMessage = self.convertToString(dictionaryData: message)
        self.channel?.publish(self.clientId, data: convertedMessage) { error in
            guard error == nil else {
                self.signalError(error!)
                return
            }
            self.delegate?.chatModelDidFinishSendingMessage(self)
        }
    }
    
    func convertToString(dictionaryData:Dictionary<String,Any>) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionaryData)
            if let json = String(data: jsonData, encoding: .utf8) {
                print(json)
                return json
            }
        } catch {
            return ""
        }
        return ""
    }
    
    open func sendTypingNotification(typing: Bool, consultation_id: String, readMessage:String, delieverMessage:String) {
        // Don't send a 'is typing' notification if user is already typing
        self.updateUserProfile(typing: typing, consultID: consultation_id,read_messageID: readMessage, delivered_massageID: delieverMessage)
    }
    
    fileprivate func detachHandlers() {
        
    }
    
    fileprivate func attemptReconnect(_ delay: Double) {
        self.delay(delay) {
            self.ablyRealtime?.connect()
        }
    }
    
    fileprivate func subscribeToEnterEvent(channel:ARTRealtimeChannel){
        channel.presence.subscribe(.enter) { member in
            if let data = member.clientId{
                self.delegate?.chatModel(self, userJoined: data, channelName: channel.name)
            }
        }
    }
    
    fileprivate func subscribeToLeaveEvent(channel:ARTRealtimeChannel){
        channel.presence.subscribe(.leave) { member in
            if let data = member.clientId{
                self.delegate?.chatModel(self, userLeft: data, channelName: channel.name)
            }
        }
    }
    
    fileprivate func subscribeToUpdateEvent(channel:ARTRealtimeChannel)
    {
        channel.presence.subscribe(.update) { member in
        }
    }
    
    
    fileprivate func submitEnterPresence(channel:ARTRealtimeChannel){
        guard let channel = self.channel else { return }
        // Enter this client with data and update once entered
        channel.presence.enter(nil) { error in
            print(error)
        }
    }
    
    fileprivate func submitLeavePresence(channel:ARTRealtimeChannel){
        guard let channel = self.channel else { return }
        // Enter this client with data and update once entered
        channel.presence.leave(nil) { error in
            
        }
    }
  
    fileprivate func joinChannel()
    {
        guard let channel = self.channel else { return }
        let presence = channel.presence
        
        channel.attach(){ error in
            if error != nil{
                self.channel = self.ablyRealtime?.channels.get("Gourav_test")
                self.joinChannel()
                return
            }
        }
        presence.subscribe(self.membersChanged)
        channel.subscribe(self.receiveMessage)

        self.submitEnterPresence(channel: channel)
        self.subscribeToEnterEvent(channel: channel)
        self.subscribeToLeaveEvent(channel: channel)
        self.subscribeToUpdateEvent(channel: channel)
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        let data = text.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]
            return json
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
        return nil
    }
    
    fileprivate func receiveMessage(_ msg : ARTMessage){
        if msg.data != nil {
            print("Success \(String(describing: msg.id))")
            if let dict =  msg.data as? Dictionary<String,Any> {
                self.processIncomingMessage(message: dict)
                print("Success \(String(describing: dict))")
            }
            else {
                if let message = self.convertToDictionary(text: msg.data as! String)
                {
                    self.processIncomingMessage(message: message)
                    print("Success \(String(describing: message))")
                }else{
                    
                }
            }
        }
    }
    
    
    private func processIncomingMessage(message:Dictionary<String, Any>){
        
        if let intentName   =   message["intentName"] as? String{
            switch intentName {
                case "incoming_text":
                    self.delegate?.chatModel(self, incomingText: message)
                    break;
                default:
                    break
            }
        }
    }
    
    fileprivate func membersChanged(_ msg: ARTPresenceMessage) {
        self.channel?.presence.get() { (result, error) in
            guard error == nil else {
                self.signalError(error!)
                return
            }
            let members = result ?? [ARTPresenceMessage]()
            self.delegate?.chatModel(self, membersDidUpdate: members, presenceMessage: msg)
        }
    }
    
    fileprivate func loadHistory() {
        var messageHistory: [ARTMessage]? = nil
        var presenceHistory: [ARTPresenceMessage]? = nil
        
        func displayIfReady() {
            guard messageHistory != nil && presenceHistory != nil else { return }
            
            var combinedMessageHistory = [ARTBaseMessage]()
            combinedMessageHistory.append(contentsOf: messageHistory! as [ARTBaseMessage])
            combinedMessageHistory.append(contentsOf: presenceHistory! as [ARTBaseMessage])
            combinedMessageHistory.sort(by: { (msg1, msg2) -> Bool in
                return msg1.timestamp!.compare(msg2.timestamp!) == .orderedAscending
            })
            
            self.delegate?.chatModel(self, historyDidLoadWithMessages: combinedMessageHistory)
        };
        
        self.getMessagesHistory { messages in
            messageHistory = messages;
            displayIfReady();
        }
        
        self.getPresenceHistory { presenceMessages in
            presenceHistory = presenceMessages;
            displayIfReady();
        }
    }
    
    fileprivate func getMessagesHistory(_ callback: @escaping ([ARTMessage]) -> Void) {
        do {
            try self.channel!.history(self.createHistoryQueryOptions()) { (result, error) in
                guard error == nil else {
                    self.signalError(error!)
                    return
                }
                
                let items = result?.items ?? [ARTMessage]()
                callback(items)
            }
        }
        catch let error as NSError {
            self.signalError(error as! ARTErrorInfo)
        }
    }
    
    fileprivate func getPresenceHistory(_ callback: @escaping ([ARTPresenceMessage]) -> Void) {
        do {
            try self.channel!.presence.history(self.createHistoryQueryOptions()) { (result, error) in
                guard error == nil else {
                    self.signalError(error!)
                    return
                }
                
                let items = result?.items ?? [ARTPresenceMessage]()
                callback(items)
            }
        }
        catch let error as NSError {
            self.signalError(error as! ARTErrorInfo)
        }
    }
    
    fileprivate func createHistoryQueryOptions() -> ARTRealtimeHistoryQuery {
        let query = ARTRealtimeHistoryQuery()
        query.limit = 50
        query.direction = .backwards
        query.untilAttach = true
        return query
    }
    
    fileprivate func didChannelLoseState(_ error: ARTErrorInfo?) {
        self.channel?.unsubscribe()
        self.channel?.presence.unsubscribe()
        self.ablyRealtime?.connection.once(.connected) { state in
            self.joinChannel()
        }
    }
    
    fileprivate func signalError(_ error: ARTErrorInfo) {
        self.delegate?.chatModel(self, didReceiveError: error)
    }
    
    fileprivate func delay(_ delay: Double, block: @escaping () -> Void) {
        let time = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: time, execute: block)
    }
    
    @objc fileprivate func applicationWillResignActiveEventReceived(_ notification: Notification) {
//        self.disconnect()
    }
    
    @objc fileprivate func applicationWillEnterForegroundEventReceived(_ notification: Notification) {
//        self.reconnect()
    }
    
    
    // MARK: - Video chat handling
    
    open func publishMessageForVideoCall(_ message: String, _ intentName : String, _ consult_ID : String, messageID:String) {
        let messageForServer = ["intentName":   intentName,
                                "uniqueId"  : messageID,
                                "consultation_request_id" : consult_ID,
                                "transient" :    true,
                                "payload": [
                                    "text": message
            ],
                                "user": [
                                    "type": "customer"
            ]
            ]as [String: Any]
        
        let convertedMessage = self.convertToString(dictionaryData: messageForServer)
        self.channel?.publish(self.clientId, data: convertedMessage) { error in
            guard error == nil else {
                self.signalError(error!)
                return
            }
            self.delegate?.chatModelDidFinishSendingMessage(self)
        }
    }
}

