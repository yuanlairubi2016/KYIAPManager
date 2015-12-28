//
//  KYIAPManager.m
//  KYIAPManager
//
//  Created by bruce on 15/11/24.
//  Copyright © 2015年 KY. All rights reserved.
//
//  support iOS6 or later 
//  地址是自己的服务器
#define ORDERIDGETURL           @"http://104.131.159.174/shop/index.php/API/PayIAP/iapOrderID"
#define RECEIPTPOSTURL          @"http://104.131.159.174/shop/index.php/API/PayIAP/receipt"

#define ORDERIDKEY              @"order_id"
#define PRODUCTIDKEY            @"product_id"
#define RECEIPTKEY              @"receipt"
#define TRANSACTIONKEY          @"transaction"


#import "KYIAPManager.h"
#import "NSData+Base64.h"
#import "HTTPNSURLConnection.h"
#import "KYIAPPlist.h"

@interface KYIAPManager()<SKProductsRequestDelegate,SKRequestDelegate,SKPaymentTransactionObserver>

@property(nonatomic, strong)NSArray *products;      //商品信息列表
@property(nonatomic, strong)SKProduct *product;     //单个商品信息
@property(nonatomic, assign)NSUInteger quantity;    //购买数量
@property(nonatomic, strong)NSString *productId;    //购买id
@property(nonatomic, strong)NSString *callBackInfo; //回调信息
@property(nonatomic, assign)BOOL isBuying;          //每次只能购买一个   ---是否在购买过程中？,,确保购买的时候没有其他购买

@end

@implementation KYIAPManager


//返回单例,方便调用。
+ (KYIAPManager *)shareInstance {
    static KYIAPManager *mInstance = nil;
    static dispatch_once_t onceTokenKYIAPManager;
    dispatch_once(&onceTokenKYIAPManager, ^{
        mInstance = [[[self class] alloc] init];
    });
    return mInstance;
}

- (instancetype)init {
    
    if(self = [super init]){
        self.isBuying = NO;
    }
    return self;
}

//添加观察者
- (void)addIAPObserver {
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

//是否允许应用内付费
- (BOOL)canMakePayments {
    return [SKPaymentQueue canMakePayments];
}

//删除本地订单
- (void)removeQueueTransactions {
    NSArray<SKPaymentTransaction *> *transactions = [SKPaymentQueue defaultQueue].transactions;
    for(SKPaymentTransaction *transaction in transactions) {
        NSLog(@"transaction.payment.applicationUsername = %@",transaction.payment.applicationUsername);
        NSLog(@"transaction.transactionState = %zd",transaction.transactionState);
        if(transaction.transactionState == SKPaymentTransactionStatePurchased) {//1表示购买完成
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
    }
}

//刷新flesh
- (void)refleshIAP {
    //iOS7之后
    if(ISIOS7H){
        SKReceiptRefreshRequest *request = [[SKReceiptRefreshRequest alloc] init];
        request.delegate = self;
        [request start];
    }
}

#pragma mark - 获取产品信息列表
//初始化商品id列表，用于请求产品信息
- (void)requestProductWithIdentifiers:(NSSet *)productIdentifiers {
    SKProductsRequest * request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    request.delegate = self;
    [request start];
}

//商品信息－请求成功
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    if(response.products && response.products.count>0){
        
        self.products = response.products;
        
        NSLog(@"商品信息请求成功 = %@",self.products);
        if(self.kyIAPPurchaseDelegate && [self.kyIAPPurchaseDelegate respondsToSelector:@selector(kyProductInfo:)] ){
            [self.kyIAPPurchaseDelegate kyProductInfo:self.products];
        }
    }else{
        NSLog(@"商品信息为空，应该是productid或者boundle identifier 不对应");
    }
}


//商品信息－请求结果失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"商品信息请求失败 = %@",error);
}

#pragma mark - 用户购买产品

//购买请求
- (void)buyWithProductId:(NSString *)productId andQuantity:(NSUInteger )quantity andCallbackInfo:(NSString *)callbackInfo{
    
    if(self.isBuying){//一次只能购买一个
        return;
    }
    self.isBuying = YES;
    //每次下单都重新发送请求
    
    self.quantity = quantity;
    self.productId = productId;
    self.callBackInfo = callbackInfo;
    
    //1、获取对应的product
    for(SKProduct *pro in _products){
        if(pro.productIdentifier && [pro.productIdentifier isEqual:productId]){
            self.product = pro;
            break;
        }
    }
    
    //2、向平台发送请求、获取我们自己服务器的订单号
    NSString *urlString = [NSString stringWithFormat:@"%@?productID=%@",ORDERIDGETURL, productId];
    [HTTPNSURLConnection getRequestWithURL:urlString paramters:nil finshedBlock:^(BOOL isSuccess, NSDictionary *resultDic) {
        if(!isSuccess){
            self.isBuying = NO;
            return ;
        }
        NSString *code = [resultDic objectForKey:@"code"];
        if(code && [code isEqualToString:@"0"]){
            //请求完成后使用
            NSString *orderID = resultDic[@"result"][@"orderID"];
            NSLog(@"==============请求的到的orderID==============:%@",orderID);
            if(orderID){//订单请求成功后发送购买请求
                [self buyProduct:_product andQuantity:_quantity andOrderID:orderID];//1表示购买数
            }else{
                NSLog(@"获取订单失败");
                self.isBuying = NO;
            }
        }else{
            NSLog(@"获取订单失败");
            self.isBuying = NO;
        }
    }];
    
    
}

- (void)buyProduct:(SKProduct *)product andQuantity:(NSInteger)quantity andOrderID:(NSString *)orderID{
    NSLog(@"购买：productid: %@",product.productIdentifier);
    if(self.quantity<1){
        self.quantity = 1;
    }
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.quantity = self.quantity;
    
    if (ISIOS7H){
        payment.applicationUsername = orderID;//这个是iOS7之后提供的方法
    }else{
        //iOS6以及之前的方式
        //一product。productIdentifier 作为key值保持订单，即使订单号和真正的订单不对应，也可以保证价格不会出错
        NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:orderID,product.productIdentifier, nil];
        [[KYIAPPlist shareInstance] writeToPlist:KYIAPPLIST andParams:dic];
    }

    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

//SKPaymentTransactionOBserver,购买的回调函数。
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction * transaction in transactions) {
        switch (transaction.transactionState)
        {
                //交易完成
            case SKPaymentTransactionStatePurchased:{
                [self completeTransactionIn:transaction];
                break;
            }
                //交易失败
            case SKPaymentTransactionStateFailed:{
                [self failedTransactionIn:transaction];
                break;
            }
                //已经购买过该商品，NOTE: consumble payment is NOT restorable
            case SKPaymentTransactionStateRestored:{
                [self restoreTransactionIn:transaction];
                break;
            }
                //商品添加进列表
            case SKPaymentTransactionStatePurchasing:{
                [self purchasingTransactionIn:transaction];
                break;
            }
            default:{
                break;
            }
        }
    }
}

//交易完成
- (void)completeTransactionIn:(SKPaymentTransaction *)transaction {
    NSLog(@"用户支付完成");
    //3、告诉我们的服务器购买完成了，用户支付完成
    [self sendToService:transaction];
    
    if(self.kyIAPPurchaseDelegate && [self.kyIAPPurchaseDelegate respondsToSelector:@selector(kyCompleteTransactionIn:)] ){
        [self.kyIAPPurchaseDelegate kyCompleteTransactionIn:transaction];
    }
    
}

//交易失败
- (void)failedTransactionIn:(SKPaymentTransaction *)transaction {
    NSLog(@"交易失败:%@",transaction.error);
    
    if(self.kyIAPPurchaseDelegate && [self.kyIAPPurchaseDelegate respondsToSelector:@selector(kyFailedTransactionIn:)] ){
        [self.kyIAPPurchaseDelegate kyFailedTransactionIn:transaction];
    }
    
    self.isBuying = NO;
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

//
- (void)restoreTransactionIn:(SKPaymentTransaction *)transaction {
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
//    SKPaymentTransactionStateRestored  非消耗性商品已经购买过，这时我们要按交易成功来处理。
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

//商品添加进购买队列
- (void)purchasingTransactionIn:(SKPaymentTransaction *)transaction{
    NSLog(@"商品添加进购买列表");
}

//根据UserName去取
- (void)restoreCompletedTransactionsWithApplicationUsername:(nullable NSString *)username {
    
}

#pragma mark - 发送 === 验证信息 ===到起点的服务的方法
- (void)sendToService:(SKPaymentTransaction *)transaction{
    NSString *receipt = [self receipt:transaction];
    //把base64加密后的数据数据对应订单号 发送给服务器
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    NSString *orderID = @"";
    if (ISIOS7H){
         orderID = transaction.payment.applicationUsername;//这个是iOS7之后提供的方法
    }else{
        orderID = [[KYIAPPlist shareInstance] readFromPlist:KYIAPPLIST andKey:transaction.payment.productIdentifier];
    }
    
    NSLog(@"==============用户支付完成的orderID==============:%@",orderID);

    
    if(orderID){
        [dic setObject:orderID forKey:ORDERIDKEY];
    }
    if(receipt){
        [dic setObject:receipt forKey:RECEIPTKEY];
    }
    if(transaction.payment.productIdentifier){
        [dic setObject:transaction.payment.productIdentifier forKey:PRODUCTIDKEY];
    }
    if(transaction){
        [dic setObject:transaction forKey:TRANSACTIONKEY];
    }
    
    [self sendReceiptToServer:dic];

}


- (void)sendReceiptToServer:(NSDictionary *)dic {
    
    SKPaymentTransaction *transaction = [dic objectForKey:TRANSACTIONKEY];
    NSString *receipt = [dic objectForKey:RECEIPTKEY];
    if(!receipt || !transaction){
        return;
    }
    //不用把transaction 发送到服务器，把receipt发送到服务器就好了
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithDictionary:dic];
    [mutableDic removeObjectForKey:TRANSACTIONKEY];
    
    //5、发送receipt
    [HTTPNSURLConnection postRequestWithURL:RECEIPTPOSTURL paramters:mutableDic finshedBlock:^(BOOL isSuccess, NSDictionary *resultDic) {
        self.isBuying = NO;
        if(!isSuccess){
            return ;
        }
        NSString *code = [resultDic objectForKey:@"code"];
        NSLog(@"resultDic = %@",resultDic);
        if(code && [code isEqualToString:@"0"]){//表示请求有到达服务器
            //请求完成后使用
            NSLog(@"下发成功");
            //移除plist中记录的内容
        }
        
        //注意：只有在服务器端明确返回收到客户端返回信息的时候 删除
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }];
}

#pragma mark - receipt

- (NSString *)receipt:(SKPaymentTransaction *)transaction {
    //receipt不同的获取方式。
    NSString *receipt = @"";
    NSData *data = nil;
    //    // iOS 7 or later.
    NSURL *receiptFileURL = nil;
    NSBundle *bundle = [NSBundle mainBundle];
    if ([bundle respondsToSelector:@selector(appStoreReceiptURL)]) {
        // Get the transaction receipt file path location in the app bundle.
        receiptFileURL = [bundle appStoreReceiptURL];
        data  = [NSData  dataWithContentsOfURL:receiptFileURL];
        //        receipt = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
        receipt = [data base64EncodedString];
        
    }else{
        data = [[NSData alloc] initWithData:transaction.transactionReceipt];
        receipt = [data base64EncodedString];
    }

    //base64EncodedString 加密后的。
    receipt = [receipt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //去除掉首尾的空白字符和换行字符
    receipt = [receipt stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    receipt = [receipt stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    return receipt;
}
@end
