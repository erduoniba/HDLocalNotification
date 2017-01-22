//
//  AppDelegate.swift
//  HDLocalNotification
//
//  Created by denglibing on 2016/12/22.
//  Copyright © 2016年 denglibing. All rights reserved.
//

import UIKit

import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    //后台任务
    var backgroundTask : UIBackgroundTaskIdentifier! = nil

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (resulet, error) in
            if resulet {
                print("register notification success")
            }
            else {
                print("register notification fail error.localizedDescription:\(error?.localizedDescription)")
            }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        //如果已存在后台任务，先将其设为完成
        if self.backgroundTask != nil {
            application.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskInvalid
        }
        
        //注册后台任务
        self.backgroundTask = application.beginBackgroundTask(expirationHandler: {
            () -> Void in
            //如果没有调用endBackgroundTask，时间耗尽时应用程序将被终止
            application.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskInvalid
        })
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        //需求：需要取消今日的本地通知
        //思路是即将进入app前台时，先获取通知中心的所有通知，再取消所有的通知，然后在拿到的所有通知一一找到其下一个触发的时间和现在对比，如果大于一天则重新加入通知中心
        
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests : [UNNotificationRequest]) in
            
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            
            let formatter = DateFormatter()
            formatter.dateFormat = "dd"
            let dateString = formatter.string(from: Date())
            let dateInt = Int(dateString)
            
            for request in requests {
                let trigger = request.trigger as! UNCalendarNotificationTrigger
                let nextTriggerDate = trigger.nextTriggerDate()
                let nextTriggerDateString = formatter.string(from: nextTriggerDate!)
                let nextTriggerDateInt = Int(nextTriggerDateString)
                
                print("dateInt:\(dateInt) nextTriggerDateInt:\(nextTriggerDateInt)")
                
                //触发时间比现在在 1 天以后，说明是第二天的通知了，需要重新加入到通知中心
                if nextTriggerDateInt! - dateInt! > 0 {
                    
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
                        
                    })
                }
                
            }
        })

    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        print("shortcutItem.type: \(shortcutItem.type)")
    }

    
    // The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
    // app在前台运行时，收到通知会唤起该方法，但是前提是得 实现该方法 及 实现completionHandler
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Swift.Void){
        
        print("categoryIdentifier: \(notification.request.content.categoryIdentifier)")
        
        completionHandler(.alert)
    }
    
    // The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from applicationDidFinishLaunching:.
    // 用户收到通知点击进入app的时候唤起，
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Swift.Void) {
        
        let catogoryIdentifier = response.notification.request.content.categoryIdentifier
        if catogoryIdentifier == "local_notification" {
            
            if response.actionIdentifier == "sure_action" {
                print("response.actionIdentifier: sure_action")
            }
            
        }
        
        completionHandler()
    }

}

