//
//  OnboardingController.swift
//  Lock n Key Wallet
//
//  Created by Javier Gomez on 12/7/21.
//

import UIKit

import UIKit

// MARK: — Data Model

struct OnboardingPage {
    let icon: String
    let title: String
    let body: String
    let accent: UIColor
}

// MARK: — OnboardingController

class OnboardingController: UIViewController {

    // MARK: — Data
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Your vault,\nyour rules.",
            body: "Store passwords, cards, notes and images — all encrypted, all private.",
            accent: .accentBrand
        ),
        OnboardingPage(
            icon: "key.fill",
            title: "Military-grade\nencryption.",
            body: "Every piece of data is encrypted before it ever leaves your device.",
            accent: .accentBrand
        ),
        OnboardingPage(
            icon: "square.grid.2x2.fill",
            title: "Everything\nin one place.",
            body: "Passwords, cards, images, secure notes — organized and always accessible.",
            accent: .accentBrand
        )
    ]

    // MARK: — UI
    private var pageVC: UIPageViewController!
    private var currentIndex = 0

    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.numberOfPages          = 3
        pc.currentPage            = 0
        pc.pageIndicatorTintColor = UIColor.accentBrand.withAlphaComponent(0.3)
        pc.currentPageIndicatorTintColor = .accentBrand
        pc.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()

    private let skipButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Skip", for: .normal)
        btn.setTitleColor(.textSecondary, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let continueButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Continue", for: .normal)
        btn.setTitleColor(.backgroundPrimary, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor    = .accentBrand
        btn.layer.cornerRadius = 14
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: — Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundPrimary
        setupPageViewController()
        setupBottomControls()
    }

    // MARK: — Setup

    private func setupPageViewController() {
        pageVC = UIPageViewController(transitionStyle: .scroll,
                                      navigationOrientation: .horizontal)
        pageVC.dataSource = self
        pageVC.delegate   = self

        let first = makePageVC(index: 0)
        pageVC.setViewControllers([first], direction: .forward, animated: false)

        addChild(pageVC)
        view.addSubview(pageVC.view)
        pageVC.view.translatesAutoresizingMaskIntoConstraints = false
        pageVC.didMove(toParent: self)

        NSLayoutConstraint.activate([
            pageVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupBottomControls() {
        view.addSubview(pageControl)
        view.addSubview(skipButton)
        view.addSubview(continueButton)

        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            continueButton.heightAnchor.constraint(equalToConstant: 54),

            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -16),

            skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            skipButton.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -8)
        ])
    }

    // MARK: — Page factory

    private func makePageVC(index: Int) -> OnboardingPageViewController {
        let vc    = OnboardingPageViewController()
        vc.page   = pages[index]
        vc.pageIndex = index
        return vc
    }

    // MARK: — Actions

    @objc private func continueTapped() {
        if currentIndex < pages.count - 1 {
            currentIndex += 1
            let next = makePageVC(index: currentIndex)
            pageVC.setViewControllers([next], direction: .forward, animated: true)
            updateControls()
        } else {
            finish()
        }
    }

    @objc private func skipTapped() {
        finish()
    }

    private func finish() {
        print("→ onboarding finish called")
        dismiss(animated: true)
    }

    private func updateControls() {
        pageControl.currentPage = currentIndex
        let isLast = currentIndex == pages.count - 1
        continueButton.setTitle(isLast ? "Get Started" : "Continue", for: .normal)
        skipButton.isHidden = isLast
    }
}

// MARK: — UIPageViewControllerDataSource

extension OnboardingController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? OnboardingPageViewController,
              vc.pageIndex > 0 else { return nil }
        return makePageVC(index: vc.pageIndex - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? OnboardingPageViewController,
              vc.pageIndex < pages.count - 1 else { return nil }
        return makePageVC(index: vc.pageIndex + 1)
    }
}

// MARK: — UIPageViewControllerDelegate

extension OnboardingController: UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard completed,
              let vc = pageViewController.viewControllers?.first as? OnboardingPageViewController
        else { return }
        currentIndex = vc.pageIndex
        updateControls()
    }
}

// MARK: — OnboardingPageViewController

class OnboardingPageViewController: UIViewController {

    var page: OnboardingPage!
    var pageIndex: Int = 0

    private let iconView    = UIImageView()
    private let titleLabel  = UILabel()
    private let bodyLabel   = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundPrimary
        setupContent()
    }

    private func setupContent() {
        // Icon
        let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .medium)
        iconView.image               = UIImage(systemName: page.icon, withConfiguration: config)
        iconView.tintColor           = page.accent
        iconView.contentMode         = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        // Title
        titleLabel.text          = page.title
        titleLabel.font          = UIFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor     = .textPrimary
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Body
        bodyLabel.text          = page.body
        bodyLabel.font          = UIFont.systemFont(ofSize: 17, weight: .regular)
        bodyLabel.textColor     = .textSecondary
        bodyLabel.numberOfLines = 0
        bodyLabel.textAlignment = .center
        bodyLabel.lineBreakMode = .byWordWrapping
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack       = UIStackView(arrangedSubviews: [iconView, titleLabel, bodyLabel])
        stack.axis      = .vertical
        stack.spacing   = 24
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: 120),
            iconView.widthAnchor.constraint(equalToConstant: 120),

            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
}
