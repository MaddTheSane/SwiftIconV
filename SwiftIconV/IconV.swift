//
//  IconV.swift
//  SwiftIconV
//
//  Created by C.W. Betts on 12/14/15.
//  Copyright © 2015 C.W. Betts. All rights reserved.
//

import Swift
#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
	import Darwin.POSIX.iconv
#elseif os(Linux)
	import Glibc
	import SwiftGlibc.POSIX.iconv
	import SwiftGlibc.C.errno
#endif

/// Swift wrapper around the iconv library functions
final public class IconV: CustomStringConvertible {
	fileprivate var intIconv: iconv_t?
	
	/// The string encoding that `convert` converts to
	public let toEncoding: String
	
	/// The string encoding that `convert` converts from
	public let fromEncoding: String
	
	public enum EncodingErrors: Error {
		/// The buffer is too small
		case bufferTooSmall
		/// Conversion function was passed `nil`
		case passedNull
		/// The encoding name isn't recognized by libiconv
		case invalidEncodingName
		/// Unable to convert from one encoding to another
		case invalidMultibyteSequence
		/// Buffer ends between a multibyte sequence
		case incompleteMultibyteSequence
		/// `errno` was an unknown value
		case unknownError(Int32)
	}
	
	/// Initialize an IconV class that can convert one encoding to another
	/// - parameter fromEncoding: The name of the encoding to convert from
	/// - parameter toEncoding: The name of the encoding to convert to. Default is `"UTF-8"`
	/// - returns: an IconV class, or `nil` if an encoding name is invalid.
	public init?(fromEncoding: String, toEncoding: String = "UTF-8") {
		guard !fromEncoding.contains(" "), !toEncoding.contains(" ") else {
			return nil
		}
		
		self.fromEncoding = fromEncoding
		self.toEncoding = toEncoding
		intIconv = iconv_open(toEncoding, fromEncoding)
		if intIconv == nil {
			return nil
		}
	}
	
	/// Converts a pointer to a byte array from the encoding `fromEncoding` to `toEncoding`
	/// - parameter outBufferMax: the maximum size of the buffer to use. Default is `1024`. 
	/// If passed `Int.max`, will attempt to convert the whole buffer without throwing `EncodingErrors.BufferTooSmall`.
	/// - parameter inBuf: A pointer to the buffer of bytes to convert. On return, will point to
	/// where the encoding ended.
	/// - parameter inBytes: the number of bytes in `inBuf`.
	/// - parameter outBuf: The converted bytes, appending the array.
	/// - returns: the number of non-reversible conversions performed.
	/// - throws: an `EncodingErrors` on failure, including the buffer size request being too small.
	///
	/// If `outBufferMax` isn't large enough to store the converted characters,
	/// `EncodingErrors.BufferTooSmall` is thrown.<br>
	/// Even if the function throws, the converted bytes are added to `outBuf`.
	/// It is recommended to pass a copy of the pointer of the buffer and its length, as they are
	/// incremented internally.
	@discardableResult
	public func convert(inBuffer inBuf: inout UnsafeMutablePointer<CChar>?, inBytesCount inBytes: inout Int, outBuffer outBuf: inout [CChar], outBufferMax: Int = 1024) throws -> Int {
		guard inBuf != nil && inBytes != 0 else {
			throw EncodingErrors.passedNull
		}
		if outBufferMax == Int.max {
			var icStatus = 0
			repeat {
				do {
					icStatus += try convert(inBuffer: &inBuf, inBytesCount: &inBytes, outBuffer: &outBuf, outBufferMax: 2048)
				} catch let error as EncodingErrors {
					switch error {
					case .bufferTooSmall:
						continue
						
					default:
						throw error
					}
				}
			} while inBytes != 0
			return icStatus
		}
		let tmpBuf = UnsafeMutablePointer<Int8>.allocate(capacity: outBufferMax)
		defer {
			tmpBuf.deallocate(capacity: outBufferMax)
		}
		var tmpBufSize = outBufferMax
		var passedBufPtr: UnsafeMutablePointer<Int8>? = tmpBuf
		let iconvStatus = iconv(intIconv, &inBuf, &inBytes, &passedBufPtr, &tmpBufSize)
		
		let toAppend = UnsafeMutableBufferPointer(start: tmpBuf, count: outBufferMax - tmpBufSize)

		outBuf.append(contentsOf: toAppend)
		
		//failed
		if iconvStatus == -1 {
			switch errno {
			case EILSEQ:
				throw EncodingErrors.invalidMultibyteSequence
				
			case E2BIG:
				throw EncodingErrors.bufferTooSmall
				
			case EINVAL:
				throw EncodingErrors.incompleteMultibyteSequence
				
			default:
				throw EncodingErrors.unknownError(errno)
			}
		}
		
		return iconvStatus
	}

	deinit {
		if intIconv != nil {
			iconv_close(intIconv)
		}
	}
	
	/// Resets the encoder to its default state
	public func reset() {
		iconv(intIconv, nil, nil, nil, nil)
	}
	
	public var description: String {
		return "From encoding: \"\(fromEncoding)\", to encoding \"\(toEncoding)\""
	}
}

#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
	/// OS X-specific additions that may not be present on Linux.
	extension IconV {
		fileprivate static var encodings = [[String]]()
		
		/// A list of all the available encodings.
		/// They are grouped so that names that reference the same encoding are in the same array
		/// within the returned array.
		public static func availableEncodings() -> [[String]] {
			if IconV.encodings.count == 0 {
				iconvlist({ (namescount, names, data) -> Int32 in
					var encNames = [String]()
					encNames.reserveCapacity(Int(namescount))
					for i in 0..<Int(namescount) {
						guard let strName = String(validatingUTF8: names![i]!) else {
							return -1
						}
						encNames.append(strName)
					}
					let encodings = data!.assumingMemoryBound(to: [[String]].self)
					encodings.pointee.append(encNames)
					
					return 0
					}, withUnsafeMutablePointer(to: &IconV.encodings, {
						return UnsafeMutableRawPointer($0)
					}))
			}
			
			return encodings
		}
		
		@available(*, deprecated, renamed: "isTrivial")
		public var trivial: Bool {
			return isTrivial;
		}
		
		/// Is `true` if the encoding conversion is trivial.
		public var isTrivial: Bool {
			var toRet: Int32 = 0
			iconvctl(intIconv, ICONV_TRIVIALP, &toRet)
			return toRet == 1
		}
		
		public var transliterates: Bool {
			get {
				var toRet: Int32 = 0
				iconvctl(intIconv, ICONV_GET_TRANSLITERATE, &toRet)
				return toRet == 1
			}
			set {
				var toRet: Int32
				if newValue {
					toRet = 1
				} else {
					toRet = 0
				}
				iconvctl(intIconv, ICONV_SET_TRANSLITERATE, &toRet)
			}
		}
		
		/// "illegal sequence discard and continue"
		public var discardIllegalSequence: Bool {
			get {
				var toRet: Int32 = 0
				iconvctl(intIconv, ICONV_GET_DISCARD_ILSEQ, &toRet)
				return toRet == 1
			}
			set {
				var toRet:Int32
				if newValue {
					toRet = 1
				} else {
					toRet = 0
				}
				iconvctl(intIconv, ICONV_SET_DISCARD_ILSEQ, &toRet)
			}
		}
		
		public func setHooks(_ hooks: iconv_hooks) {
			var tmpHooks = hooks
			iconvctl(intIconv, ICONV_SET_HOOKS, &tmpHooks)
		}
		
		public func setFallbacks(_ fallbacks: iconv_fallbacks) {
			var tmpHooks = fallbacks
			iconvctl(intIconv, ICONV_SET_FALLBACKS, &tmpHooks)
		}
		
		/// Canonicalize an encoding name.
		/// The result is either a canonical encoding name, or `name` itself.
		public class func canonicalizeEncoding(_ name: String) -> String {
			guard let retName = iconv_canonicalize(name) else {
				return name
			}
			return String(cString: retName)
		}
	}
#endif

extension IconV.EncodingErrors: Equatable {
	
}

public func ==(lhs: IconV.EncodingErrors, rhs: IconV.EncodingErrors) -> Bool {
	switch (lhs, rhs) {
	case (.unknownError(let lhsErr), .unknownError(let rhsErr)):
		return lhsErr == rhsErr
		
	case (.bufferTooSmall, .bufferTooSmall):
		return true
		
	case (.passedNull, .passedNull):
		return true

	case (.invalidEncodingName, .invalidEncodingName):
		return true

	case (.invalidMultibyteSequence, .invalidMultibyteSequence):
		return true

	case (.incompleteMultibyteSequence, .incompleteMultibyteSequence):
		return true

	default:
		return false
	}
}

extension IconV {
	/// Converts a C string in the specified encoding to a Swift String.
	/// - parameter cstr: pointer to the C string to convert
	/// - parameter length: the length, in bytes, of `cstr`. If `nil`, uses `strlen` to get the length.
	/// Default value is `nil`.
	/// - parameter encName: the name of the encoding that the C-string is in.
	/// - throws: an `EncodingErrors` on failure.
	///
	/// Internally, this tells libiconv to convert the string to UTF-32,
	/// then initializes a Swift String from the result.
	public class func convertCString(_ cstr: UnsafePointer<Int8>?, length: Int? = nil, fromEncodingNamed encName: String) throws -> String {
		if cstr == nil {
			throw EncodingErrors.passedNull
		}
		
		//Use "UTF-32LE" so we don't have to worry about the BOM
		guard let converter = IconV(fromEncoding: encName, toEncoding: "UTF-32LE") else {
			throw EncodingErrors.invalidEncodingName
		}
		
		let strLen = length ?? Int(strlen(cstr))
		var tmpStrLen = strLen
		var utf8Str = [Int8]()
		utf8Str.reserveCapacity(strLen * 4)
		var cStrPtr = UnsafeMutablePointer<Int8>(mutating: cstr)
		try converter.convert(inBuffer: &cStrPtr, inBytesCount: &tmpStrLen, outBuffer: &utf8Str, outBufferMax: Int.max)
		let str32Len = utf8Str.count / 4
		let preScalar: [UnicodeScalar] = try {
			// Nasty, dirty hack to convert to [UInt32]
			let badPtr = UnsafeMutablePointer<Int8>(mutating: utf8Str)
			return try badPtr.withMemoryRebound(to: UInt32.self, capacity: str32Len) { goodPtr in
				let betterPtr = UnsafeBufferPointer(start: goodPtr, count: str32Len)

				// Make sure the UTF-32 number is in the processor's endian.
				return try betterPtr.map({ prescale in
					guard let scaler = UnicodeScalar(prescale.littleEndian) else {
						throw EncodingErrors.invalidMultibyteSequence
					}
					return scaler
				})
			}
		}()
		var scalar = String.UnicodeScalarView()
		scalar.append(contentsOf: preScalar)
		
		return String(scalar)
	}
}
