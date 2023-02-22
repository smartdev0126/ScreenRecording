//
//  SampleHandler.swift
//  mybroadcast
//
//  Created by Andrei Yakugov on 4/16/22.
//

import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {

    private var writer: BroadcastWriter?
    private let fileManager: FileManager = .default
    private let notificationCenter = UNUserNotificationCenter.current()
    static let notificationName = "broadcastFinished" as CFString
    static let notificationName2 = "broadcastStarted" as CFString
    static let notificationName3 = "broadcastCliped" as CFString
    let randomNumber = arc4random_uniform(9999)

    func createReplaysFolder()
        {
            // path to documents directory
            let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
            if let documentDirectoryPath = documentDirectoryPath {
                // create the custom folder path
                let replayDirectoryPath = documentDirectoryPath.appending("/Replays")
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: replayDirectoryPath) {
                    do {
                        try fileManager.createDirectory(atPath: replayDirectoryPath,
                                                        withIntermediateDirectories: false,
                                                        attributes: nil)
                    } catch {
                        print("Error creating Replays folder in documents dir: \(error)")
                    }
                }
            }
        }
    func filePath(_ fileName: String) -> String
        {
            createReplaysFolder()
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory = paths[0] as String
            let filePath : String = "\(documentsDirectory)/Replays/\(fileName).mp4"
            return filePath
        }
    override init() {

        super.init()

        startListeners()
    }
    deinit {
        // don't listen anymore
        stopListeners()
    }
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        let screen: UIScreen = .main
        
        let nodeURL = URL(fileURLWithPath: filePath("coolSCR\(randomNumber)"))
        fileManager.removeFileIfExists(url: nodeURL)
        do {
            writer = try .init(
                outputURL: nodeURL,
                screenSize: screen.bounds.size,
                screenScale: screen.scale
            )
        } catch {
            assertionFailure(error.localizedDescription)
            finishBroadcastWithError(error)
            return
        }
        do {
            try writer?.start()
            
        } catch {
            finishBroadcastWithError(error)
        }
        sendNotificationForMessage(withIdentifier: Self.notificationName2)
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard let writer = writer else {
            debugPrint("processSampleBuffer: Writer is nil")
            return
        }

        do {
            let captured = try writer.processSampleBuffer(sampleBuffer, with: sampleBufferType)
            debugPrint("processSampleBuffer captured", captured)
        } catch {
            debugPrint("processSampleBuffer error:", error.localizedDescription)
        }
    }

    override func broadcastPaused() {
        debugPrint("=== paused")
        writer?.pause()
    }

    override func broadcastResumed() {
        debugPrint("=== resumed")
        writer?.resume()
    }

    override func broadcastFinished() {
        let outputURL: URL?
        do {
            outputURL = try writer?.finish()
            sendNotificationForMessage(withIdentifier: Self.notificationName)
        } catch {
            debugPrint("writer failure", error)
            return
        }

        guard let containerURL = fileManager.containerURL(
                    forSecurityApplicationGroupIdentifier: "group.com.ishicorodayo.SCBApp"
        )?.appendingPathComponent("Library/Documents/") else {
            fatalError("no container directory")
        }
        do {
            try fileManager.createDirectory(
                at: containerURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            debugPrint("error creating", containerURL, error)
        }

        let destination = containerURL.appendingPathComponent(outputURL!.lastPathComponent)
        do {
            debugPrint("Moving", outputURL!, "to:", destination)
            try self.fileManager.moveItem(
                at: outputURL!,
                to: destination
            )

        } catch {
            debugPrint("ERROR", error)
        }

        debugPrint("FINISHED")
        
        
    }
    private func sendNotificationForMessage(withIdentifier identifier: CFString?) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let deliverImmediately = true
        let identifierRef = identifier
        CFNotificationCenterPostNotification(center, CFNotificationName(rawValue: identifierRef!), nil, nil, deliverImmediately)
    }
    
    func startListeners() {
        stopListeners()

        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passRetained(self).toOpaque(), { (center, observer, name, object, userInfo) in
                        // send the equivalent internal notification
            let mymsg:[String: CFNotificationName?] = ["identifier": name]
            NotificationCenter.default.post(name: .notificationname3, object: observer, userInfo: mymsg as [AnyHashable : Any])
        }, Self.notificationName3, nil, .deliverImmediately)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(bccliped),
            name: .notificationname3,
            object: nil)

         
    }
    
    func stopListeners() {
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passRetained(self).toOpaque(), CFNotificationName(rawValue: Self.notificationName3), nil)
        NotificationCenter.default.removeObserver(
            self,
            name: .notificationname3,
            object: nil)
         
    }
    @objc func bccliped(noti: NSNotification){
        //do stuff using the userInfo property of the notification object
        if let iden = noti.userInfo?["identifier"] as? CFNotificationName {
            let cfStr:CFString = iden.rawValue
            let nsTypeString = cfStr as NSString
            let swiftString = nsTypeString as String
            if swiftString == "broadcastCliped" {
                
                
                let defaults = UserDefaults(suiteName: "group.com.ishicorodayo.SCBApp")
                defaults!.synchronize()
                let duration = defaults!.double(forKey: "duration")
                
                
                
                // paused
                let outputURL: URL?
                do {
                    outputURL = try writer?.finish()
                } catch {
                    debugPrint("writer failure", error)
                    return
                }
 
                trimVideo(sourceURL1: outputURL!, duration: duration)
                
                
                // resumed
                let nodeURL = URL(fileURLWithPath: filePath("coolSCR\(randomNumber)"))
                fileManager.removeFileIfExists(url: nodeURL)
                
                let screen: UIScreen = .main
                do {
                    writer = try .init(
                        outputURL: nodeURL,
                        screenSize: screen.bounds.size,
                        screenScale: screen.scale
                    )
                } catch {
                    assertionFailure(error.localizedDescription)
                    finishBroadcastWithError(error)
                    return
                }
                do {
                    try writer?.start()
                } catch {
                    finishBroadcastWithError(error)
                }
                
            }
        }
    }

    
    func trimVideo(sourceURL1: URL, duration: Double) {
        let videoAsset: AVAsset = AVAsset(url: sourceURL1) as AVAsset
        let composition = AVMutableComposition()
        composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID())

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: 1280, height: 768)

        let length = Double(videoAsset.duration.seconds)


        let start = duration >= length ? 0 : length - duration
        let end = length

        let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetHighestQuality)!
        exportSession.outputFileType = AVFileType.mp4

        let startTime = CMTime(seconds: Double(start ), preferredTimescale: 1000)
        let endTime = CMTime(seconds: Double(end ), preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)

        exportSession.timeRange = timeRange

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"

        let date = Date()

        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let outputPath = "\(documentsPath)/\(formatter.string(from: date))-abcd.mp4"
        let outputURL = URL(fileURLWithPath: outputPath)

        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mov
        print("sucess")
        exportSession.exportAsynchronously(completionHandler: { () -> Void in
            DispatchQueue.main.async(execute: {
                let myurl = exportSession.outputURL
                self.saveToCameraRoll(desurl: myurl!)
            })
        })
    }


    func saveToCameraRoll(desurl: URL) {
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(desurl.relativePath) {
            UISaveVideoAtPathToSavedPhotosAlbum(desurl.relativePath, nil, nil, nil)
        }
    }


}
extension FileManager {

    func removeFileIfExists(url: URL) {
        guard fileExists(atPath: url.path) else { return }
        do {
            try removeItem(at: url)
        } catch {
            print("error removing item \(url)", error)
        }
    }
}
extension Notification.Name {

    static let notificationname3 = Notification.Name("notificationname3")
}
