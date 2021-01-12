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
        buildMessage()
    }
    @IBAction func didTapCloseSockettButton(_ sender: Any) {
        closeSocket()
    }
    
    private var socket: CFSocket?
    private var addrData: CFData?
    
    var retries = 0

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
    
    private func buildMessage() {
        guard let _ = socket, let _ = addrData else {
            print("Socket not created")
            return
        }
        
        // build the search message
        let messageData = """
               M-SEARCH * HTTP/1.1
               HOST: 239.255.255.250:1900
               MAN: ssdp:discover
               MX: 1
               ST: urn:udi-com:device:X_Insteon_Lighting_Device:1
               """.data(using: .utf8)

        sendMessage(messageData: messageData!)

    }
    
    private func sendMessage(messageData: Data){
        if CFSocketSendData(socket, addrData, (messageData as CFData), 0) == .success {
            print("Message sent with success")
            createListener()
        } else {
            print("Failed to send the message. errno: \(errno)")
            //this only appears to happen on phisical device and not emulator
            if errno == 65 {
                if retries < 10 {
                    retries = retries + 1
                    print("Resend message as it has failed")
                    buildMessage()
                }else {
                    print("Error Too many retires. This may happen if CONNECT TO DEVICES ON YOUR LOCAL NETWORK was not accepted by uers or is waiting for acceptance")
                }
                
            }
        }
    }
    
    
    private func createListener(){
        print("createListner")
        let dispatchQueue = DispatchQueue.global(qos: .background)
        dispatchQueue.async { [self] in
            var responseBuffer = Array<UInt8>(repeating: 0, count: 1024)
            let nativeSocket = CFSocketGetNative(self.socket)
            responseBuffer.withUnsafeMutableBytes{ unsafeRawBufferPointer in
                let rawPtr = unsafeRawBufferPointer.baseAddress
                let result = Darwin.recv(nativeSocket, rawPtr, 4096, 0)
                if result >= 0 {
                    print("response size: \(result)")
                    let output = String(bytes: unsafeRawBufferPointer, encoding: .utf8)
                    print (output!)
                }
            }
        }
    }
}

