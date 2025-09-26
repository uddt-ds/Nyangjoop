//
//  BaseViewController.swift
//  Nyangjoop
//
//  Created by Lee on 9/26/25.
//

import UIKit

class BaseViewController: UIViewController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        configureHierarchy()
        configureLayout()
        configureView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }


    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func configureHierarchy() { }

    func configureLayout() { }

    func configureView() {
        view.backgroundColor = .white
    }
}
