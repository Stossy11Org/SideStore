//
//  ViewAppIntentHandler.swift
//  ViewAppIntentHandler
//
//  Created by Riley Testut on 7/10/20.
//  Copyright © 2020 Riley Testut. All rights reserved.
//

import Intents
import AltStoreCore
import minimuxer

@available(iOS 14, *)
public class ViewAppIntentHandler: NSObject, ViewAppIntentHandling
{
    // Store a mapping from AltStoreCore.App to InstalledApp
    private var appMapping: [String: InstalledApp] = [:]
    
    public func provideAppOptionsCollection(for intent: ViewAppIntent, with completion: @escaping (INObjectCollection<AltStoreCore.App>?, Error?) -> Void)
    {
        DatabaseManager.shared.start { (error) in
            if let error = error
            {
                print("Error starting extension:", error)
            }
            
            DatabaseManager.shared.persistentContainer.performBackgroundTask { (context) in
                let apps = InstalledApp.all(in: context).compactMap { (installedApp: InstalledApp) in
                    // Safely unwrap the identifier
                    let identifier = installedApp.resignedBundleIdentifier
                    let app = AltStoreCore.App(identifier: identifier, display: installedApp.name)
                    self.appMapping[identifier] = installedApp
                    return app
                }
                
                let collection = INObjectCollection(items: apps)
                completion(collection, nil)
            }
        }
    }

    public func handle(intent: ViewAppIntent, completion: @escaping (ViewAppIntentResponse) -> Void)
    {
        // Safely unwrap the identifier
        guard let selectedApp = intent.app, let identifier = selectedApp.identifier, let installedApp = appMapping[identifier] else {
            completion(ViewAppIntentResponse(code: .failure, userActivity: nil))
            return
        }
         
        // Enable JIT for the selected InstalledApp
        AppManager.shared.enableJIT(for: installedApp) { result in
            switch result {
            case .success:
                completion(ViewAppIntentResponse(code: .success, userActivity: nil))
            case .failure(let error):
                print("Error enabling JIT:", error)
                completion(ViewAppIntentResponse(code: .failure, userActivity: nil))
            }
        }
    }
}
