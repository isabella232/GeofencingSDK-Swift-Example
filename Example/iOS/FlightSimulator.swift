//
//  FlightSimulator.swift
//  GeofencingSDK
//
//  Created by Michael Odere on 1/10/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import AirMapGeofencing
import CoreLocation
import RxCocoa
import RxSwift
import Turf

protocol FlightSimulatorDelegate: class {
	func onPositionChanged(coordinate: CLLocationCoordinate2D, altitudeAgl: Meters?)
	func onSpeedChange(velocity: Velocity)
}

class FlightSimulator {

	public weak var delegate: FlightSimulatorDelegate?

	private let lineStringFeature: LineStringFeature!
	private var currentIndex: Int = 0
	private var currentCoordinate: CLLocationCoordinate2D!
	private var targetCoordinate: CLLocationCoordinate2D!
	private var distancePerInterval: Meters!

	// speed of the object in meters per second
	private let speed: Double = 14
	// duration between updatessent to delegate in seconds
	private let intervalDuration: RxTimeInterval = 0.2

	private let isActive = BehaviorRelay(value: false)
	private let disposeBag = DisposeBag()

	init(lineStringFeature: LineStringFeature) {
		self.lineStringFeature = lineStringFeature
		guard self.lineStringFeature.geometry.coordinates.count > 1
		else { fatalError("Flight simulator expects line string with more than 1 coordinate") }

		currentCoordinate = self.lineStringFeature.geometry.coordinates[0]
		targetCoordinate = self.lineStringFeature.geometry.coordinates[1]
		distancePerInterval = self.speed * self.intervalDuration

		setupBindings()
	}

	// MARK: - Public

	public func start() {
		isActive.accept(true)
	}

	public func pause() {
		isActive.accept(false)
	}

	// MARK: - Private

	private func setupBindings() {

		let interval = Observable<Int>
			.interval(intervalDuration, scheduler: MainScheduler.instance)

		Observable.combineLatest(
				isActive,
				interval
			)
			.filter { $0.0 }
			.subscribe(onNext: {[unowned self] _ in

				let distanceToTargetCoordinate = self.currentCoordinate.distance(to: self.targetCoordinate)
				// Don't want to go beyond the targetCoordinate
				let distance = min(distanceToTargetCoordinate, self.distancePerInterval)

				// Need bearing to find direction the next point needs to go and the velocity
				let bearing = FlightSimulator.bearingBetweenLocation(coordinate1: self.currentCoordinate, coordinate2: self.targetCoordinate)

				// Update currentCoordinate based off of distance and bearing
				self.currentCoordinate = FlightSimulator.destination(coordinate: self.currentCoordinate, distance: distance, bearing: bearing)
				self.delegate?.onPositionChanged(coordinate: self.currentCoordinate, altitudeAgl: 0)

				// speed is constant, but Vx & Vy change with bearing
				let velocityX = Float(cos(FlightSimulator.degreesToRadians(degrees: bearing)) * self.speed)
				let velocityY = Float(sin(FlightSimulator.degreesToRadians(degrees: bearing)) * self.speed)
				self.delegate?.onSpeedChange(velocity: Velocity(velocityX, velocityY, 0))

				// Update the targetCoordinate
				if distanceToTargetCoordinate <= self.distancePerInterval {
					let coordinatesCount = self.lineStringFeature.geometry.coordinates.count
					let nextIndex = self.currentIndex + 1
					self.currentIndex = nextIndex >= coordinatesCount ? 0 : nextIndex

					self.targetCoordinate = self.lineStringFeature.geometry.coordinates[self.currentIndex]
				}
			})
			.disposed(by: disposeBag)
	}
}

// MARK: - Private Static Extension

extension FlightSimulator {

	// Referenced from http://turfjs.org/docs/#destination
	private static func destination(coordinate: CLLocationCoordinate2D, distance: Meters, bearing: CLLocationDegrees) -> CLLocationCoordinate2D {
		let fromLatitudeRadians = FlightSimulator.degreesToRadians(degrees: coordinate.latitude)
		let fromLongitudeRadians = FlightSimulator.degreesToRadians(degrees: coordinate.longitude)
		let bearingRadians = FlightSimulator.degreesToRadians(degrees: bearing)
		let distanceRadians = FlightSimulator.distanceToRadians(meters: distance)

		let toLatitudeRadians = asin(sin(fromLatitudeRadians) * cos(distanceRadians) +
			cos(fromLatitudeRadians) * sin(distanceRadians) * cos(bearingRadians))
		let toLongitudeRadians = fromLongitudeRadians + atan2(sin(bearingRadians) *
			sin(distanceRadians) * cos(fromLatitudeRadians),
			cos(distanceRadians) - sin(fromLatitudeRadians) * sin(toLatitudeRadians))

		let latitude = FlightSimulator.radiansToDegrees(radians: toLatitudeRadians)
		let longitude = FlightSimulator.radiansToDegrees(radians: toLongitudeRadians)

		return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}

	// Referenced from https://stackoverflow.com/questions/26998029/calculating-bearing-between-two-cllocation-points-in-swift
	private static func bearingBetweenLocation(coordinate1: CLLocationCoordinate2D, coordinate2: CLLocationCoordinate2D) -> Degree {
		let lat1 = FlightSimulator.degreesToRadians(degrees: coordinate1.latitude)
		let lon1 = FlightSimulator.degreesToRadians(degrees: coordinate1.longitude)

		let lat2 = FlightSimulator.degreesToRadians(degrees: coordinate2.latitude)
		let lon2 = FlightSimulator.degreesToRadians(degrees: coordinate2.longitude)

		let dLon = lon2 - lon1

		let y = sin(dLon) * cos(lat2)
		let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
		let radiansBearing = atan2(y, x)

		return radiansToDegrees(radians: radiansBearing)
	}

	private static func distanceToRadians(meters: Meters) -> Radian {
		return (meters / 1000) / 6371.0
	}

	private static func degreesToRadians(degrees: CLLocationDegrees) -> Radian {
		return degrees * Double.pi / 180
	}

	private static func radiansToDegrees(radians: Radian) -> Degree {
		return (radians * 180) / Double.pi
	}
}
