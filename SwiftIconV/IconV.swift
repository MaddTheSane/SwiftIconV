//
//  IconV.swift
//  SwiftIconV
//
//  Created by C.W. Betts on 12/14/15.
//  Copyright © 2015 C.W. Betts. All rights reserved.
//

import Swift
import Darwin.POSIX.iconv

public class IconV {
	private static var encodings = [[String]]()
	private var intIconv: iconv_t
	public static func availableEncodings() -> [[String]] {
		if IconV.encodings.count == 0 {
			var encodingsPtr: UnsafeMutablePointer<[[String]]> = nil
			
			func hackyGetPtr(arr: UnsafeMutablePointer<[[String]]>) {
				encodingsPtr = arr
			}
			
			hackyGetPtr(&IconV.encodings)
			
			iconvlist({ (namescount, names, data) -> Int32 in
				var encNames = [String]()
				for i in 0..<Int(namescount) {
					guard let strName = String.fromCString(names[i]) else {
						return -1
					}
					encNames.append(strName)
				}
				let encodings = UnsafeMutablePointer<[[String]]>(data)
				encodings.memory.append(encNames)
				
				return 0
				}, encodingsPtr)
			
		}
		
		return encodings
	}
	
	public init?(fromEncoding: String, toEncoding: String = "UTF-8") {
		intIconv = iconv_open(toEncoding, fromEncoding)
		if intIconv == nil {
			return nil
		}
	}
	
	deinit {
		if intIconv != nil {
			iconv_close(intIconv)
		}
	}
}
