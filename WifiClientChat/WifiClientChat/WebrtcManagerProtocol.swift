//
//  ViewController.swift
//  WifiChat
//
//  Created by Swayam Agrawal on 25/08/17.
//  Copyright © 2017 Avviotech. All rights reserved.
//

import Foundation
@objc protocol WebrtcManagerProtocol {

  func offerSDPCreated(_ sdp:RTCSessionDescription)
  func localStreamAvailable(_ stream:RTCMediaStream)
  func remoteStreamAvailable(_ stream:RTCMediaStream)
  func answerSDPCreated(_ sdp:RTCSessionDescription)
  func iceCandidatesCreated(_ iceCandidate:RTCICECandidate)
  func dataReceivedInChannel(_ data:Data)
}
