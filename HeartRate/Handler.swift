//
//  Handler.swift
//  HeartRate
//
//  Created by Spotlight Deveaux on 2022-01-08.
//

import Foundation
import HealthKit
import MultipeerKit

class Handler {
    var datasource: MultipeerTransceiver = {
        var config = MultipeerConfiguration.default
        config.serviceType = "heartrate"
        config.security.encryptionPreference = .required

        return MultipeerTransceiver(configuration: config)
    }()

    public let healthStore = HKHealthStore()
    let heartRateUnit = HKUnit(from: "count/min")
    var timer: Timer?

    func setup() {
        datasource.resume()

        timer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(doQuery), userInfo: nil, repeats: true)
    }

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
                let rate = HeartRateStruct()
                rate.rate = lastSample.quantity.doubleValue(for: heartRateUnit)

                datasource.send(rate, to: datasource.availablePeers)
            }
        }
        healthStore.execute(query)
    }
}
