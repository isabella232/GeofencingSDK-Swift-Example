//
//  ViewController.swift
//  GeofencingSDK
//
//  Created by Michael Odere on 1/10/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import AirMap
import AirMapGeofencing
import CoreLocation
import Mapbox
import RxCocoa
import RxSwift
import Turf
import UIKit

class ViewController: UIViewController {

	@IBOutlet weak var mapView: AirMapMapView!

	@IBOutlet weak var playButton: UIButton!
	@IBOutlet weak var tabHighlight: UIView!
    @IBOutlet weak var tabStackView: UIStackView!
    @IBOutlet weak var swipeViewContainer: UIView!
    @IBOutlet weak var intersectingButton: UIButton!
    @IBOutlet weak var entertingButton: UIButton!
    @IBOutlet weak var approachingButton: UIButton!

	var geofencingService: GeofencingService!

	private var swipeView: SwipeView!
	private var statusViews = [StatusViewController]()

	private var intersectingViewController: StatusViewController!
	private var enteringViewController: StatusViewController!
	private var approachingViewController: StatusViewController!

	private var aircraftAnnotation: AircraftAnnotation!
	private var lineString: LineStringFeature!
	private var flightSimulator: FlightSimulator!
	private var isActive = false
	private var jurisdictions: [AirMapJurisdiction] = []
	private var activeRulesets: [AirMapRuleset] = [] {
		didSet {
			// update the map with the latest rulesets
			mapView.rulesetConfiguration = .manual(rulesets: activeRulesets)
		}
	}

	private let preferredRulesetIds: [AirMapRulesetId] = ["usa_part_107", "usa_airmap_rules"]

	// MARK: - View Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()
		setupLineString()
		setupMapView()
		setupGeofencing()
		setupFlightSimulator()
		setupAircraftAnnotation()
		setupSwipeView()
		setupPlayButton()
	}

	// MARK: - Setup

	private func setupLineString() {
		// The flight path the example will fly
		let url = Bundle.main.url(forResource: "aircraftPath", withExtension: "json")!
		let data = try! Data(contentsOf: url)
		lineString = try! GeoJSON.parse(LineStringFeature.self, from: data)
	}

	private func setupMapView() {

		mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

		// set the visual style
		mapView.theme = .light

        // set the map's ruleset behavior
        mapView.rulesetConfiguration = .automatic

		mapView.centerCoordinate = lineString.geometry.coordinates.first!
		mapView.zoomLevel = 16
		mapView.allowsScrolling = false

		mapView.delegate = self
	}

	private func setupGeofencing() {
		let source = AirspaceMapSource(mapView)
		geofencingService = GeofencingService(source: source)
		geofencingService.delegate = self
	}

	// swiftlint:disable force_try
	private func setupFlightSimulator() {
		flightSimulator = FlightSimulator(lineStringFeature: lineString)
		flightSimulator.delegate = self
	}

	private func setupAircraftAnnotation() {
		aircraftAnnotation = AircraftAnnotation(id: "Drone", coordinate: lineString.geometry.coordinates.first!)
		self.mapView.addAnnotation(aircraftAnnotation)
	}

	private func setupPlayButton() {
		playButton.layer.cornerRadius = playButton.frame.width / 2
	}

	private func setupSwipeView() {

		swipeView = SwipeView(frame: swipeViewContainer.bounds)
		swipeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		swipeViewContainer.addSubview(swipeView)
		swipeView.isPagingEnabled = true
		swipeView.alwaysBounceHorizontal = false
		swipeView.showsHorizontalScrollIndicator = false
		swipeView.showsVerticalScrollIndicator = false
		swipeView.delegate = self

		// Setup child views
		let sb = UIStoryboard(name: "Main", bundle: nil)
		intersectingViewController = sb.instantiateViewController(withIdentifier: "StatusViewController") as? StatusViewController
		enteringViewController = sb.instantiateViewController(withIdentifier: "StatusViewController") as? StatusViewController
		approachingViewController = sb.instantiateViewController(withIdentifier: "StatusViewController") as? StatusViewController

		// Order here matters. Must align with order of the buttons in the storyboard
		statusViews = [intersectingViewController, enteringViewController, approachingViewController]

		statusViews.forEach { addChild($0) }
		statusViews.forEach { swipeView.addSubview($0.view) }

		swipeView.setNeedsLayout()
	}

	// MARK: - Update

	func updateFlight(coordinate: CLLocationCoordinate2D) {
		aircraftAnnotation.setValuesForKeys([
			"coordinate": aircraftAnnotation.coordinate
		])

		aircraftAnnotation.willChangeValue(forKey: "coordinate")
		aircraftAnnotation.coordinate = coordinate
		aircraftAnnotation.didChangeValue(forKey: "coordinate")
	}

	// MARK: - Action

	@IBAction func playAction(_ button: UIButton) {
		if isActive {
			flightSimulator.pause()
			button.setImage(UIImage(named: "play"), for: .normal)
		} else {
			flightSimulator.start()
			button.setImage(UIImage(named: "pause"), for: .normal)
		}

		isActive = !isActive
	}

	@IBAction func switchTabAction(_ button: UIButton) {

		let buttons = [intersectingButton, entertingButton, approachingButton]
		let index = buttons.index(of: button)!

		let offset = swipeView.bounds.width * CGFloat(index)
		swipeView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
	}
}

// MARK: - GeofencingStatusDelegate

extension ViewController: GeofencingStatusDelegate {

	func onStatusChanged(statuses: [GeofencingStatus]) {
		let filteredStatuses = statuses
			.reduce([]) { (result, status) -> [GeofencingStatus] in
				guard let object = status.airspaceObject as? MapboxAirspaceObject,
					  let name = object.name,
					  !(result.contains(where: { ($0.airspaceObject as! MapboxAirspaceObject).name! == name }))
				else { return result }

				var newResult = result
				newResult.append(status)
				return newResult
			}

		let intersecting = filteredStatuses.filter { $0.level == Level.intersecting }
		let entering = filteredStatuses.filter { $0.level == Level.entering }
		let approaching = filteredStatuses.filter { $0.level == Level.approaching }

		intersectingViewController.statuses = intersecting
		enteringViewController.statuses = entering
		approachingViewController.statuses = approaching
	}
}

// MARK: - FlightSimulatorDelegate

extension ViewController: FlightSimulatorDelegate {
	func onPositionChanged(coordinate: CLLocationCoordinate2D, altitudeAgl: Meters?) {
		mapView.setCenter(coordinate, animated: false)
		updateFlight(coordinate: coordinate)
		geofencingService.onPositionChanged(coordinate: coordinate, altitudeAgl: altitudeAgl)
	}

	func onSpeedChange(velocity: Velocity) {
		geofencingService.onSpeedChange(velocity: velocity)
	}
}

// MARK: - AirMapMapViewDelegate

extension ViewController: AirMapMapViewDelegate {
	func airMapMapViewJurisdictionsDidChange(mapView: AirMapMapView, jurisdictions: [AirMapJurisdiction]) {
		self.jurisdictions = jurisdictions

		// Handle updates to the map's jurisdictions and resolve which rulesets should be active based on user preference
		activeRulesets = AirMapRulesetResolver.resolvedActiveRulesets(with: Array(preferredRulesetIds), from: jurisdictions, enableRecommendedRulesets: false)
	}
}

// MARK: - MGLMapViewDelegate

extension ViewController: MGLMapViewDelegate {
	func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {

		if let annotation = annotation as? AircraftAnnotation {
			return MGLAnnotationImage(image: annotation.getImage(), reuseIdentifier: annotation.getReuseIdentifier())
		}

		return nil
	}
}

// MARK: - UIScrollViewDelegate

extension ViewController: UIScrollViewDelegate {

	func scrollViewDidScroll(_ scrollView: UIScrollView) {

		let tabs = tabStackView.arrangedSubviews.compactMap { $0 as? UIButton }
		let tabCount = CGFloat(tabs.count)

		let offset = scrollView.contentOffset.x / tabCount
		tabHighlight.transform.tx = offset
	}
}
