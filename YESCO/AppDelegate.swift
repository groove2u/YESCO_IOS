//
//  AppDelegate.swift
//  HiHR
//
//  Created by skyblue on 2021/06/23.
//  Copyright © 2021 skyblue. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var gcmMessageIDKey = "AAAA_BZ2jI8:APA91bHvZzX-q8-4jHZkvN-FPKzOXL5ZtPRJ4ndQW0Quokeo0E0rQWQiPXxONJGopWBOTrkFZYZ-zoysHQGICBHEaCWcNQgLkd52XGzZxt9q7UC3NkHoPLn3rmAC1SXcpspsyT4os47t"
    static var fcmToken = String()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
//        registerForPushNotifications()
        
        Messaging.messaging().subscribe(toTopic: "news") { error in
            print("Subscribed to news topic")
        }
        
        return true
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self?.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
       
        AppDelegate.fcmToken = deviceToken.hexString
        print("Current fcmToken is : \(AppDelegate.fcmToken)")
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register: \(error.localizedDescription)")
    }
    func application(
        _ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
       
        print(userInfo)
        completionHandler(.newData)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}


extension AppDelegate : UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print("Will Present User Info: \(userInfo)")
        
        if #available(iOS 14.0, *) {
            completionHandler([[.banner, .sound]])
        } else {
            // Fallback on earlier versions
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        if response.actionIdentifier == "accept" {
            print("Did Receive User Info: \(userInfo)")
            
            completionHandler()
        }
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let dataDict: [String: String] = [AppDelegate.fcmToken: fcmToken ?? ""]
        NotificationCenter.default.post(name: NSNotification.Name("FCMToken"), object: nil, userInfo: dataDict)

        // Note: This callback is fired at each app startup and whenever a new token is generated.
        AppDelegate.fcmToken = fcmToken!
        
        let pref = UserDefaults.standard
        pref.setValue(fcmToken!, forKey: "token")
        pref.synchronize()
        
        
    }
}

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}
