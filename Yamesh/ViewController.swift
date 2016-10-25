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
    let noPeripheralLabel = "(no peripheral)"
    let scanningLabel = "Scanning..."

    var centralManager: CBCentralManager?
    var peripheral: CBPeripheral?
    var ledPeripheral: CBPeripheral?

    @IBOutlet weak var peripheralNameLabel: UILabel!
    @IBOutlet weak var scanButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        centralManager = CBCentralManager(delegate: self, queue: nil)

        initialize()
    }

    func initialize() {
        // ペリフェラルのクリア
        self.ledPeripheral = nil
        self.peripheralNameLabel.text = noPeripheralLabel
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK - Actions

    @IBAction func scanButtonDidPress(_ sender: AnyObject) {

        if scanButton.currentTitle == "SCAN" {
            // ペリフェラルのクリア
            self.ledPeripheral = nil
            self.peripheralNameLabel.text = scanningLabel

            // LEDサービスのスキャンを開始
            // serviceのUUID: 72C90001-57A9-4D40-B746-534E22EC9F9E
            let service = CBUUID(string: "19B10000-E8F2-537E-4F6C-D104768A1214")
            self.centralManager?.scanForPeripherals(withServices: [service], options: nil)

            // スキャンボタンのラベル更新
            scanButton.setTitle("STOP SCAN", for: UIControlState.normal)
        } else {
            self.centralManager?.stopScan()
            self.peripheralNameLabel.text = noPeripheralLabel
            scanButton.setTitle("SCAN", for: UIControlState.normal)
        }

    }

    // LEDを点灯する
    @IBAction func onButtonDidPress(_ sender: AnyObject) {
        if let peripheral = self.ledPeripheral {

            // 接続開始
            self.centralManager?.connect(peripheral, options: nil)
        }
    }

    // MARK: - CBCentralManagerDelegate

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            print("state: poweredOff")
        case .poweredOn:
            print("state: poweredOn")
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

        // LEDペリフェラルが見つかったので保持しておく
        self.ledPeripheral = peripheral

        // ペリフェラル名を表示
        self.peripheralNameLabel.text = peripheral.name

        // スキャンボタンのラベルを戻す
        self.scanButton.setTitle("SCAN", for: UIControlState.normal)
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
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    // XXX: 今はLED点灯に特化しちゃってるので、徐々に汎化していく予定
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            print("\(characteristics.count) 個のキャラクタリスティックを発見")

            if let characteristic = characteristics.first {
                // 書き込みを行う
                let newValue: UInt8 = 1
                let newData = NSData(bytes: [newValue], length: 1)
                peripheral.writeValue(newData as Data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("書き込み成功！ service: \(characteristic.service.uuid), characteristics: \(characteristic.uuid)")
    }
}

