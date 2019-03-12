//
//  MapboxAirspaceObject.swift
//  GeofencingSDK
//
//  Created by Michael Odere on 1/10/19.
//  Copyright © 2018 AirMap, Inc. All rights reserved.
//

import AirMap
import AirMapGeofencing
import Turf

struct MapboxAirspaceObject: AirspaceObject {
	var geometry: Geofencible
	var attributes: [String: Any]
	var evaluationType: GeoEvaluationType

	var name: String? {
		return attributes["name"] as? String
	}

	var restriction: String? {
		return attributes["restriction_type"] as? String
	}

	var category: AirMapAirspaceType? {
		return AirMapAirspaceType(rawValue: attributes["category"] as? String ?? "")
	}
}
