# RKSocket

[![CI Status](https://img.shields.io/travis/chzy/RKSocket.svg?style=flat)](https://travis-ci.org/chzy/RKSocket)
[![Version](https://img.shields.io/cocoapods/v/RKSocket.svg?style=flat)](https://cocoapods.org/pods/RKSocket)
[![License](https://img.shields.io/cocoapods/l/RKSocket.svg?style=flat)](https://cocoapods.org/pods/RKSocket)
[![Platform](https://img.shields.io/cocoapods/p/RKSocket.svg?style=flat)](https://cocoapods.org/pods/RKSocket)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

RKSocket is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'RKSocket'
```

## Use
###详情参考demo
```
import RKSocket
var address = "wss://XXXX"
RKSocket.share.config(address)
RKSocket.share.openClient()
RKSocket.share.delegate = self
```

###消息回调
```
extension ViewController: RKSocketDelegate {
    func rkwebSocket(_ webSocket: RKSocket, didFailWithError error: Error) {
        
    }
    
    func rkwebSocketDidOpen(_ webSocket: RKSocket) {
        
    }
    
    func rkwebSocket(_ webSocket: RKSocket, didCloseWithCode code: Int, reason: String?, wasClean: Bool) {
        
    }
    
    func rkwebSocket(_ webSocket: RKSocket, didReceiveMessage message: Any) {
        print("didReceiveMessageWith message: \(message)")
    }
    
    func rkwebSocket(_ webSocket: RKSocket, didReceiveMessageWith data: Data) {
        
    }
    
    func rkwebSocket(_ webSocket: RKSocket, didReceiveMessageWith string: String) {
        print("didReceiveMessageWith: string " + string)
    }
    
    func rkwebSocket(_ webSocket: RKSocket, didReceivePingWith data: Data?) {
        
    }
    
    func rkwebSocket(_ webSocket: RKSocket, didReceivePong pongData: Data?) {
        
    }

}
```

## Author

chzy, yang.chunzhi@hotmail.com

## License

RKSocket is available under the MIT license. See the LICENSE file for more info.
