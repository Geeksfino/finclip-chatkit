//
//  DeviceDetection.swift
//  MyPal
//
//  Utility for detecting iOS simulator vs physical device
//

import UIKit

enum DeviceType {
  case simulator
  case physicalDevice
}

struct DeviceDetection {
  /// Check if running on iOS Simulator
  static var isSimulator: Bool {
    #if targetEnvironment(simulator)
    return true
    #else
    return false
    #endif
  }
  
  /// Get device type (simulator or physical device)
  static var deviceType: DeviceType {
    isSimulator ? .simulator : .physicalDevice
  }
}

