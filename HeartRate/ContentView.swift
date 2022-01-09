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
                let allTypes = Set([HKObjectType.quantityType(forIdentifier: .heartRate)!])
                
                handler.healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in
                    if !success {
                        print("WHY DID YOU DO THAT")
                    }
                }
                
                handler.setup()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
