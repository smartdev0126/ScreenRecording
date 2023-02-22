//
//  AppDelegate.swift
//  SCBApp
//
//  Created by Andrei Yakugov on 4/8/22.
//

import UIKit
import UserNotifications
import BackgroundTasks
import AVKit
import ReplayKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var backgroundTask: UIBackgroundTaskIdentifier!
    
    func registerForPushNotifications() {
        //1
          UNUserNotificationCenter.current()
            .requestAuthorization(
              options: [.alert, .sound, .badge]) { [weak self] granted, _ in
              print("Permission granted: \(granted)")
              guard granted else { return }
              self?.getNotificationSettings()
            }
    }
    // called if app is running in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent
        notification: UNNotification, withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void) {

        // show alert while app is running in foreground
        
        return completionHandler(UNNotificationPresentationOptions.banner)
    }

    // called when user interacts with notification (app not running in foreground)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse, withCompletionHandler
        completionHandler: @escaping () -> Void) {

        // do something with the notification
        print(response.notification.request.content.userInfo)

        // the docs say you should execute this asap
        return completionHandler()
    }
    func getNotificationSettings() { UNUserNotificationCenter.current().getNotificationSettings { settings in
        print("Notification settings: \(settings)")
        guard settings.authorizationStatus == .authorized else { return }
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
    }
    func application(_ application: UIApplication,
          didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
          let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
          let token = tokenParts.joined()
          print("Device Token: \(token)")
    }
    func application(_ application: UIApplication,
          didFailToRegisterForRemoteNotificationsWithError error: Error) {
          print("Failed to register: \(error)")
    }
    
    ////////////////////
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        registerForPushNotifications()
        UNUserNotificationCenter.current().delegate = self
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
         } catch {
             print("Setting category to AVAudioSessionCategoryPlayback failed.")
         }
        
        
        NotificationCenter.default.addObserver(forName:UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { (_) in
                // Your Code here
            //NotificationCenter.default.post(name: .comebackfrombackground, object: nil)

            print("Background ---> Foreground.")
        }

        NotificationCenter.default.addObserver(forName:UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { (_) in
               // Your Code here
            //NotificationCenter.default.post(name: .goestobackground, object: nil)

            print("Inactive ---> Background.")
        }
        
        
        return true
    }

    
    
    ////////////////////
    
    

    private func application(application: UIApplication, didReceiveLocalNotification notification: UNNotificationRequest) {
        print("Local notification received (tapped, or while app in foreground): \(notification)")
    }
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("Recived: \(userInfo)")

    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        completionHandler(.newData)
        
    }
    func sendNotification(title: String, body: String) {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        // content:
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "mynotification"
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        // trigger:
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
    }
}

