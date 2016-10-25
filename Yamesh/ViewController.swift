//
//  ViewController.swift
//  Yamesh
//
//  Created by Takashi Hatakeyama on 2016/10/18.
//  Copyright © 2016年 esm. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager?
    var peripheral: CBPeripheral?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - CBCentralManagerDelegate

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            print("state: poweredOff")
        case .poweredOn:
            print("state: poweredOn")

            // スキャンを開始
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)

            // LEDサービス（ serviceのUUID = 72C90001-57A9-4D40-B746-534E22EC9F9E ）のスキャンを開始
            let service = CBUUID(string: "19B10000-E8F2-537E-4F6C-D104768A1214")
            self.centralManager?.scanForPeripherals(withServices: [service], options: nil)
        case .resetting:
            print("state: resetting")
        case .unauthorized:
            print("state: unauthorized")
        case .unknown:
            print("state: unauthorized")
        case .unsupported:
            print("state: unsupported")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("発見したBLEデバイス: \(peripheral)")

        // ペリフェラルがメモリから開放されないよう、インスタンス変数へ保持しておく
        self.peripheral = peripheral

        // 接続開始
        self.centralManager?.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // 接続成功
        print("接続成功: \(peripheral)")

        peripheral.delegate = self

        // サービス探索開始
        peripheral.discoverServices(nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("\(peripheral.services!.count) 個のサービスを発見")

        if let service = peripheral.services?.first {
            // キャラクタリスティックを探索
//            let characteristic = CBUUID(string: "19B10001-E8F2-537E-4F6C-D104768A1214")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            print("\(characteristics.count) 個のキャラクタリスティックを発見")

            if let characteristic = characteristics.first {
                // キャラクタリスティックからのRead
                peripheral.readValue(for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("読み込み成功！ service: \(characteristic.service.uuid), characteristic: \(characteristic.uuid)")

        if let data = characteristic.value {
            let s = data.map { String(format: "%02X", $0) }.joined()
            print("value: \(s)")
        }

        // 書き込みを行う
        let newValue = NSData(bytes: [0x1], length: 1)
        peripheral.writeValue(newValue as Data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("書き込み成功！ service: \(characteristic.service.uuid), characteristics: \(characteristic.uuid)")
    }
}

