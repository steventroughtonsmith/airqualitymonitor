//
//  ContentView.swift
//  AirQualityMonitor
//
//  Created by Steven Troughton-Smith on 06/10/2020.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var home = Home()
    
    var body: some View {
        VStack {
            Text("Loading…")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.fixed(width: 150, height: 40))
    }
}

