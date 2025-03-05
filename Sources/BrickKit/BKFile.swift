//
//  BKFile.swift
//  BrickKit
//
//  Created by iain on 17/02/2025.
//

import Foundation
import System

public struct BKFileLoaderOptions: Sendable {
    public let basePath: FilePath
    public let useHiRes: Bool
    
    public init(basePath: FilePath, useHiRes: Bool) {
        self.basePath = basePath
        self.useHiRes = useHiRes
    }
}

public class BKFile {
    public enum BKFileError: Error {
        case noFile(String)
        case unknownLineType(String)
        case badLine(String)
    }
    
    public class func load(file: String,
                           options: BKFileLoaderOptions,
                           asColor color: BKColorCode = 16) async throws -> BKPart {
        var lines = [BKFileLine]()
        
        guard let filePath = findFile(file, withOptions: options) else {
            throw BKFileError.noFile(file)
        }
        
        let url = URL(fileURLWithPath: filePath)
        for try await line in url.lines {
            if let fileLine = try await parseLine(line, withOptions: options) {
                switch fileLine {
                case .end:
                    return BKPart(color: color, filename: file, lines: lines)
                    
                default:
                    break
                }
                
                lines.append(fileLine)
            }
        }
        
        return BKPart(color: color, filename: file, lines: lines)
    }
    
    class func parseLine(_ line: String,
                         withOptions options: BKFileLoaderOptions) async throws -> BKFileLine? {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLine.isEmpty else {
            return nil
        }
        
        let type = trimmedLine.substring(to: trimmedLine.index(line.startIndex, offsetBy: 1))
        switch type {
        case "X":
            return .end
            
        case "0":
            let meta = BKMeta.from(string: trimmedLine)
            switch meta {
            case .ignore:
                return nil
                
            default:
                return .meta(meta)
            }
            
        case "1":
            let subpart = BKSubpart(from: trimmedLine)
            
            guard let subpart else {
                throw BKFileError.badLine(line)
            }
            
            let part = try await BKFile.load(file: subpart.filename,
                                             options: options,
                                             asColor: subpart.color)
            return .subpart(subpart, part)
            
        case "2":
            guard let l = BKLine(from: trimmedLine) else {
                throw BKFileError.badLine(line)
            }
            
            return .line(l)
            
        case "3":
            guard let l = BKTriangle(from: trimmedLine) else {
                throw BKFileError.badLine(line)
            }
            
            return .triangle(l)
            
        case "4":
            guard let l = BKRectangle(from: trimmedLine) else {
                throw BKFileError.badLine(line)
            }
            
            return .rectangle(l)
            
        case "5":
            guard let l = BKOptionalLine(from: trimmedLine) else {
                throw BKFileError.badLine(line)
            }
            
            return .optionalLine(l)
            
        default:
            throw BKFileError.unknownLineType(type)
        }
    }
}

private extension BKFile {
    static func findFile(_ filename: String,
                         withOptions options: BKFileLoaderOptions) -> String? {
        let filePath = FilePath(filename)
        if filePath.isAbsolute {
            return filePath.string
        }
        
        var knownFolders: [String] = ["parts", "models"]
        if options.useHiRes {
            knownFolders.append("p/48")
        }
        knownFolders.append("p")
        
        for folder in knownFolders {
            let checkPath = options.basePath.appending(folder).appending(filename)
            if FileManager.default.fileExists(atPath: checkPath.string) {
                return checkPath.string
            }
        }
        
        return nil
    }
}
