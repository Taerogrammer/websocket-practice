//
//  ViewController.swift
//  WebSocketExample
//
//  Created by KimTaeHyung on 2023/06/25.
//

import UIKit

class ViewController: UIViewController {
    
    //MARK: - Components
    
    private var webSocket: URLSessionWebSocketTask?     //웹소켓 생성
    
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
        
        setWebSocketSession()
        
        setLayout()
        
        setTableView()

    }
    
}


//MARK: - Table View Extension

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

//MARK: - methods extension (레이아웃 관련)

extension ViewController {
    
    private func setTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CellIdentifier")
        tableView.frame = CGRect(x: 0, y: sendButton.frame.maxY + 10, width: view.bounds.width, height: view.bounds.height - sendButton.frame.maxY - 10)
        tableView.backgroundColor = .red
        tableView.delegate = self
        tableView.dataSource = self
        // tableView의 설정 (예: delegate, dataSource, cell 등)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setLayout() {
        setTextField()
        setCloseButton()
        setSendButton()
        
    }
    
    private func setTextField() {
        textField.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
        textField.center = CGPoint(x: view.center.x, y: closeButton.frame.maxY + textField.frame.height/2 + 100)
        textField.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(textField)
    }
    
    private func setCloseButton() {
        closeButton.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeButton.center = view.center
    }
    
    private func setSendButton() {
        sendButton.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        sendButton.addTarget(self, action: #selector(send), for: .touchUpInside)
        view.addSubview(sendButton)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.center = CGPoint(x: closeButton.center.x, y: closeButton.frame.maxY + sendButton.frame.height/2 + 10)
    }
    
}

//MARK: - websocket Extension

extension ViewController: URLSessionWebSocketDelegate {
    
    
    //Websocket은 연결되어 있어야하고 계속적으로 반응할 준비가 되어 있어야 함
    private func setWebSocketSession() {
        let session = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: OperationQueue()  //.main큐에 넣어도 되지만, UI를 다루는 큐에 한 번에 넣지 않고 새로운 큐를 생성한 것
        )
        
        //piesocket API
//        let url = URL(string: "wss://s9309.blr1.piesocket.com/v3/1?api_key=cZGOksfuE6CqV1cZfly2CnFBqbE33D1UBzTWgUvd&notify_self=1")
        let url = URL(string: "ws://localhost:1337/")   //웹소켓 url은 http나 https를 사용하지 않고, ws나 wss 사용
        webSocket = session.webSocketTask(with: url!)
        webSocket?.resume()
    }
    
    //ping을 통해 webSocket이 잘 연결되고 있는지 확인, 연결을 하려면 connection이 되어 있어야 하는데, 이를 확인함
    func ping() {
        webSocket?.sendPing { error in
            if let error = error {
                print("Ping error: \(error)")
            }
        }
    }
    
    @objc func close() {
        webSocket?.cancel(with: .goingAway, reason: "Demo ended".data(using: .utf8))    //connection이 끝났을 때 대한 이유

    }
    
    //메세지 보내기
    @objc func send() {

        guard let newMessage = textField.text, !newMessage.isEmpty else { return }

        self.webSocket?.send(.string(newMessage), completionHandler: { error in
            if let error = error {
                print("send error: \(error)")
            }
        })
    }
    
    //지속적으로 이 receive 함수를 받기 때문에 계속해서 값을 받아야 함
    func receive() {
        webSocket?.receive(completionHandler: { [weak self] result in   //weak self : 메모리 누수 방지
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    print("Got Data: \(data)")
                case .string(let message):
                    print("Got String: \(message)")
                    self?.handleReceivedMessage(message)
                
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

    private func handleReceivedMessage(_ message: String) {
        print("handleMessage called()")
        if let data = message.data(using: .utf8),
           let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let dataArray = jsonData["data"] as? [[String: Any]] {
           print("--------------------------")
            for dataItem in dataArray {
                if let timeValue = dataItem["time"] as? TimeInterval,
                   let textValue = dataItem["text"] as? String,
                   let authorValue = dataItem["author"] as? String,
                   let colorValue = dataItem["color"] as? String {
                    
                    let item = "\(timeValue), \(textValue), \(authorValue), \(colorValue)"
                    print("item -> \(item)")
                    self.messages.append(item)
                }
            }
            handleReceivedMessageCallback()
        } else {
            print("else문")
            if let data = message.data(using: .utf8),
               let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let dataObject = jsonData["data"] as? [String: Any] {
                
                if let timeValue = dataObject["time"] as? TimeInterval,
                   let textValue = dataObject["text"] as? String,
                   let authorValue = dataObject["author"] as? String,
                   let colorValue = dataObject["color"] as? String {
                    
                    let item = "\(timeValue), \(textValue), \(authorValue), \(colorValue)"
                    print("item -> \(item)")
                    self.messages.append(item)
                    handleReceivedMessageCallback()
                }
            }
        }
    }
    
    // 메시지를 받았을 때 호출되는 콜백 메서드
    private func handleReceivedMessageCallback() {
        print("callBack called()")
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
            let indexPath = IndexPath(row: (self?.messages.count ?? 0) - 1, section: 0)
            self?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    //URLSessionWebSocketDelegate - 웹소켓 open
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Did connect to socket")
        ping()
        receive()
//        send()
    }
    
    //URLSessionWebSocketDelegate - 웹소켓 close
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Did close connection with reason \((reason)!)")
    }
    
}
