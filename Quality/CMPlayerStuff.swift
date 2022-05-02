//
//  CMPlayerStats.swift
//  Quality
//
//  Created by Vincent Neo on 19/4/22.
//

import Foundation
import OSLog
import Sweep

struct CMPlayerStats {
    let sampleRate: Double // Hz
    let bitDepth: Int
    let date: Date
    let priority: Int
}

class CMPlayerParser {
    static func parseMusicConsoleLogs(_ entries: [SimpleConsole]) -> [CMPlayerStats] {
        let kTimeDifferenceAcceptance = 5.0 // seconds
        var lastDate: Date?
        var sampleRate: Double?
        var bitDepth: Int?
        
        var stats = [CMPlayerStats]()
        
        for entry in entries {
            let date = entry.date
            let rawMessage = entry.message
            
            if let lastDate = lastDate, date.timeIntervalSince(lastDate) > kTimeDifferenceAcceptance {
                sampleRate = nil
                bitDepth = nil
            }
            
            if let subSampleRate = rawMessage.firstSubstring(between: "asbdSampleRate = ", and: " kHz") {
                let strSampleRate = String(subSampleRate)
                sampleRate = Double(strSampleRate)
            }
            
            if let subBitDepth = rawMessage.firstSubstring(between: "sdBitDepth = ", and: " bit") {
                let strBitDepth = String(subBitDepth)
                bitDepth = Int(strBitDepth)
            }
            else if rawMessage.contains("sdBitRate") { // lossy
                bitDepth = 16
            }
            
            if let sr = sampleRate,
               let bd = bitDepth {
                let stat = CMPlayerStats(sampleRate: sr * 1000, bitDepth: bd, date: date, priority: 1)
                stats.append(stat)
                sampleRate = nil
                bitDepth = nil
                print("detected stat \(stat)")
                break
            }
            
            lastDate = date
            
        }
        return stats
    }
    
    static func parseCoreAudioConsoleLogs(_ entries: [SimpleConsole]) -> [CMPlayerStats] {
        let kTimeDifferenceAcceptance = 5.0 // seconds
        var lastDate: Date?
        var sampleRate: Double?
        var bitDepth: Int?
        
        var stats = [CMPlayerStats]()
        
        for entry in entries {
            let date = entry.date
            let rawMessage = entry.message
            
            if let lastDate = lastDate, date.timeIntervalSince(lastDate) > kTimeDifferenceAcceptance {
                sampleRate = nil
                bitDepth = nil
            }
            
            if rawMessage.contains("Input format: ") {
                if let subSampleRate = rawMessage.firstSubstring(between: "ch, ", and: " Hz") {
                    let strSampleRate = String(subSampleRate)
                    sampleRate = Double(strSampleRate)
                }
                
                bitDepth = 24 // not important anymore, just putting as placeholder, at least until there's a way to set bit depth with Core Audio.
            }
            
            if let sr = sampleRate,
               let bd = bitDepth {
                let stat = CMPlayerStats(sampleRate: sr, bitDepth: bd, date: date, priority: 10)
                stats.append(stat)
                sampleRate = nil
                bitDepth = nil
                print("detected stat \(stat)")
                break
            }
            
            lastDate = date
            
        }
        return stats
    }
    
    static func parseCoreMediaConsoleLogs(_ entries: [SimpleConsole]) -> [CMPlayerStats] {
        let kTimeDifferenceAcceptance = 5.0 // seconds
        var lastDate: Date?
        var sampleRate: Double?
        let bitDepth = 24 // not important anymore, just putting as placeholder, at least until there's a way to set bit depth with Core Audio.
        
        var stats = [CMPlayerStats]()
        
        for entry in entries {
            let date = entry.date
            let rawMessage = entry.message
            
            if let lastDate = lastDate, date.timeIntervalSince(lastDate) > kTimeDifferenceAcceptance {
                sampleRate = nil
            }
            
            if rawMessage.contains("Creating AudioQueue") {
                if let subSampleRate = rawMessage.firstSubstring(between: "sampleRate:", and: .end) {
                    let strSampleRate = String(subSampleRate)
                    sampleRate = Double(strSampleRate)
                }
            }
            
            if let sr = sampleRate {
                let stat = CMPlayerStats(sampleRate: sr, bitDepth: bitDepth, date: date, priority: 10)
                stats.append(stat)
                sampleRate = nil
                print("detected stat \(stat)")
                break
            }
            
            lastDate = date
            
        }
        return stats
    }
}
