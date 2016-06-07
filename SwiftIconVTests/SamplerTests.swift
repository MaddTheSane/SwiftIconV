//
//  SamplerTests.swift
//  SwiftIconV
//
//  Created by C.W. Betts on 6/7/16.
//  Copyright © 2016 C.W. Betts. All rights reserved.
//

import Cocoa
import XCTest

@objc class SamplerTests: XCTestCase {
	let bundle: NSBundle = NSBundle(forClass: SamplerTests.self)

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testOdysseus() {
		if let aURL = bundle.URLForResource("Odysseus Elytis", withExtension: "txt"),
			data = NSData(contentsOfURL: aURL) {
			
		} else {
			XCTFail("Could not read file")
		}
    }

    func testHorseman() {
		
    }

}
