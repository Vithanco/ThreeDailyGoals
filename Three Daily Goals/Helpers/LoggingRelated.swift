//
//  LoggingRelated.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 12/01/2024.
//


import Logging

public typealias LogType = Logger.Level

private func getLogger() -> Logger {
    var result = Logger(label: "com.vithanco.3dg")
    
#if DEBUG
    result.logLevel = .debug
#else
    result.logLevel = .info
#endif
    
    return result
}


fileprivate let logger = getLogger()

public extension Logger {
    init(label: String, level: LogType) {
        self.init(label: label)
        self.logLevel = level
    }
    
    func error(error:Error) {
        self.error("\(error.localizedDescription)")
    }
    
    
    func logThis(_ type: LogType, _ text: String, uiText: String? = nil) {
        if #available(macOS 10.14, *) {
            switch type {
                case .debug,.trace:
                    self.debug("\(text)")
                case .info, .notice:
                    self.info("\(text)")
                case .warning:
                    self.warning("\(text)")
                case .error, .critical:
                    self.error("\(text)")
            }
        } else {
            Swift.print("\(type): \(text)")
        }
//        DispatchQueue.main.async {
//            let showText = uiText ?? text
//            if let bottomBar = vtApp().currentCanvasView()?.bottomBar {
//                switch type {
//                    case .info,.notice:
//                        bottomBar.stringValue = showText
//                        bottomBar.textColor = NSColor.gray
//                    case .warning:
//                        bottomBar.stringValue = showText
//                        bottomBar.textColor = rgb(153, 153, 0)
//                        Swift.print(text)
//                    case .error, .critical:
//                        bottomBar.stringValue = showText
//                        bottomBar.textColor = NSColor.systemRed
//                        Swift.print(text)
//                    case .debug, .trace :
//                        break
//                }
//            }
//        }
    }
}

extension Error {
    public func log() {
        logger.logThis(.error, self.localizedDescription)
    }
}
