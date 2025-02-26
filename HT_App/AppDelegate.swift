//
//  AppDelegate.swift
//  HT_App
//
//  Created by Joy Itodo on 2/24/25.
//

import Foundation
import GoogleMaps


class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GMSServices.provideAPIKey(ProcessInfo.processInfo.environment["MAP_API_KEY"] as! String)
        return true
    }
}
