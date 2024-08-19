//
//  ContentView.swift
//  IOSTemplateApp
//
//  Created by 村石 拓海 on 2024/05/12.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var motionManager = MotionManager()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Section(header: Text("Accelerometer Data").font(.headline)) {
                Text("x: \(motionManager.accelerationX)")
                Text("y: \(motionManager.accelerationY)")
                Text("z: \(motionManager.accelerationZ)")
            }

            Section(header: Text("Gyroscope Data").font(.headline)) {
                Text("x: \(motionManager.rotationRateX)")
                Text("y: \(motionManager.rotationRateY)")
                Text("z: \(motionManager.rotationRateZ)")
            }

            Section(header: Text("Distance from Origin").font(.headline)) {
                Text("Distance: \(motionManager.distance, specifier: "%.2f")")
            }

            Section(header: Text("Velocity").font(.headline)) {
                Text("x: \(motionManager.velocityX, specifier: "%.2f")")
                Text("y: \(motionManager.velocityY, specifier: "%.2f")")
                Text("z: \(motionManager.velocityZ, specifier: "%.2f")")
            }

            Section(header: Text("Position").font(.headline)) {
                Text("x: \(motionManager.positionX, specifier: "%.2f")")
                Text("y: \(motionManager.positionY, specifier: "%.2f")")
                Text("z: \(motionManager.positionZ, specifier: "%.2f")")
            }

            Spacer()
            
            Button(action: {
                if let csvURL = motionManager.exportCSV() {
                    shareCSV(url: csvURL)
                }
            }) {
                Text("Export CSV")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Spacer()
                .frame(height: 200)
        }
        .padding()
    }
    
    private func shareCSV(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let topController = UIApplication.shared.windows.first?.rootViewController {
            topController.present(activityVC, animated: true, completion: nil)
        }
    }
}

#Preview {
    ContentView()
}
