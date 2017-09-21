//
//  UniversalRefreshViewController.swift
//  CustomSolutions
//
//  Created by Slava Zubrin on 9/20/17.
//  Copyright © 2017 Slava Zubrin. All rights reserved.
//

import UIKit

class UniversalRefreshViewController: UIViewController {

    @IBOutlet weak var refreshControl: UniversalRefreshControl!
    weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let table = UITableView(frame: .zero)

        table.bounces = false
        table.alwaysBounceVertical = false

        table.panGestureRecognizer.addTarget(self, action: #selector(debug(_:)))

        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        table.dataSource = self
        refreshControl.content = table

        tableView = table
        tableView.reloadData()

        refreshControl.delegate = self
    }

    // DEBUG

    func debug(_ sender: UIPanGestureRecognizer) {
        //print("table.pan.state: \(sender.state.rawValue)")
    }
}

extension UniversalRefreshViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.textLabel?.text = "\(indexPath.row)"

        return cell
    }
}

extension UniversalRefreshViewController: UniversalRefreshControlDelegate {

    func startedLoading(_ sender: UniversalRefreshControl) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: { [weak self] in
            self?.tableView.reloadData()
            sender.finish()
        })
    }
}
