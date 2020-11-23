//
//  ViewController.swift
//  Multicast
//
//  Created by Aurélien COLAS on 28/09/2020.
//

import UIKit

class ViewController: UIViewController {
    @IBAction func didTapCreateSocketButton(_ sender: Any) {
        createSocket()
    }
    @IBAction func didTapSendMessageButton(_ sender: Any) {
        sendMessage()
    }
    @IBAction func didTapCloseSockettButton(_ sender: Any) {
        closeSocket()
    }
    
    private var socket: CFSocket?
    private var addrData: CFData?

    private func createSocket() {
        guard socket == nil else {
            print("Socket already created")
            return
        }

        // create the socket
        socket = CFSocketCreate(kCFAllocatorDefault, AF_INET, SOCK_DGRAM, IPPROTO_UDP, 0, nil, nil)

        // check the address
        var sin = sockaddr_in() // https://linux.die.net/man/7/ip
        sin.sin_len = __uint8_t(MemoryLayout.size(ofValue: sin))
        sin.sin_family = sa_family_t(AF_INET)
        sin.sin_port = UInt16(1900).bigEndian
        sin.sin_addr.s_addr = inet_addr("239.255.255.250")
        addrData = NSData(bytes: &sin, length: MemoryLayout.size(ofValue: sin)) as CFData
        
        print("Socket created")
    }
    
    private func closeSocket() {
        guard let socket = socket else {
            print("Socket not created")
            return
        }
        CFSocketInvalidate(socket)
        self.socket = nil
        print("Socket closed")
    }
    
    private func sendMessage() {
        guard let socket = socket, let addrData = addrData else {
            print("Socket not created")
            return
        }
        
        // build the search message
        let message = "Hello Cruel World!\r\nCoucou monde cruel\r\n"
        guard let messageData = message.data(using: .utf8) else {
            print("Failed to build the message")
            return
        }

        // send the message
        if CFSocketSendData(socket, addrData, messageData as CFData, 0) == .success {
            print("Message sent with success")
        } else {
            print("Failed to send the message. errno: \(errno)")
        }
    }
}

