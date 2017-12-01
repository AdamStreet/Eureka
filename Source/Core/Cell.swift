//  Cell.swift
//  Eureka ( https://github.com/xmartlabs/Eureka )
//
//  Copyright (c) 2016 Xmartlabs ( http://xmartlabs.com )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

/// Base class for the Eureka cells
open class BaseCell: UITableViewCell, BaseCellType {

    /// Untyped row associated to this cell.
    public var baseRow: BaseRow! { return nil }

    /// Block that returns the height for this cell.
    public var height: (() -> CGFloat)?

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public required override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    /**
     Function that returns the FormViewController this cell belongs to.
     */
    public func formViewController() -> FormViewController? {
        var responder: AnyObject? = self
        while responder != nil {
            if let formVC = responder as? FormViewController {
              return formVC
            }
            responder = responder?.next
        }
        return nil
    }

    open func setup() {}
    open func update() {}

    open func didSelect() {}

    /**
     If the cell can become first responder. By default returns false
     */
    open func cellCanBecomeFirstResponder() -> Bool {
        return false
    }

    /**
     Called when the cell becomes first responder
     */
    @discardableResult
    open func cellBecomeFirstResponder(withDirection: Direction = .down) -> Bool {
        return becomeFirstResponder()
    }

    /**
     Called when the cell resigns first responder
     */
    @discardableResult
    open func cellResignFirstResponder() -> Bool {
        return resignFirstResponder()
    }
}

/// Generic class that represents the Eureka cells.
open class Cell<T>: BaseCell, TypedCellType where T: Equatable {

    public typealias Value = T

    /// The row associated to this cell
    public weak var row: RowOf<T>!

    private var awakeFromNibCalled = false
    
    @IBOutlet public weak var titleLabel : UILabel?
    @IBOutlet public weak var subtitleLabel : UILabel?
    
    private var dynamicConstraints = [NSLayoutConstraint]()
    
    /// Returns the navigationAccessoryView if it is defined or calls super if not.
    override open var inputAccessoryView: UIView? {
        if let v = formViewController()?.inputAccessoryView(for: row) {
            return v
        }
        return super.inputAccessoryView
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        awakeFromNibCalled = true
    }
    
    required public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let titleLabel = UILabel()
        self.titleLabel = titleLabel
        contentView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        self.subtitleLabel = subtitleLabel
        contentView.addSubview(subtitleLabel)
        
        NotificationCenter.default.addObserver(forName: Notification.Name.UIContentSizeCategoryDidChange, object: nil, queue: nil) { [weak self] _ in
            guard let me = self else { return }
            me.update()
        }
        
        setNeedsUpdateConstraints()
    }
    
    deinit {
        guard !awakeFromNibCalled else { return }
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIContentSizeCategoryDidChange, object: nil)
    }
    
    override open func updateConstraints() {
        super.updateConstraints()
        
        if (!awakeFromNibCalled) {
            contentView.removeConstraints(dynamicConstraints)
            dynamicConstraints.removeAll()
            
            // Use default cell layout
            titleLabel?.translatesAutoresizingMaskIntoConstraints = false
            subtitleLabel?.translatesAutoresizingMaskIntoConstraints = false
            
            titleLabel?.setContentHuggingPriority(UILayoutPriority(500), for: .horizontal)
            titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            let horizontalGap : CGFloat = 10.0
            let verticalGap : CGFloat = 6.0
            
            if let titleLabel = titleLabel {
                dynamicConstraints.append(NSLayoutConstraint(item: titleLabel,
                                                             attribute: .leading,
                                                             relatedBy: .equal,
                                                             toItem: contentView,
                                                             attribute: .leading,
                                                             multiplier: 1.0,
                                                             constant: horizontalGap))
                
                dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-(gap)-[titleLabel]-(gap)-|",
                                                                     options: .alignAllCenterY,
                                                                     metrics: ["gap" : verticalGap],
                                                                     views: ["titleLabel" : titleLabel])
            }
            
            if let selectedItemLabel = subtitleLabel {
                dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-(gap)-[selectedItemLabel]-(gap)-|",
                                                                     options: .alignAllCenterY,
                                                                     metrics: ["gap" : verticalGap],
                                                                     views: ["selectedItemLabel" : selectedItemLabel])
                
                dynamicConstraints.append(NSLayoutConstraint(item: selectedItemLabel,
                                                             attribute: .trailing,
                                                             relatedBy: .equal,
                                                             toItem: contentView,
                                                             attribute: .trailing,
                                                             multiplier: 1.0,
                                                             constant: -horizontalGap))
            }
            
            if let titleLabel = titleLabel, let selectedItemLabel = subtitleLabel {
                dynamicConstraints.append(NSLayoutConstraint(item: titleLabel,
                                                             attribute: .trailing,
                                                             relatedBy: .lessThanOrEqual,
                                                             toItem: selectedItemLabel,
                                                             attribute: .leading,
                                                             multiplier: 1.0,
                                                             constant: horizontalGap))
            }
            
            contentView.addConstraints(dynamicConstraints)
        }
    }
    /**
     Update specific labels with title & value
     */
    open func update(textLabel : UILabel?, detailTextLabel : UILabel?) {
        textLabel?.text = row.title
        textLabel?.textColor = row.isDisabled ? .gray : .black
        detailTextLabel?.text = row.displayValueFor?(row.value) ?? (row as? NoValueDisplayTextConformance)?.noValueDisplayText
    }
    
    /**
     Function responsible for setting up the cell at creation time.
     */
    open override func setup() {
        super.setup()
    }

    /**
     Function responsible for updating the cell each time it is reloaded.
     */
    /**
     Function responsible for updating the cell each time it is reloaded.
     */
    open override func update() {
        super.update()
        
        textLabel?.text = nil
        detailTextLabel?.text = nil
        
        update(textLabel: titleLabel, detailTextLabel: subtitleLabel)
    }

    /**
     Called when the cell was selected.
     */
    open override func didSelect() {}

    override open var canBecomeFirstResponder: Bool {
        return false
    }

    open override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            formViewController()?.beginEditing(of: self)
        }
        return result
    }

    open override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            formViewController()?.endEditing(of: self)
        }
        return result
    }

    /// The untyped row associated to this cell.
    public override var baseRow: BaseRow! { return row }
}
