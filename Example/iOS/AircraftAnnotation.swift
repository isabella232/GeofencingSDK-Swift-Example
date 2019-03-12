//
//  AircraftAnnotation.swift
//  GeofencingSDK
//
//  Created by Michael Odere on 1/10/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Mapbox

class AircraftAnnotation: NSObject {
	let id: String
	var coordinate: CLLocationCoordinate2D

	init(id: String, coordinate: CLLocationCoordinate2D) {
		self.id = id
		self.coordinate = coordinate
	}

	override var hash: Int {
		return id.hash
	}

	static func ==(lhs: AircraftAnnotation, rhs: AircraftAnnotation) -> Bool {
		return lhs.id.hashValue == rhs.id.hashValue
	}
}

extension AircraftAnnotation: MGLAnnotation {
	func getReuseIdentifier() -> String {
		return "Drone_Image_\(id)"
	}

	func getImage() -> UIImage {
		return UIImage(named: "drone_icon")!
	}
}
