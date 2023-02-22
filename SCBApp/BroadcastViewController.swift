//
//  BroadcastViewController.swift
//  SCBApp
//
//  Created by Andrei Yakugov on 4/8/22.
//

import UIKit
import AVFoundation
import ReplayKit
import AVKit


class BroadcastViewController: UIViewController, AVPictureInPictureControllerDelegate {
    
    let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
    
    var broadcastPicker: RPSystemBroadcastPickerView?
    
    var label: UILabel!
    
    @IBOutlet weak var mClipTimeTextField: UITextField!
    
    @IBOutlet weak var mStartButton: UIButton!
    
    var mClipTime: Double!
    
    static let notificationName = "broadcastFinished" as CFString
    static let notificationName2 = "broadcastStarted" as CFString
    static let notificationName3 = "broadcastCliped" as CFString

    var playerLayer: AVPlayerLayer?
    var avPictureInPictureConctroller: AVPictureInPictureController?
    
    
    
    @IBAction func onReplaysButtonClicked(_ sender: Any) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "videoclips") as! VideoClipsTableViewController
        self.navigationController?.pushViewController(newViewController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        let scstatus = UIScreen.main.isCaptured

        mClipTimeTextField.isEnabled = !scstatus
        mStartButton.backgroundColor = !scstatus ? .green : .gray
        mStartButton.isEnabled = !scstatus

        startListeners()
        
        DispatchQueue.main.async {
            self.start()
        }
        

    }
    func saveClipfunc() {
        let defaults = UserDefaults(suiteName: "group.com.ishicorodayo.SCBApp")
        defaults!.set(mClipTime, forKey: "duration")
        defaults!.synchronize()
        sendNotificationForMessage(withIdentifier: Self.notificationName3)
        
        appDelegate?.sendNotification(title: "Save Clip", body: "Clip was saved successfully.")
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = .init(x: 25, y: 50, width: view.frame.size.width - 50, height: 30)
    }

    
    func start() {
        playerLayer?.removeFromSuperlayer()
        ImagePlayer.shared.imageProvider = DateImageProvider()

        playerLayer = AVPlayerLayer(player: ImagePlayer.shared.player)
        playerLayer?.frame = .init(x: 25, y: 50, width: view.frame.size.width - 50, height: 30)
        playerLayer?.videoGravity = .resizeAspect

        if AVPictureInPictureController.isPictureInPictureSupported() {
            avPictureInPictureConctroller = AVPictureInPictureController(playerLayer: playerLayer!)
            avPictureInPictureConctroller?.delegate = self
        }

        view.layer.addSublayer(playerLayer!)
        playerLayer?.isHidden = true
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            if let status = playerLayer?.player?.timeControlStatus {
                    switch status{
                        case .paused:
                            //Paused mode
                            print("paused")
                            saveClipfunc()
                        case .waitingToPlayAtSpecifiedRate:
                            //Resumed
                            print("resumed")
                        case .playing:
                            //Video Ended
                            print("ended")
                        @unknown default:
                            print("For future versions")
                        }
                    }
        }
    }
    deinit {
        // don't listen anymore
        stopListeners()
    }
    
    func startListeners() {
        stopListeners()
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passRetained(self).toOpaque(), { (center, observer, name, object, userInfo) in
                        // send the equivalent internal notification
            let mymsg:[String: CFNotificationName?] = ["identifier": name]
            NotificationCenter.default.post(name: .notificationname, object: observer, userInfo: mymsg as [AnyHashable : Any])
        }, Self.notificationName, nil, .deliverImmediately)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(bcfinished),
            name: .notificationname,
            object: nil)
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passRetained(self).toOpaque(), { (center, observer, name, object, userInfo) in
                        // send the equivalent internal notification
            let mymsg:[String: CFNotificationName?] = ["identifier2": name]
            NotificationCenter.default.post(name: .notificationname2, object: observer, userInfo: mymsg as [AnyHashable : Any])
        }, Self.notificationName2, nil, .deliverImmediately)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(bcstarted),
            name: .notificationname2,
            object: nil)
    }
    
    func stopListeners() {
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passRetained(self).toOpaque(), CFNotificationName(rawValue: Self.notificationName), nil)
        NotificationCenter.default.removeObserver(
            self,
            name: .notificationname,
            object: nil)
        
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), Unmanaged.passRetained(self).toOpaque(), CFNotificationName(rawValue: Self.notificationName2), nil)
        NotificationCenter.default.removeObserver(
            self,
            name: .notificationname2,
            object: nil)

    }
 
    @objc func bcstarted(noti: NSNotification){
        //do stuff using the userInfo property of the notification object
        if let iden = noti.userInfo?["identifier2"] as? CFNotificationName {
            let cfStr:CFString = iden.rawValue
            let nsTypeString = cfStr as NSString
            let swiftString = nsTypeString as String
            if swiftString == "broadcastStarted" {
                bcstart()
            }
        }
    }
    @objc func bcfinished(noti: NSNotification){
        //do stuff using the userInfo property of the notification object
        if let iden = noti.userInfo?["identifier"] as? CFNotificationName {
            let cfStr:CFString = iden.rawValue
            let nsTypeString = cfStr as NSString
            let swiftString = nsTypeString as String
            if swiftString == "broadcastFinished" {
                bcfinish()
            }
        }
    }

    private func bcstart() {
        
        if let avPictureInPictureConctroller = avPictureInPictureConctroller, !avPictureInPictureConctroller.isPictureInPictureActive {
            if #available(iOS 14.2, *) {
                avPictureInPictureConctroller.canStartPictureInPictureAutomaticallyFromInline = true
            }
            avPictureInPictureConctroller.startPictureInPicture()
            if playerLayer?.player == nil {
                ImagePlayer.shared.imageProvider = DateImageProvider()
                playerLayer?.player = ImagePlayer.shared.player
            }

            playerLayer?.player?.play()
            playerLayer?.player?.addObserver(self, forKeyPath: "rate", options: [], context: nil)
            
        }
    }
    private func bcfinish() {
        
        broadcastPicker!.isHidden = true
        label.isHidden = true
        mClipTimeTextField.isEnabled = true
        mStartButton.backgroundColor = .green
        mStartButton.isEnabled = true
        
        
        
        if let avPictureInPictureConctroller = avPictureInPictureConctroller, avPictureInPictureConctroller.isPictureInPictureActive {
            if #available(iOS 14.2, *) {
                avPictureInPictureConctroller.canStartPictureInPictureAutomaticallyFromInline = false
            }
            avPictureInPictureConctroller.stopPictureInPicture()
            
            playerLayer?.player?.removeObserver(self, forKeyPath: "rate", context: nil)
            playerLayer?.player?.pause()
            playerLayer?.player = nil
            
        }
    }

    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
       
    @IBAction func mStartButtonClicked(_ sender: Any) {
        
        if mClipTimeTextField.text == "" {
            print("TextField is nil")
            showErrorAlert(vc: self, title: "Input Error", message: "You've entered empty number. Please input correct !")
        } else {
            
            if #available(iOS 12.0, *) {
                let kPickerFrame = CGRect(x: 0, y: 0, width: 50, height: 50)
                broadcastPicker = RPSystemBroadcastPickerView(frame: kPickerFrame)
                broadcastPicker?.showsMicrophoneButton = true
                broadcastPicker?.backgroundColor = .cyan
                broadcastPicker?.preferredExtension = "com.ishicorodayo.SCBApp.mybroadcast"
                view.addSubview(broadcastPicker!)
                broadcastPicker?.center = self.view.center
                label = UILabel(frame: CGRect(x: 0, y: (broadcastPicker?.frame.maxY)!, width: self.view.frame.size.width, height: 30))
                label.text = "Click the button above to start recording"
                label.textAlignment = .center
                label.textColor = .red
                view.addSubview(label)
            }
            
            mClipTime = Double(mClipTimeTextField.text!)
            mClipTimeTextField.isEnabled = false
            mStartButton.backgroundColor = .gray
            mStartButton.isEnabled = false

        }
    }
    
    func showErrorAlert(vc: UIViewController, title: NSString?, message: NSString) {
        let alert: UIAlertController = UIAlertController(title: title as String?,
                                                         message: message as String,
                                                         preferredStyle: .alert);
        let cancelAction: UIAlertAction = UIAlertAction(title: "OK",
                                                        style: .cancel,
                                                        handler: nil)
        alert.addAction(cancelAction)
        vc.present(alert, animated: true, completion: nil)
    }
    
    
    
    public func sendNotificationForMessage(withIdentifier identifier: CFString?) {
            let center = CFNotificationCenterGetDarwinNotifyCenter()
            let deliverImmediately = true
            let identifierRef = identifier
            CFNotificationCenterPostNotification(center, CFNotificationName(rawValue: identifierRef!), nil, nil, deliverImmediately)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


        // MARK: - AVPictureInPictureControllerDelegate
        func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
            
            print("pip error: \(error)")
        }
        func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {

        }
        func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            playerLayer?.isHidden = false
        }

        func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            playerLayer?.isHidden = true
        }
        func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            
        }
        
}

extension Notification.Name {

    static let notificationname = Notification.Name("notificationname")
    static let notificationname2 = Notification.Name("notificationname2")
    static let goestobackground = Notification.Name("goestobackground")
    static let comebackfrombackground = Notification.Name("comebackfrombackground")
}

