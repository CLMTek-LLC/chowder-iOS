//
//  CustomSheet2.swift
//  Chowder
//
//  Created on 18/02/2026.
//

import SwiftUI
import UIKit

// MARK: - PassThroughView

class PassThroughView: UIView {
    weak var sheetContainer: UIView?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let container = sheetContainer else { return nil }
        let containerPoint = convert(point, to: container)
        guard container.bounds.contains(containerPoint) else { return nil }
        return super.hitTest(point, with: event)
    }
}

// MARK: - SheetInputViewController

class SheetInputViewController: UIViewController {

    private var progress: CGFloat = 0 {
        didSet { applyProgress(animated: false) }
    }

    private var keyboardHeight: CGFloat = 0
    private var isKeyboardVisible = false

    private let minHeight: CGFloat = 80
    private var maxHeight: CGFloat {
        let screen = view.bounds.height
        return isKeyboardVisible ? screen / 3 : screen / 2
    }
    private var fullTranslation: CGFloat { maxHeight - minHeight }

    // Subviews
    private let sheetContainer = UIView()
    private let sheetGlassBackground = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let dragHandle = UIView()
    private let galleryPlaceholder = UIView()
    private let inputBar = UIView()
    private let inputGlassBackground = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let plusButton = UIButton(type: .system)
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)

    private var sheetHeightConstraint: NSLayoutConstraint!
    private var sheetBottomConstraint: NSLayoutConstraint!

    private var panStartProgress: CGFloat = 0

    private var passThroughView: PassThroughView { view as! PassThroughView }

    // MARK: - Lifecycle

    override func loadView() {
        let ptView = PassThroughView()
        ptView.backgroundColor = .clear
        self.view = ptView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSheetContainer()
        setupSheetGlassBackground()
        setupDragHandle()
        setupInputBar()
        setupGalleryPlaceholder()
        setupGestures()
        setupKeyboardObservers()

        passThroughView.sheetContainer = sheetContainer
        applyProgress(animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSheetBackgroundMask()
        let inputHeight = inputGlassBackground.bounds.height
        if inputHeight > 0 {
            inputGlassBackground.layer.cornerRadius = inputHeight / 2
        }
    }

    // MARK: - Sheet Container

    private func setupSheetContainer() {
        sheetContainer.translatesAutoresizingMaskIntoConstraints = false
        sheetContainer.backgroundColor = .clear
        sheetContainer.clipsToBounds = false
        view.addSubview(sheetContainer)

        sheetHeightConstraint = sheetContainer.heightAnchor.constraint(equalToConstant: minHeight)
        sheetBottomConstraint = sheetContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)

        NSLayoutConstraint.activate([
            sheetContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetBottomConstraint,
            sheetHeightConstraint,
        ])
    }

    private let sheetShadowContainer = UIView()

    // MARK: - Glass Background (Sheet)

    private func setupSheetGlassBackground() {
        // Shadow container (shadows can't render when masksToBounds is true)
        sheetShadowContainer.translatesAutoresizingMaskIntoConstraints = false
        sheetShadowContainer.backgroundColor = .clear
        sheetShadowContainer.layer.shadowColor = UIColor.black.cgColor
        sheetShadowContainer.layer.shadowOpacity = 0.18
        sheetShadowContainer.layer.shadowRadius = 28
        sheetShadowContainer.layer.shadowOffset = CGSize(width: 0, height: -6)
        sheetShadowContainer.alpha = 0
        sheetContainer.addSubview(sheetShadowContainer)

        sheetGlassBackground.translatesAutoresizingMaskIntoConstraints = false
        sheetGlassBackground.clipsToBounds = true
        sheetShadowContainer.addSubview(sheetGlassBackground)

        NSLayoutConstraint.activate([
            sheetShadowContainer.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor, constant: 4),
            sheetShadowContainer.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor, constant: -4),
            sheetShadowContainer.topAnchor.constraint(equalTo: sheetContainer.topAnchor),
            sheetShadowContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 40),

            sheetGlassBackground.leadingAnchor.constraint(equalTo: sheetShadowContainer.leadingAnchor),
            sheetGlassBackground.trailingAnchor.constraint(equalTo: sheetShadowContainer.trailingAnchor),
            sheetGlassBackground.topAnchor.constraint(equalTo: sheetShadowContainer.topAnchor),
            sheetGlassBackground.bottomAnchor.constraint(equalTo: sheetShadowContainer.bottomAnchor),
        ])
    }

    private func updateSheetBackgroundMask() {
        let bounds = sheetGlassBackground.bounds
        guard bounds.width > 0 && bounds.height > 0 else { return }

        let topRadius: CGFloat = 40
        let bottomRadius: CGFloat = 60

        let path = UIBezierPath()
        path.move(to: CGPoint(x: topRadius, y: 0))
        path.addLine(to: CGPoint(x: bounds.width - topRadius, y: 0))
        path.addQuadCurve(to: CGPoint(x: bounds.width, y: topRadius),
                          controlPoint: CGPoint(x: bounds.width, y: 0))
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.height - bottomRadius))
        path.addQuadCurve(to: CGPoint(x: bounds.width - bottomRadius, y: bounds.height),
                          controlPoint: CGPoint(x: bounds.width, y: bounds.height))
        path.addLine(to: CGPoint(x: bottomRadius, y: bounds.height))
        path.addQuadCurve(to: CGPoint(x: 0, y: bounds.height - bottomRadius),
                          controlPoint: CGPoint(x: 0, y: bounds.height))
        path.addLine(to: CGPoint(x: 0, y: topRadius))
        path.addQuadCurve(to: CGPoint(x: topRadius, y: 0),
                          controlPoint: CGPoint(x: 0, y: 0))
        path.close()

        let mask = CAShapeLayer()
        mask.path = path.cgPath
        sheetGlassBackground.layer.mask = mask

        sheetShadowContainer.layer.shadowPath = path.cgPath
    }

    // MARK: - Drag Handle

    private func setupDragHandle() {
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        dragHandle.backgroundColor = UIColor.tertiaryLabel
        dragHandle.layer.cornerRadius = 2.5
        sheetContainer.addSubview(dragHandle)

        NSLayoutConstraint.activate([
            dragHandle.centerXAnchor.constraint(equalTo: sheetContainer.centerXAnchor),
            dragHandle.topAnchor.constraint(equalTo: sheetContainer.topAnchor, constant: 10),
            dragHandle.widthAnchor.constraint(equalToConstant: 36),
            dragHandle.heightAnchor.constraint(equalToConstant: 5),
        ])
    }

    // MARK: - Gallery Placeholder

    private func setupGalleryPlaceholder() {
        galleryPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        galleryPlaceholder.backgroundColor = .clear
        sheetContainer.addSubview(galleryPlaceholder)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Gallery"
        label.textColor = .tertiaryLabel
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        galleryPlaceholder.addSubview(label)

        NSLayoutConstraint.activate([
            galleryPlaceholder.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor),
            galleryPlaceholder.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor),
            galleryPlaceholder.topAnchor.constraint(equalTo: dragHandle.bottomAnchor, constant: 8),
            galleryPlaceholder.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            label.centerXAnchor.constraint(equalTo: galleryPlaceholder.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: galleryPlaceholder.centerYAnchor),
        ])
    }

    // MARK: - Input Bar

    private func setupInputBar() {
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.backgroundColor = .clear
        sheetContainer.addSubview(inputBar)

        NSLayoutConstraint.activate([
            inputBar.leadingAnchor.constraint(equalTo: sheetContainer.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: sheetContainer.trailingAnchor),
            inputBar.bottomAnchor.constraint(equalTo: sheetContainer.bottomAnchor),
            inputBar.heightAnchor.constraint(equalToConstant: 80),
        ])

        // Glass capsule background for input
        inputGlassBackground.translatesAutoresizingMaskIntoConstraints = false
        inputGlassBackground.clipsToBounds = true
        inputGlassBackground.alpha = 0
        inputBar.addSubview(inputGlassBackground)

        NSLayoutConstraint.activate([
            inputGlassBackground.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 16),
            inputGlassBackground.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -16),
            inputGlassBackground.topAnchor.constraint(equalTo: inputBar.topAnchor, constant: 2),
            inputGlassBackground.bottomAnchor.constraint(equalTo: inputBar.bottomAnchor, constant: -2),
        ])

        // Plus button
        let plusConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        plusButton.setImage(UIImage(systemName: "plus", withConfiguration: plusConfig), for: .normal)
        plusButton.tintColor = .label
        plusButton.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        plusButton.layer.cornerRadius = 22
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
        inputBar.addSubview(plusButton)

        NSLayoutConstraint.activate([
            plusButton.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 16),
            plusButton.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            plusButton.widthAnchor.constraint(equalToConstant: 44),
            plusButton.heightAnchor.constraint(equalToConstant: 44),
        ])

        // Send button
        let sendConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        sendButton.setImage(UIImage(systemName: "arrow.up", withConfiguration: sendConfig), for: .normal)
        sendButton.tintColor = .white
        sendButton.backgroundColor = UIColor.label.withAlphaComponent(0.12)
        sendButton.layer.cornerRadius = 22
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        inputBar.addSubview(sendButton)

        NSLayoutConstraint.activate([
            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44),
        ])

        // Text field
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "OddJob is ready"
        textField.font = .systemFont(ofSize: 17)
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.returnKeyType = .send
        textField.delegate = self
        inputBar.addSubview(textField)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: plusButton.trailingAnchor, constant: 10),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            textField.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    // MARK: - Gestures

    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sheetContainer.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        dragHandle.isUserInteractionEnabled = true
        dragHandle.addGestureRecognizer(tap)

        // Enlarge the tap target around the drag handle
        let tapArea = UIView()
        tapArea.translatesAutoresizingMaskIntoConstraints = false
        tapArea.backgroundColor = .clear
        sheetContainer.insertSubview(tapArea, belowSubview: inputBar)

        let tapOnArea = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapArea.addGestureRecognizer(tapOnArea)

        NSLayoutConstraint.activate([
            tapArea.centerXAnchor.constraint(equalTo: dragHandle.centerXAnchor),
            tapArea.centerYAnchor.constraint(equalTo: dragHandle.centerYAnchor),
            tapArea.widthAnchor.constraint(equalTo: sheetContainer.widthAnchor),
            tapArea.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            panStartProgress = progress
        case .changed:
            let translation = gesture.translation(in: view)
            let delta = -translation.y / fullTranslation
            let newProgress = min(1, max(0, panStartProgress + delta))
            progress = newProgress
            applyProgress(animated: false)
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: view).y
            let projectedProgress = progress + (-velocity / fullTranslation) * 0.15
            let target: CGFloat = projectedProgress > 0.5 ? 1 : 0
            animateToProgress(target)
        default:
            break
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let target: CGFloat = progress < 0.5 ? 1 : 0
        animateToProgress(target)
    }

    @objc private func plusTapped() {
        animateToProgress(1)
    }

    // MARK: - Keyboard

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ note: Notification) {
        guard let info = note.userInfo,
              let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let viewBottom = view.convert(view.bounds, to: nil).maxY
        keyboardHeight = max(0, viewBottom - frame.origin.y)
        isKeyboardVisible = true

        let options = UIView.AnimationOptions(rawValue: curveValue << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.sheetBottomConstraint.constant = -self.keyboardHeight
            self.applyProgress(animated: false)
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ note: Notification) {
        guard let info = note.userInfo,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        keyboardHeight = 0
        isKeyboardVisible = false

        let options = UIView.AnimationOptions(rawValue: curveValue << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.sheetBottomConstraint.constant = 0
            self.applyProgress(animated: false)
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Animation

    private func animateToProgress(_ target: CGFloat) {
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.5,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.progress = target
            self.applyProgress(animated: true)
            self.view.layoutIfNeeded()
        }
    }

    private func applyProgress(animated: Bool) {
        let currentHeight = minHeight + progress * fullTranslation
        sheetHeightConstraint.constant = currentHeight

        // Sheet glass background + shadow
        let showBG = progress > 0.01
        sheetShadowContainer.alpha = showBG ? 1 : 0
        sheetShadowContainer.transform = showBG ? .identity : CGAffineTransform(translationX: 0, y: 80)

        // Input capsule glass
        inputGlassBackground.alpha = progress

        // Plus button fade/shrink
        let plusAlpha = max(0, 1 - progress * 2.5)
        plusButton.alpha = plusAlpha
        let plusScale = 1 - progress * 0.4
        plusButton.transform = CGAffineTransform(scaleX: plusScale, y: plusScale)
            .translatedBy(x: -20 * progress, y: 0)
        plusButton.isUserInteractionEnabled = progress < 0.3

        // Gallery placeholder
        galleryPlaceholder.alpha = progress

        // Drag handle
        dragHandle.alpha = max(0.3, progress)
    }
}

// MARK: - UITextFieldDelegate

extension SheetInputViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - SheetInputRepresentable

struct SheetInputRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SheetInputViewController {
        SheetInputViewController()
    }

    func updateUIViewController(_ uiViewController: SheetInputViewController, context: Context) {}
}

// MARK: - CustomSheet2 (SwiftUI)

struct CustomSheet2: View {
    private let inputBarHeight: CGFloat = 88

    let messages: [MessageItem] = [
        MessageItem(text: "Hi! I'm your OpenClaw assistant. How can I help you today?", isSent: false),
        MessageItem(text: "I need to book a flight to New York", isSent: true),
        MessageItem(text: "I'd be happy to help you book a flight to New York. When would you like to travel?", isSent: false),
        MessageItem(text: "March 15th, returning on the 20th", isSent: true),
        MessageItem(text: "Got it. And which city will you be departing from?", isSent: false),
        MessageItem(text: "San Francisco", isSent: true),
        MessageItem(text: "I found 12 flights from SFO to JFK on March 15th. Would you prefer morning or evening departure?", isSent: false),
        MessageItem(text: "Morning would be best", isSent: true),
        MessageItem(text: "Here are your top options:\n\n• United UA 234 - 7:15 AM - $389\n• Delta DL 512 - 8:30 AM - $412\n• JetBlue B6 918 - 9:00 AM - $367", isSent: false),
        MessageItem(text: "The JetBlue one looks good", isSent: true),
        MessageItem(text: "Excellent choice! JetBlue B6 918 departing at 9:00 AM, arriving at 5:42 PM. Would you like economy or extra legroom?", isSent: false),
        MessageItem(text: "Economy is fine", isSent: true),
        MessageItem(text: "Perfect. I've selected the same return flight for March 20th. Your total comes to $734 roundtrip. Ready to proceed with booking?", isSent: false),
        MessageItem(text: "Yes, let's do it!", isSent: true),
        MessageItem(text: "Your booking is confirmed! ✈️ Confirmation #OCLW7823. I've sent the details to your email.", isSent: false),
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(messages) { message in
                                MessageItemBubble(message: message)
                            }
                            Spacer()
                                .frame(height: inputBarHeight)
                                .id("endSpacer")
                        }
                        .padding()
                    }
                    .contentMargins(.bottom, inputBarHeight, for: .scrollIndicators)
                    .onAppear {
                        proxy.scrollTo("endSpacer", anchor: .bottom)
                    }
                }

                Rectangle()
                    .fill(.regularMaterial)
                    .ignoresSafeArea()
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black.opacity(0.96), location: 0.4),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }
                    .frame(height: inputBarHeight * 2)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()

                SheetInputRepresentable()
                    .ignoresSafeArea(.keyboard)
            }
            .navigationTitle("Odd Job")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CustomSheet2()
}
