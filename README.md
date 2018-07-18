


### iOS 内购（ IAP）处理流程， 漏单

<font size=3 color="#116611">最重要的一点:在确认服务端收到receipt之前不要结束订单（不要调用[[SKPaymentQueue defaultQueue] finishTransaction:transaction];）</font>

这边介绍的是receipt在服务端验证的内购

### 漏单

>漏单：正常玩家购买了却没有收到物品、且自己的服务端没有任何记录iOS的订单。iOS的补单是非常麻烦的，用户提供支付的截图中的订单号我们又不能在itunes 或者其他地方找到相应的订单号。有的玩家还会ps...

### 购买步骤


- 1、手机端向服务器发送订单请求（生成我们自己的订单号）
- 2、向苹果发送购买请求、且把自己的订单赋值给payment.applicationUsername （iOS7之后）
- 3、用户支付完成（网上很多例子在这边调用finishTransaction、会造成一定量的漏单）
- 4、把receipt和自己的订单号发送到自己的服务器验
- 5、服务端向苹果发送验证
- 6、手机端收到服务端确定收到receipt的信息、及物品是否下发、调用结束购买[[SKPaymentQueue defaultQueue] finishTransaction:transaction];


### 注意：

- 1、自己的订单号：是根据苹果的productid和服务端其他一些信息制作而成，通过productid可以知道用户购买的时间、价格、物品等信息
- 2、finishTransaction：没有调用之前，成功购买的订单会一直留在[SKPaymentQueue defaultQueue]，且每次应用进入前台，都会调用支付完成的流程（前提是注册了addTransactionObserver 的观察者）。
苹果建议在物品真正发放后在调用finishTransaction。
[详情链接](https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/DeliverProduct.html#//apple_ref/doc/uid/TP40008267-CH5-SW10)
- 3、流程中第2步，iOS6是不能使用payment.applicationUsername，我这边是这样子处理把自己的orderid和productIdentifier存于一个自定义的plist文件中。验证成功或者失败就移除，其他情况就保存。
- 4、在购买的过程中（从用户发起购买请求到用户收到物品），只有一个订单在处理中，即用户完成了一单才再能购买下一单。
- 5、现在从后台的记录看，iOS6用户的充值是非常的少，（2015年12月29日）近3个月已经没有iOS6版本充值了记录了。

### 服务器端注意事项

> 服务端需要处理一个receipt中携带了多个未处理的订单，即在in-app中有多个支付记录。   
虽然按正常逻辑，一次只会处理一笔支付，在漏掉以前充值订单的情况下，一个receipt，可能含有多个购买记录，这些记录可能就是没有下发给用户的，需要对receipt 的 in-app记录逐条检查，根据订单记录查看某一单是否已经下发过了。

-----
> 2016年02月24日16:00:26更新
按上面支付流程上线后，发现还有问题，就是步骤第2步的时候，把自己的订单号存在payment.applicationUsername，
有一些特殊情况会导致payment.applicationUsername为空，[这里](https://forums.developer.apple.com/thread/14136)有人碰到过，我发现我们的后台日志也有这种情况，这就需要在payment.applicationUsername为空的时候，使用其他方式获取刚刚从服务器获取的订单号
或者重新请求自己的服务端重新生成订单号。

-----
### 一些参考地址

[[In-App Purchase Programming Guide]](https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/Restoring.html#//apple_ref/doc/uid/TP40008267-CH8-SW2)

[\[In-App Purchase Best Practices\]](https://developer.apple.com/library/ios/technotes/tn2387/_index.html)


[\[Receipt Fields\]](https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html#//apple_ref/doc/uid/TP40010573-CH106-SW1)


[\[in-app is empty\]](https://forums.developer.apple.com/thread/8954)




[Adding In-App Purchase to your Applications](https://developer.apple.com/library/content/technotes/tn2259/_index.html)

[[In-App Purchase FAQ]](https://developer.apple.com/library/ios/technotes/tn2413/_index.html#//apple_ref/doc/uid/DTS40016228-CH1-TNTAG1)

-----
>如果有朋友有比较好的建议，请告诉我下





