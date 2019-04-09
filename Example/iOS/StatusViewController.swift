//
//  StatusViewController.swift
//  GeofencingSDK
//
//  Created by Michael Odere on 1/10/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import AirMapGeofencing
import UIKit

class StatusViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

	let formatter = NumberFormatter()

	var statuses = [GeofencingStatus]() {
		didSet {
			self.tableView.reloadData()
		}
	}

	// MARK: - View Lifecycle

	override func viewDidLoad() {
		tableView.dataSource = self
		formatter.maximumFractionDigits = 3
	}
}

// MARK: - UITableViewDataSource

extension StatusViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return statuses.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "StatusCell") as! StatusCell
		let status = statuses[indexPath.row]
		let distanceTo = formatter.string(from: NSNumber(value: status.context.distanceTo)) ?? "-"

		var timeToString = "-"
		if let timeTo = status.context.timeTo, let formattedTimeTo = formatter.string(from: NSNumber(value: timeTo)) {
			timeToString = formattedTimeTo
		}

		cell.titleLabel.text = (status.airspaceObject as? MapboxAirspaceObject)?.name
		cell.descriptionLabel.text = "\(distanceTo) m, \(timeToString) s"

		return cell
	}
}
