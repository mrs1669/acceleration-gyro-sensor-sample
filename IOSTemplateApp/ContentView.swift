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
        VStack(alignment: .center, spacing: 12) { // セクション間の間隔を調整
            cardSection(header: "Accelerometer Data") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("x: \(motionManager.accelerationX)")
                    Text("y: \(motionManager.accelerationY)")
                    Text("z: \(motionManager.accelerationZ)")
                }
            }

            cardSection(header: "Gyroscope Data") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("x: \(motionManager.rotationRateX)")
                    Text("y: \(motionManager.rotationRateY)")
                    Text("z: \(motionManager.rotationRateZ)")
                }
            }

            cardSection(header: "Velocity") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("x: \(motionManager.velocityX, specifier: "%.2f")")
                    Text("y: \(motionManager.velocityY, specifier: "%.2f")")
                    Text("z: \(motionManager.velocityZ, specifier: "%.2f")")
                }
            }

            cardSection(header: "Position") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("x: \(motionManager.positionX, specifier: "%.2f")")
                    Text("y: \(motionManager.positionY, specifier: "%.2f")")
                    Text("z: \(motionManager.positionZ, specifier: "%.2f")")
                }
            }

            cardSection(header: "Distance from Origin") {
                Text("Distance: \(motionManager.distance, specifier: "%.2f")")
                    .foregroundColor(.red) // 距離だけ赤色に
            }
            .padding(.bottom, 8) // セクション間の間隔を調整

            Spacer()

            HStack {
                Button(action: {
                    motionManager.startUpdates()
                }) {
                    Text("Start")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                // リセットボタン
                Button(action: {
                    motionManager.resetData()
                }) {
                    Text("Reset")
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

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
            }
        }
        .padding()
    }

    @ViewBuilder
    private func cardSection<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(header)
                .font(.headline)
                .padding(.bottom, 4)
            content()
        }
        .frame(width: 200)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
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
