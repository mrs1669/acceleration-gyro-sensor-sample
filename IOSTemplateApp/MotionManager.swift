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
    
    // 補正値
    @Published var zeroGCalibration: (x: Double, y: Double, z: Double)?

    // 補正用変数
    private var zeroGCalibrationX: Double = 0.0
    private var zeroGCalibrationY: Double = 0.0
    private var zeroGCalibrationZ: Double = 0.0
    private var calibrationDataCount = 0
    private var numberOfcalibrationData = 1000

    // 加速度を保存するリスト
    private var initialAccelerationData: [(Double, Double, Double)] = []

    // 計測フラグ
    private var isCalibrating = true

    private var motionData: [MotionData] = []
    private var previousTimestamp: Int64?

    func startUpdates() {
        startDeviceMotionUpdates()
    }

    func resetData() {
        // 速度や位置、距離を初期化
        velocityX = 0.0
        velocityY = 0.0
        velocityZ = 0.0
        positionX = 0.0
        positionY = 0.0
        positionZ = 0.0
        distance = 0.0

        // 加速度や回転行列もリセット
        accelerationX = 0.0
        accelerationY = 0.0
        accelerationZ = 0.0
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
        let accX = data.userAcceleration.x * 9.80665
        let accY = data.userAcceleration.y * 9.80665
        let accZ = data.userAcceleration.z * 9.80665

        if isCalibrating {
            if calibrationDataCount < numberOfcalibrationData {
                initialAccelerationData.append((accX, accY, accZ))
                calibrationDataCount += 1

                if calibrationDataCount == numberOfcalibrationData {
                    calculateZeroGOffset()
                }
                return
            }
        }

        // 補正適用 (501データ目以降)
        let correctedAccX = accX - zeroGCalibrationX
        let correctedAccY = accY - zeroGCalibrationY
        let correctedAccZ = accZ - zeroGCalibrationZ

        // ローカルフレームの加速度をワールドフレームに変換
        let rotationMatrix = data.attitude.rotationMatrix
        let worldAccX = rotationMatrix.m11 * correctedAccX + rotationMatrix.m12 * correctedAccY + rotationMatrix.m13 * correctedAccZ
        let worldAccY = rotationMatrix.m21 * correctedAccX + rotationMatrix.m22 * correctedAccY + rotationMatrix.m23 * correctedAccZ
        let worldAccZ = rotationMatrix.m31 * correctedAccX + rotationMatrix.m32 * correctedAccY + rotationMatrix.m33 * correctedAccZ

        // ドリフト防止: 加速度が小さいときはゼロにする
        let accelerationThreshold = 0.02 // 誤差を許容できる範囲のしきい値
        let clippedWorldAccX = abs(worldAccX) < accelerationThreshold ? 0.0 : worldAccX
        let clippedWorldAccY = abs(worldAccY) < accelerationThreshold ? 0.0 : worldAccY
        let clippedWorldAccZ = abs(worldAccZ) < accelerationThreshold ? 0.0 : worldAccZ

        // 前の速度と積分して新しい速度を計算
        velocityX += clippedWorldAccX * duration
        velocityY += clippedWorldAccY * duration
        velocityZ += clippedWorldAccZ * duration

        // 低速での速度クリップ
        let velocityThreshold = 0.01
        if abs(velocityX) < velocityThreshold { velocityX = 0.0 }
        if abs(velocityY) < velocityThreshold { velocityY = 0.0 }
        if abs(velocityZ) < velocityThreshold { velocityZ = 0.0 }

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
            positionZ: positionZ,
            distance: distance
        )
        motionData.append(dataPoint)
    }

    // 0G誤差補正用の計算
    private func calculateZeroGOffset() {
        let sumX = initialAccelerationData.map { $0.0 }.reduce(0, +)
        let sumY = initialAccelerationData.map { $0.1 }.reduce(0, +)
        let sumZ = initialAccelerationData.map { $0.2 }.reduce(0, +)

        zeroGCalibrationX = sumX / Double(initialAccelerationData.count)
        zeroGCalibrationY = sumY / Double(initialAccelerationData.count)
        zeroGCalibrationZ = sumZ / Double(initialAccelerationData.count)

        isCalibrating = false

        zeroGCalibration = (x: zeroGCalibrationX, y: zeroGCalibrationY, z: zeroGCalibrationZ)
    }

    func exportCSV() -> URL? {
        let fileName = "motion_data.csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // swiftlint:disable:next line_length
        var csvText = "Duration(µs),Timestamp(µs),AccelerationX,AccelerationY,AccelerationZ,RotationRateX,RotationRateY,RotationRateZ,VelocityX,VelocityY,VelocityZ,PositionX,PositionY,PositionZ,Distance\n"

        for data in motionData {
            // swiftlint:disable:next line_length
            let line = "\(data.duration),\(data.timestamp),\(data.accelerationX),\(data.accelerationY),\(data.accelerationZ),\(data.rotationRateX),\(data.rotationRateY),\(data.rotationRateZ),\(data.velocityX),\(data.velocityY),\(data.velocityZ),\(data.positionX),\(data.positionY),\(data.positionZ),\(data.distance)\n"
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
