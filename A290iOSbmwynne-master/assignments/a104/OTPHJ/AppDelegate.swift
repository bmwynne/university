//
//  AppDelegate.swift
//  OTPHJ
//
//  Created by Brandon Wynne on 10/11/16.
//  Copyright © 2016 A290 Spring 2016 - bmwynne, jfbinzer. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        loadData()
        return true
    }
    
    func loadData() {
        let defaults = NSUserDefaults.standardUserDefaults()
        let name = defaults.valueForKey("username") as? String
        let topology = defaults.valueForKey("topology") as? Bool
        let color = defaults.valueForKey("lineColor") as? String
        
        if (name != nil){
            mainVariables.name = name!
        }
        if (topology != nil) {
            mainVariables.topology = topology!
        }
        if (color != nil) {
            switch (color!) {
            case "red" : mainVariables.color = UIColor.redColor()
            case "yellow": mainVariables.color = UIColor.yellowColor()
            case "green": mainVariables.color = UIColor.greenColor()
            case "blue": mainVariables.color = UIColor.blueColor()
            default: mainVariables.color = UIColor.redColor()
            }
        }
    }
    
    func saveData() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(mainVariables.name, forKey: "name")
        defaults.setValue(mainVariables.topology, forKey: "topology")
        defaults.setValue(mainVariables.color, forKey: "lineColor")
    }
    
    
    
    

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        saveData()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

