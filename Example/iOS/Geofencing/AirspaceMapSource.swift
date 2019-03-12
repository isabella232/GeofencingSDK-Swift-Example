//
//  AirspaceMapSource.swift
//  GeofencingSDK
//
//  Created by Michael Odere on 1/10/19.
//  Copyright © 2018 AirMap, Inc. All rights reserved.
//

import AirMap
import AirMapGeofencing
import Mapbox
import Turf

class AirspaceMapSource: AirspaceSource {

	private let mapView: AirMapMapView

	init(_ mapView: AirMapMapView) {
		self.mapView = mapView
	}

	func getAirspaces(coordinates: [Coordinate2D]) -> [AirspaceObject]? {

		guard mapView.zoomLevel > 13.5 else { return [] }
		let frame = mapView.frame

		// Get all airmap layers
		guard let style = mapView.style else { return [] }
		let layers = style.layers
			.compactMap { $0.identifier.hasPrefix("airmap") ? $0.identifier : nil }

		// Get visible features and convert them to airspaceObjects
		let features = self.mapView.visibleFeatures(in: frame, styleLayerIdentifiers: Set(layers))
		let airspaceObjects = features.compactMap { (feature) -> MapboxAirspaceObject? in
			guard let object = GeoJSON.parse(feature.geoJSONDictionary()) else { return nil }
			return MapboxAirspaceObject(geometry: object, attributes: feature.attributes, evaluationType: .fence)
		}

		return airspaceObjects
	}
}
