//
//  MotionData.swift
//  IOSTemplateApp
//
//  Created by 村石 拓海 on 2024/08/18.
//

struct MotionData {
    let duration: Int64   // 最初のフレームからの経過時間（マイクロ秒）
    let timestamp: Int64  // マイクロ秒単位のタイムスタンプ

    let accelerationX: Double
    let accelerationY: Double
    let accelerationZ: Double

    let rotationRateX: Double
    let rotationRateY: Double
    let rotationRateZ: Double

    let velocityX: Double
    let velocityY: Double
    let velocityZ: Double

    let positionX: Double
    let positionY: Double
    let positionZ: Double

    let distance: Double
}
