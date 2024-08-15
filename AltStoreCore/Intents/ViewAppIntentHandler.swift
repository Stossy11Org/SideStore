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
                let apps = InstalledApp.all(in: context).map { (installedApp: InstalledApp) in
                    // Create the mapping between AltStoreCore.App and InstalledApp
                    let app = AltStoreCore.App(identifier: installedApp.resignedBundleIdentifier, display: installedApp.name)
                    if let app = app.identifier {
                        self.appMapping[app] = installedApp
                    } else {
                        return nil
                    }
                    return app
                }
                
                let collection = INObjectCollection(items: apps)
                completion(collection, nil)
            }
        }
    }

    public func handle(intent: ViewAppIntent, completion: @escaping (ViewAppIntentResponse) -> Void)
    {
        guard let selectedApp = intent.app else {
            completion(ViewAppIntentResponse(code: .failure, userActivity: nil))
            return
        }
        // Retrieve the selected AltStoreCore.App
        guard let installedApp = appMapping[selectedApp.identifier] else {
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
