//
//  ViewController.swift
//  WebSocketExample
//
//  Created by KimTaeHyung on 2023/06/25.
//

import UIKit

class ViewController: UIViewController, URLSessionWebSocketDelegate {
    
    private var webSocket: URLSessionWebSocketTask?
    
    private let sendButton: UIButton = {
        let Sbutton = UIButton()
        Sbutton.backgroundColor = .white
        Sbutton.setTitle("Send", for: .normal)
        Sbutton.setTitleColor(.black, for: .normal)
        
        return Sbutton
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.setTitle("Close", for: .normal)
        button.setTitleColor(.black, for: .normal)
        
        return button
    }()
    
    private let textField: UITextField = {
       let textField = UITextField()
        textField.backgroundColor = .white
        textField.placeholder = "Type a message..."
        textField.textColor = .black
        textField.borderStyle = .roundedRect
        
        return textField
    }()
    
    
    let tableView = UITableView()
    var messages: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBlue
        
        let session = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: OperationQueue()
        )
//        let url = URL(string: "wss://s9309.blr1.piesocket.com/v3/1?api_key=cZGOksfuE6CqV1cZfly2CnFBqbE33D1UBzTWgUvd&notify_self=1")
        let url = URL(string: "ws://localhost:1337/")
        webSocket = session.webSocketTask(with: url!)
        webSocket?.resume()
        
        textField.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
        textField.center = CGPoint(x: view.center.x, y: closeButton.frame.maxY + textField.frame.height/2 + 100)
        textField.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(textField)
        
        closeButton.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeButton.center = view.center
        
        sendButton.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)
        view.addSubview(sendButton)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.center = CGPoint(x: closeButton.center.x, y: closeButton.frame.maxY + sendButton.frame.height/2 + 10)
        
        
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CellIdentifier")
        tableView.frame = CGRect(x: 0, y: sendButton.frame.maxY + 10, width: view.bounds.width, height: view.bounds.height - sendButton.frame.maxY - 10)
        tableView.backgroundColor = .red
        tableView.delegate = self
        tableView.dataSource = self
        // tableView의 설정 (예: delegate, dataSource, cell 등)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false


    }
    
    //ping을 통해 webSocket이 잘 연결되고 있는지 확인
    func ping() {
        webSocket?.sendPing { error in
            if let error = error {
                print("Ping error: \(error)")
            }
        }
    }
    
    //connection이 끝났을 때 대한 이유
    @objc func close() {
        webSocket?.cancel(with: .goingAway, reason: "Demo ended".data(using: .utf8))
    }
    
    //
    @objc func send() {

        guard let newMessage = textField.text, !newMessage.isEmpty else { return }
        self.messages.append(newMessage)

        self.webSocket?.send(.string(newMessage), completionHandler: { error in
            if let error = error {
                print("send error: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
        })
    }
    
    
    func receive() {
        webSocket?.receive(completionHandler: { [weak self] result in   //weak self : 메모리 누수 방지
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    print("Got Data: \(data)")
                case .string(let message):
                    print("Got String: \(message)")
                @unknown default:
                    break
                }
            case .failure(let error):
                print("Receive error: \(error)")
            }
            
            //receive를 계속 부를 것이기 때문에
            self?.receive()
        })
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Did connect to socket")
        ping()
        receive()
//        send()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Did close connection with reason \((reason))")
    }
    
}


extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)
        
        let message = messages[indexPath.row]
        cell.textLabel?.text = message
        
        return cell
    }
}
