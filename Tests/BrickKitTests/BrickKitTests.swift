import XCTest
import SceneKit

@testable import BrickKit

final class BKFileParsingTests: XCTestCase {
    func testParseMetaComment() {
        let testLine = "0 A Comment"
        
        let meta = BKMeta.from(string: testLine)
        
        XCTAssertEqual(meta, .ignore)
    }
    
    func testParseBadBFC() {
        let testLine = "0 BFC"
        
        let bfc = BKMeta.from(string: testLine)
        XCTAssert(bfc == .ignore)
    }
    
    func testParseBFCCommands() {
        // This isn't really a valid line, because it has contradictory pairs
        // But the parser doesn't handle that ATM
        let testLine = "0 BFC CERTIFY NOCERTIFY CCW CW CLIP NOCLIP INVERTNEXT"
        let bfc = BKMeta.from(string: testLine)
        if case let .bfc(commands) = bfc {
            XCTAssertEqual(commands.count, 7)
            XCTAssertEqual(commands[0], .certify)
            XCTAssertEqual(commands[1], .nocertify)
            XCTAssertEqual(commands[2], .ccw)
            XCTAssertEqual(commands[3], .cw)
            XCTAssertEqual(commands[4], .clip)
            XCTAssertEqual(commands[5], .noclip)
            XCTAssertEqual(commands[6], .invertnext)
        }
    }
    
    func testParsePart() {
        let testLine = "1 16 0 0 0 1 0 0 0 1 0 0 0 1 filename.dat"
        
        let subpart = BKSubpart(from: testLine)
        XCTAssertNotNil(subpart)
        
        if let subpart {
            XCTAssertEqual(subpart.color, 16)
            XCTAssertEqual(subpart.filename, "filename.dat")
            
            let transform = SCNMatrix4(m11: 1, m12: 0, m13: 0, m14: 0,
                                       m21: 0, m22: 1, m23: 0, m24: 0,
                                       m31: 0, m32: 0, m33: 1, m34: 0,
                                       m41: 0, m42: 0, m43: 0, m44: 1)
            XCTAssertTrue(SCNMatrix4EqualToMatrix4(transform, subpart.transform))
        }
    }
    
    func testParseLine() {
        let testLine = "2 16 0 0 0 1 1 1"
        
        let line = BKLine(from: testLine)
        XCTAssertNotNil(line)
        
        if let line {
            XCTAssertEqual(line.color, 16)
            
            XCTAssertEqual(line.v1.x, 0)
            XCTAssertEqual(line.v1.y, 0)
            XCTAssertEqual(line.v1.z, 0)
            
            XCTAssertEqual(line.v2.x, 1)
            XCTAssertEqual(line.v2.y, 1)
            XCTAssertEqual(line.v2.z, 1)
        }
    }
    
    func testParseTriangle() {
        let testLine = "3 16 0 0 0 1 1 1 2 2 2"
        
        let triangle = BKTriangle(from: testLine)
        XCTAssert(triangle != nil)
        
        if let triangle {
            XCTAssertEqual(triangle.color, 16)
            
            XCTAssertEqual(triangle.v1.x, 0)
            XCTAssertEqual(triangle.v1.y, 0)
            XCTAssertEqual(triangle.v1.z, 0)
            
            XCTAssertEqual(triangle.v2.x, 1)
            XCTAssertEqual(triangle.v2.y, 1)
            XCTAssertEqual(triangle.v2.z, 1)
            
            XCTAssertEqual(triangle.v3.x, 2)
            XCTAssertEqual(triangle.v3.y, 2)
            XCTAssertEqual(triangle.v3.z, 2)
        }
    }
    
    func testParseRectangle() {
        let testLine = "3 16 0 0 0 1 1 1 2 2 2 3 3 3"
        
        let rectangle = BKRectangle(from: testLine)
        XCTAssert(rectangle != nil)
        
        if let rectangle {
            XCTAssertEqual(rectangle.color, 16)
            
            XCTAssertEqual(rectangle.v1.x, 0)
            XCTAssertEqual(rectangle.v1.y, 0)
            XCTAssertEqual(rectangle.v1.z, 0)
            
            XCTAssertEqual(rectangle.v2.x, 1)
            XCTAssertEqual(rectangle.v2.y, 1)
            XCTAssertEqual(rectangle.v2.z, 1)
            
            XCTAssertEqual(rectangle.v3.x, 2)
            XCTAssertEqual(rectangle.v3.y, 2)
            XCTAssertEqual(rectangle.v3.z, 2)
            
            XCTAssertEqual(rectangle.v4.x, 3)
            XCTAssertEqual(rectangle.v4.y, 3)
            XCTAssertEqual(rectangle.v4.z, 3)
        }
    }
}
