//
//  ContentView.swift
//  HeartRateRPC
//
//  Created by Spotlight Deveaux on 2022-01-08.
//

import MultipeerKit
import SwiftUI
import SwordRPC

struct ContentView: View {
    @ObservedObject var datasource: MultipeerDataSource = {
        var config = MultipeerConfiguration.default
        config.serviceType = "heartrate"
        config.security.encryptionPreference = .required

        let transceiver = MultipeerTransceiver(configuration: config)
        return MultipeerDataSource(transceiver: transceiver)
    }()

    let rpc = SwordRPC(appId: "929607600503390208")

    var body: some View {
        Text("Hello, world!")
            .padding()
            .onAppear {
                datasource.transceiver.resume()
                datasource.transceiver.receive(HeartRateStruct.self, using: { value, _ in

                    var presence = RichPresence()
                    presence.assets.largeImage = "healthkit"
                    presence.details = "Heart Rate"
                    presence.state = "\(Int(value.rate)) bpm"
                    rpc.setPresence(presence)
                })

                rpc.onConnect { _ in
                    print("Connected.")
                }
                rpc.connect()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
