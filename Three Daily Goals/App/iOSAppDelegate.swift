////
////  AppDelegate.swift
////  Three Daily Goals
////
////  Created by Klaus Kneupner on 06/02/2024.
////
//
//import UserNotifications
//
//#if os (iOS)
//import UIKit
//
//class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        // Request notification permission
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
//            if granted {
//                DispatchQueue.main.async {
//                    application.registerForRemoteNotifications()
//                }
//            }
//            // Handle errors
//        }
//        
//        UNUserNotificationCenter.current().delegate = self
//        return true
//    }
//    
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        // Handle the registration and possibly send the device token to your server
//    }
//    
//    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        // Handle registration failure
//    }
//}
//
//#endif
//
//#if os(macOS)
//import AppKit
//
//class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
//    func application(_ application: NSApplication, didFinishLaunchingWithOptions launchOptions: [NSApplication.LaunchOptions : Any]? = nil) -> Bool {
//        // Request notification permission
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
//            if granted {
//                DispatchQueue.main.async {
//                    application.registerForRemoteNotifications()
//                }
//            }
//            // Handle errors
//        }
//        
//        UNUserNotificationCenter.current().delegate = self
//        return true
//    }
//    
//    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        // Handle the registration and possibly send the device token to your server
//    }
//    
//    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        // Handle registration failure
//    }
//}
//
//#endif
