//
//  Handler.swift
//  HeartRate
//
//  Created by Spotlight Deveaux on 2022-01-08.
//

import Foundation
import MultipeerKit

#if targetEnvironment(macCatalyst)
// On a Mac, we want to send data to Discord.
import SwordRPC
#else
// Otherwise, we want to query health information.
import HealthKit
#endif

class Handler {
    var datasource: MultipeerTransceiver = {
        var config = MultipeerConfiguration.default
        config.serviceType = "heartrate"
        config.security.encryptionPreference = .required

        return MultipeerTransceiver(configuration: config)
    }()
    
    #if targetEnvironment(macCatalyst)
    /// Utilized to broadcast our heart rate.
    let rpc = SwordRPC(appId: "929607600503390208")
    #else
    /// Used to access health data.
    public let healthStore = HKHealthStore()
    /// Used to query our BPM.
    let heartRateUnit = HKUnit(from: "count/min")
    /// Used to obtain heart rate data.
    var timer: Timer?
    #endif

    func setup() {
        datasource.resume()

        #if targetEnvironment(macCatalyst)
        // on macOS, we're expected to send RPC information.
        datasource.receive(HeartRateStruct.self, using: { value, _ in

            var presence = RichPresence()
            presence.assets.largeImage = "healthkit"
            presence.details = "Heart Rate"
            presence.state = "\(Int(value.rate)) bpm"
            self.rpc.setPresence(presence)
        })

        rpc.onConnect { _ in
            print("Connected.")
        }
        rpc.connect()
        #else
        // Otherwise, we want to query HealthKit.
        timer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(doQuery), userInfo: nil, repeats: true)
        #endif
    }

    #if !targetEnvironment(macCatalyst)
    // On iOS, we want to query HealthKit.
    @objc func doQuery() {
        guard let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            fatalError("*** This method should never fail ***")
        }
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
                                                              end: Date.now,
                                                              options: .strictEndDate)

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                              ascending: false)

        let query = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: 1, sortDescriptors: [sortDescriptor]) {
            _, results, error in

            guard let samples = results as? [HKQuantitySample] else {
                // Handle any errors here.
                print(error)
                return
            }

            let lastSample = samples.first!

            DispatchQueue.main.async { [self] in
                var rate = HeartRateStruct()
                rate.rate = lastSample.quantity.doubleValue(for: heartRateUnit)

                datasource.send(rate, to: datasource.availablePeers)
            }
        }
        healthStore.execute(query)
    }
    #endif
}
