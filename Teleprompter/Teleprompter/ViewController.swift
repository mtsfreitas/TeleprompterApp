//
//  ViewController.swift
//  Teleprompter
//
//  Created by Matheus Freitas Martins on 26/05/23.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var speedSlider: UISlider!
    
    @IBOutlet weak var increaseFontButton: UIButton!
    @IBOutlet weak var decreaseFontButton: UIButton!
    var scrollTimer: Timer?
    
    var isScrolling = false
    var longPressRecognizer: UILongPressGestureRecognizer?
    var isBackgroundBlack = false
    var hasReachedEnd = false

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        speedSlider.value = 0.5
        
        textView.addInteraction(UIContextMenuInteraction(delegate: self))
        
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        startButton.addGestureRecognizer(longPressRecognizer!)
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
            let range = NSRange(location: 0, length: attributedText.length)
            
            attributedText.enumerateAttribute(.foregroundColor, in: range, options: []) { (value, range, stop) in
                if let color = value as? UIColor {
                    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                    let isBlack = red == 0 && green == 0 && blue == 0
                    let isWhite = red == 1 && green == 1 && blue == 1
                    
                    if isBlack {
                        attributedText.addAttribute(.foregroundColor, value: UIColor.white, range: range)
                    } else if isWhite {
                        attributedText.addAttribute(.foregroundColor, value: UIColor.black, range: range)
                    }
                }
            }
            textView.attributedText = attributedText
            
            // Altera o background dependendo da situação
            if isBackgroundBlack {
                // Restaurar o background branco
                textView.backgroundColor = .white
                isBackgroundBlack = false
            } else {
                // Alterar para o background preto
                textView.backgroundColor = .black
                isBackgroundBlack = true
            }
        }
    }
    
    func chooseColor(completion: @escaping (UIColor) -> Void) {
        let selectedRange = textView.selectedRange
        let currentAttributes = textView.attributedText.attributes(at: selectedRange.location, effectiveRange: nil)
        _ = currentAttributes[.foregroundColor] as? UIColor
        
        let alertController = UIAlertController(title: "Escolha uma cor", message: nil, preferredStyle: .actionSheet)
        
        let colors: [UIColor] = [.black, .red, .blue, .green, .orange, .purple, .gray, .brown]
        let colorNames: [String] = ["Preto", "Vermelho", "Azul", "Verde", "Laranja", "Roxo", "Cinza", "Marrom"]
        
        for (index, color) in colors.enumerated() {
            let action = UIAlertAction(title: colorNames[index], style: .default) { _ in
                completion(color)
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    @objc func toggleBold() {
        let selectedRange = textView.selectedRange
        guard selectedRange.length > 0, selectedRange.location < textView.attributedText.length else { return }
        
        let currentAttributes = textView.attributedText.attributes(at: selectedRange.location, effectiveRange: nil)
        let currentFont = currentAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 14.0)
        
        let isBold = currentFont.fontDescriptor.symbolicTraits.contains(.traitBold)
        let newFont = isBold ? UIFont.systemFont(ofSize: currentFont.pointSize) : UIFont.boldSystemFont(ofSize: currentFont.pointSize)
        
        let newAttributes: [NSAttributedString.Key: Any] = [.font: newFont]
        let newText = NSMutableAttributedString(attributedString: textView.attributedText)
        newText.addAttributes(newAttributes, range: selectedRange)
        
        textView.attributedText = newText
    }
    
    @objc func toggleColor() {
        let selectedRange = textView.selectedRange
        guard selectedRange.length > 0, selectedRange.location < textView.attributedText.length else { return }
        
        let currentAttributes = textView.attributedText.attributes(at: selectedRange.location, effectiveRange: nil)
        _ = currentAttributes[.foregroundColor] as? UIColor
        
        chooseColor { [weak self] selectedColor in
            guard let self = self else { return }
            
            let newAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: selectedColor]
            let newText = NSMutableAttributedString(attributedString: self.textView.attributedText)
            newText.addAttributes(newAttributes, range: selectedRange)
            
            self.textView.attributedText = newText
        }
    }
    
    @IBAction func increaseFontButtonTapped(_ sender: Any) {
        let newFontSize = textView.font?.pointSize ?? UIFont.systemFontSize
        textView.font = textView.font?.withSize(newFontSize + 2.0)
    }
    
    @IBAction func decreaseFontButtonTapped(_ sender: Any) {
        let newFontSize = max((textView.font?.pointSize ?? UIFont.systemFontSize) - 2.0, 10.0)
        textView.font = textView.font?.withSize(newFontSize)
    }
    
    
    @IBAction func speedSliderChanged(_ sender: Any) {
        let speed = speedSlider.value * 10
        self.showToast(message: String(Int(speed)), duration: 1.0)
        startScrolling()
    }
    
    @IBAction func startButtonTapped(_ sender: Any) {
        if longPressRecognizer?.state != .changed && longPressRecognizer?.state != .ended {
            if scrollTimer != nil {
                stopScrolling()
                startButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            } else {
                startScrolling()
                startButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                isScrolling = true
            }
        }
    }
    
    func startScrolling() {
        // Parar o timer existente
        scrollTimer?.invalidate()
        
        // Se chegou ao final do texto, retornar ao início
        if hasReachedEnd {
            self.textView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            hasReachedEnd = false
        }
        
        // Calcular a velocidade de rolagem com base na posição do slider
        let scrollSpeed = CGFloat(speedSlider.value) * 10.0
        
        // Iniciar um novo timer
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            // Atualizar a posição de rolagem
            let bottomOffset = self.textView.contentOffset.y + scrollSpeed
            self.textView.setContentOffset(CGPoint(x: 0, y: bottomOffset), animated: false)
            
            // Verificar se todo o texto saiu da tela
            let contentHeight = self.textView.contentSize.height
            let frameHeight = self.textView.frame.size.height
            if bottomOffset + frameHeight >= contentHeight {
                self.stopScrolling()
                self.startButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                self.isScrolling = false
                
                // Ficar no final do texto
                let endOffset = CGPoint(x: 0, y: max(0, contentHeight - frameHeight))
                self.textView.setContentOffset(endOffset, animated: false)
                
                // Marcar que chegou ao fim
                self.hasReachedEnd = true
            }
        }
    }
    
    func stopScrolling() {
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
    
}

extension UIViewController {
    func showToast(message : String, duration: TimeInterval) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width / 2 - 75, y: self.view.frame.size.height - 100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: duration, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}

extension ViewController: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            return self.makeContextMenu()
        })
    }
    
    func makeContextMenu() -> UIMenu {
        let toggleBold = UIAction(title: "Negrito", image: UIImage(systemName: "bold")) { action in
            self.toggleBold()
        }
        
        let toggleColor = UIAction(title: "Cor", image: UIImage(systemName: "paintbrush")) { action in
            self.toggleColor()
        }
        
        return UIMenu(title: "", children: [toggleBold, toggleColor])
    }
    
}



