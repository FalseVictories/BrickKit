//
//  File.swift
//  BrickKit
//
//  Created by iain on 17/02/2025.
//

import Foundation

public class BKFile {
    public enum BKFileError: Error {
        case unknownLineType(String)
    }
    
    public class func load(file: String,
                           from basePath: String,
                           asColour colour: Int32 = 16) async throws -> BKPart {
        var lines = [BKFileLine]()
        
        let url = URL(fileURLWithPath: basePath + "/Contents/Resources/" + file)
        for try await line in url.lines {
            if let fileLine = try await parseLine(line, from: basePath) {
                lines.append(fileLine)
            }
        }
        
        return BKPart(colour: colour, filename: file, lines: lines)
    }
    
    class func parseLine(_ line: String, from basePath: String) async throws -> BKFileLine? {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLine.isEmpty else {
            return nil
        }
        
        let type = trimmedLine.substring(to: trimmedLine.index(line.startIndex, offsetBy: 1))
        switch type {
        case "0":
            let meta = BKMeta.from(string: trimmedLine)
            return meta == .ignore ? nil : .meta(meta)
            
        case "1":
            let subpart = BKSubpart(from: trimmedLine)
            let part = try await BKFile.load(file: subpart.filename,
                                             from: basePath,
                                             asColour: subpart.colour)
            return .subpart(subpart, part)
            
        case "2":
            let l = BKLine(from: trimmedLine)
            return .line(l)
            
        case "3":
            let l = BKTriangle(from: trimmedLine)
            return .triangle(l)
            
        case "4":
            let l = BKRectangle(from: trimmedLine)
            return .rectangle(l)
            
        case "5":
            let l = BKOptionalLine(from: trimmedLine)
            return .optionalLine(l)
            
        default:
            throw BKFileError.unknownLineType(type)
        }
    }
}
