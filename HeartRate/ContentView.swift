//
//  ContentView.swift
//  HeartRate
//
//  Created by Spotlight Deveaux on 2022-01-08.
//

import HealthKit
import MultipeerKit
import SwiftUI

struct ContentView: View {
    let handler = Handler()

    var body: some View {
        Text("Siphoning heart rate...")
            .padding()
            .onAppear {
                #if !targetEnvironment(macCatalyst)
                // Ensure we can authorize for HealthKit.
                let allTypes = Set([HKObjectType.quantityType(forIdentifier: .heartRate)!])

                handler.healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { success, _ in
                    if !success {
                        print("WHY DID YOU DO THAT")
                    }
                }
                #endif
                
                print(NSTemporaryDirectory())

                handler.setup()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
