Pod::Spec.new do |s|
  
  version = '0.1.0.beta.2'

  s.name              = 'AirMapGeofencingSDK'
  s.module_name       = 'AirMapGeofencing'
  s.author            = 'AirMap, Inc.'
  s.version           = version
  s.summary           = 'A simple pod to deliver the AirMapGeofencingSDK Framework.'
  s.description       = 'This pod contains the AirMapGeofencingSDK Framework and installs it for easy use'
  s.homepage          = 'https://github.com/airmap/GeofencingSDK-Swift-Example'
  s.license           = { :type => 'Apache License, Version 2.0' }
  s.social_media_url  = 'https://twitter.com/AirMapIO'

  s.source = {
    :http => "https://github.com/airmap/GeofencingSDK-Swift-Example/releases/download/#{s.version.to_s}/AirMapGeofencing.framework.zip"
  }

  s.platform              = :ios
  s.ios.deployment_target = '9.0'
  s.swift_version         = '4.1'

  s.ios.vendored_frameworks = 'Carthage/Build/iOS/AirMapGeofencing.framework'

  s.dependency 'RxCocoa'
  s.dependency 'RxSwift'
  s.dependency 'Turf'

end
