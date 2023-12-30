//
//  ConsoleViewController.swift
//  Tile
//
//  Created by Marin Todorov on 3/29/23.
//

import AppKit
import SwiftUI
import Combine
import STTextView

struct EditorView: NSViewRepresentable {
    @Binding var text: NSAttributedString
    @Binding var isScrollingToBottom: Bool
    @Binding var scrollToBottom: Bool

    var isEditable: Bool = true
    var font: NSFont?    = .systemFont(ofSize: 14, weight: .regular)

    var onEditingChanged: () -> Void       = {}
    var onCommit        : () -> Void       = {}
    var onTextChange    : (String) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> CustomTextView {
        let textView = CustomTextView(
            text: text,
            isEditable: isEditable,
            font: font
        )
        textView.delegate = context.coordinator
        textView.wantsLayer = true
        return textView
    }

    func updateNSView(_ view: CustomTextView, context: Context) {
        view.text = text
        view.selectedRanges = context.coordinator.selectedRanges

        if scrollToBottom {
            scrollToBottom = false
            view.textView.scrollToEndOfDocument(nil)
        }

        let isAtBottom = view.textView.visibleRect.maxY == view.textView.bounds.maxY
        if isAtBottom {
            view.textView.scrollToEndOfDocument(nil)
        }
        DispatchQueue.main.async {
            if isAtBottom != isScrollingToBottom {
                self.isScrollingToBottom = isAtBottom
            }
        }
    }
}

// MARK: - Coordinator

extension EditorView {

    class Coordinator: NSObject, CustomTextViewDelegate {
        func setIsScrollingToBottom(_ value: Bool) {

        }

        var parent: EditorView
        var selectedRanges: [NSValue] = []

        init(_ parent: EditorView) {
            self.parent = parent
        }

        func textDidBeginEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            self.parent.text = textView.attributedString()
            self.parent.onEditingChanged()
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            self.parent.text = textView.attributedString()
            self.selectedRanges = textView.selectedRanges
        }

        func textDidEndEditing(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            self.parent.text = textView.attributedString()
            self.parent.onCommit()
        }
    }
}

// MARK: - CustomTextView

protocol CustomTextViewDelegate: NSTextViewDelegate {
    func setIsScrollingToBottom(_ value: Bool)
}

final class CustomTextView: NSView {
    private var isEditable: Bool
    private var font: NSFont?

    weak var delegate: CustomTextViewDelegate?

    var text: NSAttributedString {
        didSet {
            textView.textStorage?.setAttributedString(text)
        }
    }

    var selectedRanges: [NSValue] = [] {
        didSet {
            guard selectedRanges.count > 0 else {
                return
            }

            textView.selectedRanges = selectedRanges
        }
    }

    private lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = true
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalRuler = false
        scrollView.autoresizingMask = [.width, .height]
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        return scrollView
    }()

    lazy var textView: NSTextView = {
        let contentSize = scrollView.contentSize
        let textStorage = NSTextStorage()


        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)


        let textContainer = NSTextContainer(containerSize: scrollView.frame.size)
        textContainer.widthTracksTextView = true
        textContainer.containerSize = NSSize(
            width: contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )

        layoutManager.addTextContainer(textContainer)


        let textView                     = NSTextView(frame: .zero, textContainer: textContainer)
        textView.autoresizingMask        = .width
        textView.backgroundColor         = NSColor.textBackgroundColor
        textView.delegate                = self.delegate
        textView.drawsBackground         = true
        textView.font                    = self.font
        textView.isEditable              = self.isEditable
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable   = true
        textView.maxSize                 = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize                 = NSSize(width: 0, height: contentSize.height)
        textView.textColor               = NSColor.labelColor
        textView.allowsUndo              = true

        return textView
    }()

    // MARK: - Init
    init(text: NSAttributedString, isEditable: Bool, font: NSFont?) {
        self.font       = font
        self.isEditable = isEditable
        self.text       = text

        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    let useCustomTextView = true

    override func viewWillDraw() {
        super.viewWillDraw()


        if useCustomTextView {
            setupScrollViewConstraints()
            setupTextView()
        } else {
            scrollView = STTextView.scrollableTextView()
            textView = scrollView.documentView as! NSTextView
        }
    }

    func setupScrollViewConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
    }

    func setupTextView() {
        scrollView.documentView = textView
    }
}
