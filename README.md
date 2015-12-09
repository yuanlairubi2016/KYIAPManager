### KYIAPManager

iOS6 or later

过程：
>向服务器请求订单

>向苹果发送购买请求

>购买完成后本地记录订单的receipt，发送receipt到服务器端

>收到服务器端的结果（物品下发或其他的）移除本地记录的receipt，结束本次购买请求
>[[SKPaymentQueue defaultQueue] finishTransaction: transaction];

