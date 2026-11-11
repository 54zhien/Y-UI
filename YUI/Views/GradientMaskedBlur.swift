import SwiftUI
import UIKit

struct GradientMaskedBlur: UIViewRepresentable {

    enum Edge: Equatable {
        case top
        case bottom
    }

    var edge: Edge = .top
    var opaqueFraction: CGFloat = 0.42

    func makeUIView(context: Context) -> GradientMaskedBlurView {
        let view = GradientMaskedBlurView()
        view.edge = edge
        view.opaqueFraction = opaqueFraction
        return view
    }

    func updateUIView(_ view: GradientMaskedBlurView, context: Context) {
        view.edge = edge
        view.opaqueFraction = opaqueFraction
    }
}

final class GradientMaskedBlurView: UIView {

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let gradientMask = CAGradientLayer()

    var edge: GradientMaskedBlur.Edge = .top {
        didSet { updateGradient() }
    }

    var opaqueFraction: CGFloat = 0.42 {
        didSet { updateGradient() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        addSubview(blurView)
        blurView.layer.mask = gradientMask
        updateGradient()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        blurView.frame = bounds
        gradientMask.frame = blurView.bounds
    }

    private func updateGradient() {
        let end = min(max(opaqueFraction, 0), 0.8)
        let tail = end + (1 - end) * 0.55

        gradientMask.colors = [
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.black.withAlphaComponent(0.38).cgColor,
            UIColor.clear.cgColor
        ]

        let locations: [NSNumber]
        let start: CGPoint
        let finish: CGPoint

        switch edge {
        case .top:
            locations = [0, NSNumber(value: Double(end)), NSNumber(value: Double(tail)), 1]
            start = CGPoint(x: 0.5, y: 0)
            finish = CGPoint(x: 0.5, y: 1)
        case .bottom:
            locations = [0, NSNumber(value: Double(1 - end)), NSNumber(value: Double(1 - tail)), 1]
            start = CGPoint(x: 0.5, y: 1)
            finish = CGPoint(x: 0.5, y: 0)
        }

        gradientMask.locations = locations
        gradientMask.startPoint = start
        gradientMask.endPoint = finish
    }
}
