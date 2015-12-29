iOS6 or later

流程

我们这边的流程：
1、手机端向服务器发送订单请求（生成我们自己的订单号）
2、向苹果发送购买请求、且把自己的订单赋值给payment.applicationUsername （iOS7之后）
iOS6之前的通过Plist文件记录订单号对应的productIdentifier。
3、用户支付完成（网上很多例子在这边调用finishTransaction、会造成一定量的漏单）
4、把receipt和自己的订单号发送到自己的服务器验
5、服务端向苹果发送验证
6、本地收到服务端确定收到receipt的信息、及物品是否下发、调用结束购买[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
注释：

1、自己的订单号：是根据苹果的productid和服务端其他一些信息制作而成，通过productid可以知道用户购买的时间和物品。 2、finishTransaction：没有调用之前，成功购买的订单会一直留在[SKPaymentQueue defaultQueue]，且每次应用进入前台，都会调用支付完成的流程（前提是注册了addTransactionObserver 的观察者）。 苹果建议在物品真正发放后在调用finishTransaction。 【https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/DeliverProduct.html#//apple_ref/doc/uid/TP40008267-CH5-SW10】