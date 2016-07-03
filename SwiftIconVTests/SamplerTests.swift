//
//  SamplerTests.swift
//  SwiftIconV
//
//  Created by C.W. Betts on 6/7/16.
//  Copyright © 2016 C.W. Betts. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftIconV

class SamplerTests: XCTestCase {
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
		guard let aURL = bundle.URLForResource("Odysseus Elytis", withExtension: "txt") else {
			XCTFail("Could not find file")
			return
		}
		
		guard let data = NSData(contentsOfURL: aURL) else {
			XCTFail("Could not read file")
			return
		}
		
		do {
			let transStr = try IconV.convertCString(UnsafePointer<Int8>(data.bytes), length: data.length, fromEncodingNamed: "ISO8859-7")
			let nativeStr = "Τη γλώσσα μου έδωσαν ελληνική\nτο σπίτι φτωχικό στις αμμουδιές του Ομήρου.\nΜονάχη έγνοια η γλώσσα μου στις αμμουδιές του Ομήρου.\nαπό το Άξιον Εστί\nτου Οδυσσέα Ελύτη\n"
			XCTAssertEqual(transStr, nativeStr)
		} catch {
			XCTFail("Conversion error \(error)")
		}
	}
	
	func testHorseman() {
		guard let aURL = bundle.URLForResource("Bronze Horseman", withExtension: "txt") else {
			XCTFail("Could not find file")
			return
		}
		
		guard let data = NSData(contentsOfURL: aURL) else {
			XCTFail("Could not read file")
			return
		}
		
		do {
			let transStr = try IconV.convertCString(UnsafePointer<Int8>(data.bytes), length: data.length, fromEncodingNamed: "ISO8859-5")
			let nativeStr = "На берегу пустынных волн\nСтоял он, дум великих полн,\nИ вдаль глядел. Пред ним широко\nРека неслася; бедный чёлн\nПо ней стремился одиноко.\nПо мшистым, топким берегам\nЧернели избы здесь и там,\nПриют убогого чухонца;\nИ лес, неведомый лучам\nВ тумане спрятанного солнца,\nКругом шумел.\n"
			XCTAssertEqual(transStr, nativeStr)
		} catch {
			XCTFail("Conversion error \(error)")
		}
	}
	
	func testHiragana() {
		guard let aURL = bundle.URLForResource("Japanese Hiragana", withExtension: "txt") else {
			XCTFail("Could not find file")
			return
		}
		
		guard let data = NSData(contentsOfURL: aURL) else {
			XCTFail("Could not read file")
			return
		}
		
		do {
			let transStr = try IconV.convertCString(UnsafePointer<Int8>(data.bytes), length: data.length, fromEncodingNamed: "SHIFT-JIS")
			let nativeStr = "いろはにほへど　ちりぬるを\nわがよたれぞ　つねならむ\nうゐのおくやま　けふこえて\nあさきゆめみじ　ゑひもせず\n"
			XCTAssertEqual(transStr, nativeStr)
		} catch {
			XCTFail("Conversion error \(error)")
		}
	}
	
	func testWolfram() {
		guard let aURL = bundle.URLForResource("Wolfram von Eschenbach", withExtension: "txt") else {
			XCTFail("Could not find file")
			return
		}
		
		guard let data = NSData(contentsOfURL: aURL) else {
			XCTFail("Could not read file")
			return
		}
		
		do {
			let transStr = try IconV.convertCString(UnsafePointer<Int8>(data.bytes), length: data.length, fromEncodingNamed: "LATIN1")
			let nativeStr = "Si\u{302}ne kla\u{302}wen durh die wolken sint geslagen,\ner sti\u{302}get u\u{302}f mit gro\u{302}zer kraft,\nich sih in gra\u{302}wen ta\u{308}geli\u{302}ch als er wil tagen,\nden tac, der im geselleschaft\nerwenden wil, dem werden man,\nden ich mit sorgen i\u{302}n verliez.\nich bringe in hinnen, ob ich kan.\nsi\u{302}n vil manegiu tugent michz leisten hiez.\n"
			XCTAssertEqual(transStr, nativeStr)
		} catch {
			XCTFail("Conversion error \(error)")
		}
	}
}
