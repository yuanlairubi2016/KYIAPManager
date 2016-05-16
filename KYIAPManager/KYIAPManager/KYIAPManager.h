//
//  KYIAPManager.h
//  KYIAPManager
//
//  Created by bruce on 15/11/24.
//  Copyright © 2015年 KY. All rights reserved.
//
//  support iOS6 or later

#import <StoreKit/StoreKit.h>
#pragma mark 购买结果协议

#define ISIOS7H ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)

@protocol KYIAPDelegate <NSObject>

@optional
/**
 *  @brief 获取商品信息
 */
- (void)kyProductInfo:(NSArray *)products;

/**
 *  @brief 获取订单号失败
 */
- (void)kyGetOrderIdError:(NSError *)error;

/**
 *  @brief 交易(付款)完成
 */
- (void)kyCompleteTransactionIn:(SKPaymentTransaction *)transaction;

/**
 *  @brief 交易（付款）失败
 */
- (void)kyFailedTransactionIn:(SKPaymentTransaction *)transaction;


@required

/**
 *  @brief 物品发放结果
 */
- (void)didFinishedPayment:(id)result;

/**
 *  @brief 购买失败
 *
 *  @param error:错误信息描述
 *
 */
- (void)didFailedWithError:(NSError *)error;

@end

@interface KYIAPManager : NSObject


@property(nonatomic, strong)NSArray *products;

/**
 * @brief:获取单例
 */
+ (KYIAPManager *)shareInstance;

/**
 *  @brief:添加观察者,建议在delegate中的didFinishLaunchingWithOptions  调用。
 *
 */
- (void)addIAPObserver;


/**
 *  @brief:删除本地订单
 *
 */
- (void)removeQueueTransactions;


/**
 *  @brief 判断是否允许应用内付费
 *
 */
- (BOOL)canMakePayments;

/**
 * @brief 初始化产品id列表，用于请求产品信息
 */
- (void)requestProductWithIdentifiers:(NSSet *)productIdentifiers;

/**
 * @brief 初始化产品id列表，用于请求产品信息
 */
- (void)requestProductWithIdentifiers:(NSSet *)productIdentifiers andDelegate:(id<KYIAPDelegate>)delegate;

/**
 *  @brief  请求订单 和上面的方法功能一致，多了个回调信息
 *
 *  @param  productId:产品ID
 *  @param  quantity:购买数量
 *  @param  callbackInfo:可以为nil，回调信息，
 *  @param  回调delegate
 */
- (void)buyWithProductId:(NSString *)productId andQuantity:(NSUInteger )quantity andCallbackInfo:(NSString*)callbackInfo andDelegate:(id<KYIAPDelegate>)delegate;


@end
