### iOS10通知使用／3D-Touch使用

#### 概序：

主要实现iOS10中 `UserNotifications` 对带选择控制的本地通知的使用，只要点击了当日日的通知或者进入了app，当日的本地通知不再相应功能；使用 `3D-Touch` 在桌面上来快速启动app的功能；使用后台多任务功能；



#### 1、本地通知：

iOS10 全新的 `UserNotifications` 框架将iOS系统的远程和本地通知做了统一的管理，下面介绍一下本地通知的一些流程及注意点：

**1.1 注册通知中心：** 并且实现响应的代理

```swift
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

// app在前台运行时，收到通知会唤起该方法，但是前提是得 实现该方法 及 实现completionHandler
func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Swift.Void){
    print("categoryIdentifier: \(notification.request.content.categoryIdentifier)")
    completionHandler(.alert)
}

// 用户收到通知点击进入app的时候唤起，
@available(iOS 10.0, *)
func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Swift.Void) {
    let catogoryIdentifier = response.notification.request.content.categoryIdentifier
    if catogoryIdentifier == "local_notification" {
    	// 根据事件的 identifier 来响应对应的通知点击事件
        if response.actionIdentifier == "sure_action" {
            print("response.actionIdentifier: sure_action")
        }
    }
    completionHandler()
}
```



**1.2 设置自定义的通知类型:**  使用 `UNNotificationCategory` 来管理一组通知的自定义事件,  参数说明：

`authenticationRequired: 需要解锁显示, 黑色文字, 点击会被登录拦截, 解锁后也不会打开app`  

`destructive: 红色文字,点击不会进app`

`foreground: 黑色文字,点击会进app` 

```swift
let lockAction = UNNotificationAction(identifier: "lock_action", title: "点击解锁", options: .authenticationRequired)
let cancelAction = UNNotificationAction(identifier: "cancel_action", title: "点击消失", options: .destructive)
let sureAction = UNNotificationAction(identifier: "sure_action", title: "点击进入app", options: .foreground)

//设置一组通知类型，通过 local_notification 来标识
let category = UNNotificationCategory(identifier: "local_notification", actions: [sureAction, lockAction, cancelAction], intentIdentifiers: [], options: .customDismissAction)

//将该类型的通知加入到 通知中心
UNUserNotificationCenter.current().setNotificationCategories([category])
```



**1.3 向通知中心加入通知：** 通知触发器有四种方式：

`UNPushNotificationTrigger: 触发APNS服务，系统自动设置（这是区分本地通知和远程通知的标识）` 

`UNTimeIntervalNotificationTrigger: 一段时间后触发` 

`UNCalendarNotificationTrigger: 指定日期触发`

`UNLocationNotificationTrigger: 根据位置触发，支持进入某地或者离开某地或者都有`

具体使用方式对应的api都有详细的说明。

需要注意的是：

通知间隔设置需要 **60S** 以上，更换通知声音时，记得先卸载app然后重新运行；

向消息通知注册多条 通知时，记得 request 的 identifier 不能用一个，如果设置了多条request，但是identifier都是一样的，只会触发最晚的那条通知。

```swift
LocalNotifManager.swift

// 在 dateString 之后，每一分钟执行一次通知
// dateString：触发通知的时间 sound：通知触发时声音 index：第几次注册通知 times：共需要注册几次
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
    let trigger = UNCalendarNotificationTrigger.init(dateMatching: component, repeats: true)
    
    // 通知上下文，通过categoryIdentifier来唤起对应的 通知类型
    let content = UNMutableNotificationContent()
    content.categoryIdentifier = "local_notification"
    content.title = "通知标题-_-"
    content.body = "通知实体*_*"
    content.sound = sound
    
    let request = UNNotificationRequest(identifier: "request"+dateString+String(index), content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
        print("week:\(component.weekday) hour:\(component.hour) minute:\(component.minute) index : \(index) success")
    })
    
    // 预留一小段时间处理下一条通知的加入
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.addNotifi(dateString: dateString, sound: sound, index: index+1, times: times, week: week)
    }
}


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
```

好了，就这样调用如下代码即可 在每日的 `12:34 - 12:44` 时间段中每隔一分钟执行一次本地通知

```swift
LocalNotifManager().setLocalNotification(with: "12:34", times: 10)
```



**1.4 继续完善需求咯**，点击进入app后，不再接受当日的其他通知，这个在网上确实找了好多资料，都没有找到好的方式来解决，后来只能说是 **天佑残疾**，无意中我在api中发现了两个重要的方法：

```swift
// UNUserNotificationCenter: 获取还未触发的通知列表
open func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Swift.Void)
    
// UNCalendarNotificationTrigger: 获取该通知下一个触发的时间日期
open func nextTriggerDate() -> Date?
```

有了这两个接口就好办多了，大概的思路是在app进入前台时，先通过 `getPendingNotificationRequests` 拿到通知中心的所有未触发通知，再取消所有的通知，然后在拿到的所有通知列表中，一一找到通知的下一个触发时间和现在时间对比，如果大于等于一天则重新加入通知中心：

```swift
func applicationWillEnterForeground(_ application: UIApplication) {
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
            
            //触发时间比现在在 0 天以后，说明是第二天的通知了，需要重新加入到通知中心
            if nextTriggerDateInt! - dateInt! > 0 {
                UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in

                })
            }
            
        }
    })
}
```



#### 2、 `3D-Touch` 体验

这个功能很简单，这里只是做一下记录吧：

```xml
<!-- info.plist添加如下代码 -->
<key>UIApplicationShortcutItems</key>
<array>
    <dict>
        <key>UIApplicationShortcutItemTitle</key>
        <string>现在穿衣服吧</string>
        <key>UIApplicationShortcutItemType</key>
        <string>com.harry.HDLocalNotification.wear</string>
        <key>UIApplicationShortcutItemIconFile</key>
        <string>3d_touch _wear_icon</string>
        <key>UIApplicationShortcutItemUserInfo</key>
        <dict>
            <key>key1</key>
            <string>value1</string>
        </dict>
    </dict>
    <dict>
        <key>UIApplicationShortcutItemTitle</key>
        <string>现在脱衣服吧</string>
        <key>UIApplicationShortcutItemType</key>
        <string>com.harry.HDLocalNotification.notWear</string>
        <key>UIApplicationShortcutItemIconFile</key>
        <string>3d_touch_not_wear_icon</string>
        <key>UIApplicationShortcutItemUserInfo</key>
        <dict>
            <key>key2</key>
            <string>value2</string>
        </dict>
    </dict>
</array>
```

```swift
// AppDelegate: 根据info.plist中的 UIApplicationShortcutItemType值 找到对应的事件即可
func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
    print("shortcutItem.type: \(shortcutItem.type)")
}
```



#### 3、使用后台多任务功能

这个是在支持多个通知的时候使用，因为多个通知添加到通知中心时，我使用了队列处理，数量多的时候有一定的耗时，这个时候可能就需要后台多任务来跑这些任务了：

```swift
//后台任务
var backgroundTask : UIBackgroundTaskIdentifier! = nil

//进入后台后
func applicationDidEnterBackground(_ application: UIApplication) {
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
```



完整项目地址：  [HDLocalNotification](https://github.com/erduoniba/HDLocalNotification)

欢迎 **star** 