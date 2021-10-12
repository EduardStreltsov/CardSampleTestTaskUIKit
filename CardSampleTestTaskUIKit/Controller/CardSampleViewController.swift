import UIKit

class CardSampleViewController: UIViewController {
	
	@IBOutlet weak var nameOnCard: UITextField!
	@IBOutlet weak var cardNumber1: UITextField!
	@IBOutlet weak var cardNumber2: UITextField!
	@IBOutlet weak var cardNumber3: UITextField!
	@IBOutlet weak var cardNumber4: UITextField!
	@IBOutlet weak var expireDate: UITextField!
	@IBOutlet weak var securityCode: UITextField!
	
	@IBOutlet weak var addCardButton: UIButton!
	
	private var card = Card()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Text Field Delegates
		cardNumber1.delegate = self
		cardNumber2.delegate = self
		cardNumber3.delegate = self
		cardNumber4.delegate = self
		expireDate.delegate = self
		securityCode.delegate = self
		
		cardNumber1.addTarget(self, action: #selector(CardSampleViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
		cardNumber2.addTarget(self, action: #selector(CardSampleViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
		cardNumber3.addTarget(self, action: #selector(CardSampleViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
		cardNumber4.addTarget(self, action: #selector(CardSampleViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
		expireDate.addTarget(self, action: #selector(CardSampleViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
		securityCode.addTarget(self, action: #selector(CardSampleViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
		
		let label = UILabel()
		label.textColor = UIColor.white
		label.text = "CardSample"
		label.font = .boldSystemFont(ofSize: 20)
		navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: label)
		
		addCardButton.layer.cornerRadius = 4
		overrideUserInterfaceStyle = .light
	}
	
	@IBAction func addCardButtonPushed() {
		
		var validationResult = validateInputs()
		
		if validationResult.0 == true {
			
			updateModelFromView()
			
			validationResult.1 = "Success"
			validationResult.2 = getJSON()
		}
		
		presentAlert(withTitle: validationResult.1, message: validationResult.2, actions: [
			"OK": .default], completionHandler: { (action) in
			
		})
	}
	
	func updateModelFromView() {
		card.nameOnCard = nameOnCard.text
		card.cardNumber = getCombinedCardNumber()
		card.expireDate = getUnwrappedTextFieldValue(expireDate)
		card.securityCode = getUnwrappedTextFieldValue(securityCode)
	}
	
}

// MARK - Processing textField inputs
extension CardSampleViewController: UITextFieldDelegate {
	
	@objc func textFieldDidChange(_ textField: UITextField) {
		let inputCount = getTextFieldInputCount(textField)
		
		if textField == cardNumber1 || textField == cardNumber2 ||
			   textField == cardNumber3 || textField == cardNumber4 {
			changeTextFieldLessThan0(textField)
			changeTextFieldMoreThan4(textField)
		} else if textField == expireDate, inputCount >= 5 {
			securityCode.becomeFirstResponder()
		} else if textField == securityCode, inputCount >= 3 {
			textField.resignFirstResponder()
		}
	}
	
	public func textField(_ textField: UITextField,
	                      shouldChangeCharactersIn range: NSRange,
	                      replacementString string: String) -> Bool {
		
		let currentText = getUnwrappedTextFieldValue(textField)
		let currentLength = currentText.count + string.count - range.length
		
		if textField == cardNumber1 || textField == cardNumber2 ||
			   textField == cardNumber3 || textField == cardNumber4 {
			let charLimit = 4
			let newLength = charLimit - currentLength
			if newLength < 0 {
				changeTextFieldMoreThan4(textField)
				return false
			}
			
		} else if textField == expireDate {
			guard let stringRange = Range(range, in: currentText) else { return false }
			let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
			processSlashInExpireDateInput(currentText, updatedText)
			
			let charLimit = 5
			let newLength = getUnwrappedTextFieldValue(expireDate).count
			if newLength >= charLimit {
				securityCode.becomeFirstResponder()
			}
			return false
			
		} else if textField == securityCode {
			let charLimit = 3
			let newLength = charLimit - currentLength
			if newLength < 0 {
				textField.resignFirstResponder()
				return false
			}
		}
		
		return true
	}
	
	//MARK: Helper Methods
	func changeTextFieldMoreThan4(_ textField: UITextField) {
		let text = textField.text
		if text?.count == 4 {
			switch textField {
			case cardNumber1:
				cardNumber2.becomeFirstResponder()
			case cardNumber2:
				cardNumber3.becomeFirstResponder()
			case cardNumber3:
				cardNumber4.becomeFirstResponder()
			case cardNumber4:
				expireDate.becomeFirstResponder()
			default:
				break
			}
		}
	}
	
	func changeTextFieldLessThan0(_ textField: UITextField) {
		if getTextFieldInputCount(textField) <= 0 {
			switch textField {
			case cardNumber1:
				cardNumber1.becomeFirstResponder()
			case cardNumber2:
				cardNumber1.becomeFirstResponder()
			case cardNumber3:
				cardNumber2.becomeFirstResponder()
			case cardNumber4:
				cardNumber3.becomeFirstResponder()
			default:
				break
			}
		}
	}
	
	private func processSlashInExpireDateInput(_ currentText: String, _ updatedText: String) {
		var newText = updatedText.filter { "0123456789".contains($0) }
		let isDeleting = currentText.count > newText.count
		if isDeleting && String(currentText.suffix(1)) == "/" {
			newText = String(newText.prefix(1))
		}
		if newText.count >= 2 {
			newText = "\(newText.prefix(2))/\(newText.substring(fromIndex: 2))"
		}
		expireDate.text = String(newText.prefix(5))
	}
	
	func getUnwrappedTextFieldValue(_ textField: UITextField) -> String {
		textField.text ?? ""
	}
	
	func getTextFieldInputCount(_ textField: UITextField) -> Int {
		(textField.text ?? "").count
	}
	
	func getCombinedCardNumber() -> String {
		getUnwrappedTextFieldValue(cardNumber1) +
			getUnwrappedTextFieldValue(cardNumber2) +
			getUnwrappedTextFieldValue(cardNumber3) +
			getUnwrappedTextFieldValue(cardNumber4)
	}
}

// MARK - Validation
extension CardSampleViewController {
	
	func validateInputs() -> (Bool, String, String) {
		
		var validationResult: (Bool, String, String) = (isValid: false,
			title: "",
			message: "")
		
		var errorMessage = ""
		if getCombinedCardNumber().count != 16 {
			errorMessage = "Card number must be 16 digits\n"
		}
		if !getCombinedCardNumber().isNumeric {
			errorMessage = errorMessage + "Card number must contain numbers only\n"
		}
		
		let pattern = "^(0[1-9]|1[0-2])/(\\d{2})$"
		let result = getUnwrappedTextFieldValue(expireDate).range(of: pattern, options: .regularExpression)
		if result == nil {
			errorMessage = errorMessage + "Expiration date is incorrect\n"
		}
		
		if getTextFieldInputCount(securityCode) != 3 {
			errorMessage = errorMessage + "Security code must be 3 digits\n"
		}
		if !getUnwrappedTextFieldValue(securityCode).isNumeric {
			errorMessage = errorMessage + "Security code must contain numbers only\n"
		}
		
		let isValid = errorMessage.count == 0
		validationResult.0 = isValid
		
		if !isValid {
			validationResult.1 = "Validation Error"
			validationResult.2 = errorMessage
		}
		
		return validationResult
	}
}

// MARK - Alert
extension CardSampleViewController {
	
	func presentAlert(withTitle title: String, message: String,
	                  actions: [String: UIAlertAction.Style],
	                  completionHandler: ((UIAlertAction) -> ())? = nil) {
		
		let alertController = UIAlertController(title: title,
			message: message, preferredStyle: .alert)
		
		for action in actions {
			let action = UIAlertAction(title: action.key, style: action.value) { action in
				if completionHandler != nil {
					completionHandler!(action)
				}
			}
			alertController.addAction(action)
		}
		
		present(alertController, animated: true, completion: nil)
	}
}

// MARK - JSON
extension CardSampleViewController {
	
	private func getJSON() -> String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		do {
			let data = try encoder.encode(card)
			var result = String(data: data, encoding: .utf8) ?? ""
			result = result.replacingOccurrences(of: "\\", with: "")
			return result
		} catch {
			print("Encoding error: \(error.localizedDescription)")
		}
		return ""
	}
}
