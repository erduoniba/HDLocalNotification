//
//  LocalNotifManager.swift
//  HDLocalNotification
//
//  Created by denglibing on 2016/12/22.
//  Copyright © 2016年 denglibing. All rights reserved.
//

import UIKit

import UserNotifications

class LocalNotifManager: NSObject {
    
    class func getRemindTimeWithString(remindTime : String, afterMinter : Int) -> String {
        let array = remindTime.components(separatedBy: ":")
        if array.count == 2 {
            var hour = Int(array[0]);
            var minter = Int(array[1]);
            var totalMinter = hour! * 60 + minter!
            totalMinter += afterMinter
            
            hour = Int(totalMinter / 60)
            minter = Int(totalMinter % 60)
            if minter! > 9 {
                return String(hour!) + ":" + String(minter!)
            }
            else {
                return String(hour!) + ":0" + String(minter!)
            }
        }
        
        return remindTime;
    }
    
    override init(){
        
        /* 通知的action，在通知到来下拉通知或者在通知栏长按通知会出现
         authenticationRequired: 需要解锁显示，黑色文字。点击会被登录拦截,解锁后也不会打开app
         destructive: 红色文字,点击不会进app
         foreground: 黑色文字,点击会进app
         */
        let lockAction = UNNotificationAction(identifier: "lock_action", title: "点击解锁", options: .authenticationRequired)
        let cancelAction = UNNotificationAction(identifier: "cancel_action", title: "点击消失", options: .destructive)
        let sureAction = UNNotificationAction(identifier: "sure_action", title: "点击进入app", options: .foreground)
        
        //设置一组通知类型，通过 local_notification 来标识
        let category = UNNotificationCategory(identifier: "local_notification", actions: [sureAction, lockAction, cancelAction], intentIdentifiers: [], options: .customDismissAction)
        
        //将该类型的通知加入到 通知中心
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    // 设置在 dateString 启动通知，每一分钟执行一次，共times次
    func setLocalNotification(with dateString: String, times : Int) {
        
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        self.addNotifi(dateString: dateString, sound: UNNotificationSound(named: "Reminder_to_wear_watch.m4a"), index: 0, times: times, week: 0)
    }
    
    
    func addNotifi(dateString : String, sound : UNNotificationSound, index : Int, times : Int, week : Int) {
        
        if index >= times {
            return
        }
        
        let newDateString = LocalNotifManager.getRemindTimeWithString(remindTime: dateString, afterMinter: index)
        let array = newDateString.components(separatedBy: ":")
        let hour = Int(array[0]);
        let minute = Int(array[1]);
        var component = DateComponents()
        component.hour = hour
        component.minute = minute
        
        //通知有四种触发器:
        /*
        UNPushNotificationTrigger 触发APNS服务，系统自动设置（这是区分本地通知和远程通知的标识）
        UNTimeIntervalNotificationTrigger 一段时间后触发
        UNCalendarNotificationTrigger 指定日期触发
        UNLocationNotificationTrigger 根据位置触发，支持进入某地或者离开某地或者都有
         */
        let trigger = UNCalendarNotificationTrigger.init(dateMatching: component, repeats: true)
        
        // 通知上下文，通过categoryIdentifier来唤起对应的 通知类型
        let content = UNMutableNotificationContent()
        content.categoryIdentifier = "local_notification"
        content.title = "通知标题-_-"
        content.body = "通知实体*_*"
        content.sound = sound
        
        // 向消息通知注册多条 通知时，记得 request 的 identifier 不能用一个，如果设置了多条request，但是identifier都是一样的，只会触发最晚的那条通知
        let request = UNNotificationRequest(identifier: "request"+dateString+String(index), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            print("week:\(component.weekday) hour:\(component.hour) minute:\(component.minute) index : \(index) success")
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.addNotifi(dateString: dateString, sound: sound, index: index+1, times: times, week: week)
        }
    }

}
