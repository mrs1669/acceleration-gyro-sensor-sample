//
//  MotionManager.swift
//  IOSTemplateApp
//
//  Created by 村石 拓海 on 2024/08/14.
//

import Foundation
import CoreMotion

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()

    // 加速度
    @Published var accelerationX: Double = 0.0
    @Published var accelerationY: Double = 0.0
    @Published var accelerationZ: Double = 0.0

    // 回転速度
    @Published var rotationRateX: Double = 0.0
    @Published var rotationRateY: Double = 0.0
    @Published var rotationRateZ: Double = 0.0

    // 速度
    @Published var velocityX: Double = 0.0
    @Published var velocityY: Double = 0.0
    @Published var velocityZ: Double = 0.0

    // 位置
    @Published var positionX: Double = 0.0
    @Published var positionY: Double = 0.0
    @Published var positionZ: Double = 0.0

    // 原点からの距離
    @Published var distance: Double = 0.0

    private var motionData: [MotionData] = []
    private var previousTimestamp: Int64?

    init() {
        startDeviceMotionUpdates()
    }

    private func startDeviceMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.01 // 0.01秒に1回更新 = 1秒間に100回更新
            motionManager.startDeviceMotionUpdates(to: .main) { data, _ in
                if let data = data {
                    self.updateMotionData(data: data)
                }
            }
        }
    }

    private func updateMotionData(data: CMDeviceMotion) {
        // タイムスタンプをマイクロ秒単位で取得
        let timestamp = Int64(Date().timeIntervalSince1970 * 1_000_000)

        // duration を計算（一つ前のタイムスタンプとの差分）
        let duration: Double
        if let previousTimestamp = previousTimestamp {
            duration = Double(timestamp - previousTimestamp) / 1_000_000.0 // マイクロ秒を秒に変換
        } else {
            duration = 0.0
        }
        previousTimestamp = timestamp

        // ローカルフレームの加速度
        // 1.0(G) => 9.8m/s^2
        let accX = data.userAcceleration.x * 9.80665
        let accY = data.userAcceleration.y * 9.80665
        let accZ = data.userAcceleration.z * 9.80665

        // ローカルフレームの加速度をワールドフレームに変換
        let rotationMatrix = data.attitude.rotationMatrix
        let worldAccX = rotationMatrix.m11 * accX + rotationMatrix.m12 * accY + rotationMatrix.m13 * accZ
        let worldAccY = rotationMatrix.m21 * accX + rotationMatrix.m22 * accY + rotationMatrix.m23 * accZ
        let worldAccZ = rotationMatrix.m31 * accX + rotationMatrix.m32 * accY + rotationMatrix.m33 * accZ

        // 前の速度と積分して新しい速度を計算
        velocityX += worldAccX * duration
        velocityY += worldAccY * duration
        velocityZ += worldAccZ * duration

        // 速度を積分して現在の位置を計算
        positionX += velocityX * duration
        positionY += velocityY * duration
        positionZ += velocityZ * duration

        // 原点からの距離を計算
        distance = sqrt(positionX * positionX + positionY * positionY + positionZ * positionZ)

        // 公開プロパティの更新
        accelerationX = accX
        accelerationY = accY
        accelerationZ = accZ
        rotationRateX = data.rotationRate.x
        rotationRateY = data.rotationRate.y
        rotationRateZ = data.rotationRate.z

        // タイムスタンプとともにデータを保存
        self.addMotionData(timestamp: timestamp, duration: Int64(duration * 1_000_000)) // durationをマイクロ秒に変換
    }
    
    private func addMotionData(timestamp: Int64, duration: Int64) {
        let dataPoint = MotionData(
            duration: duration,
            timestamp: timestamp,
            accelerationX: accelerationX,
            accelerationY: accelerationY,
            accelerationZ: accelerationZ,
            rotationRateX: rotationRateX,
            rotationRateY: rotationRateY,
            rotationRateZ: rotationRateZ,
            velocityX: velocityX,
            velocityY: velocityY,
            velocityZ: velocityZ,
            positionX: positionX,
            positionY: positionY,
            positionZ: positionZ
        )
        motionData.append(dataPoint)
    }

    func exportCSV() -> URL? {
        let fileName = "motion_data.csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var csvText = "Duration(µs),Timestamp(µs),AccelerationX,AccelerationY,AccelerationZ,RotationRateX,RotationRateY,RotationRateZ,VelocityX,VelocityY,VelocityZ,PositionX,PositionY,PositionZ\n"

        for data in motionData {
            // swiftlint:disable:next line_length
            let line = "\(data.duration),\(data.timestamp),\(data.accelerationX),\(data.accelerationY),\(data.accelerationZ),\(data.rotationRateX),\(data.rotationRateY),\(data.rotationRateZ),\(data.velocityX),\(data.velocityY),\(data.velocityZ),\(data.positionX),\(data.positionY),\(data.positionZ)\n"
            csvText.append(line)
        }

        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Failed to create CSV file: \(error.localizedDescription)")
            return nil
        }
    }
}
