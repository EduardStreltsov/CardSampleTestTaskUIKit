import UIKit

extension String {
	private func index(from: Int) -> Index {
		self.index(startIndex, offsetBy: from)
	}
	
	func substring(fromIndex: Int) -> String {
		if max(count - 1, 0) < fromIndex {
			return ""
		}
		let fromIndex = index(from: fromIndex)
		return String(self[fromIndex...])
	}
	
	func substring(with r: Range<Int>) -> String {
		let startIndex = index(from: r.lowerBound)
		let endIndex = index(from: r.upperBound)
		return String(self[startIndex..<endIndex])
	}
	
	var isNumeric: Bool {
		!isEmpty && allSatisfy { $0.isNumber }
	}
}