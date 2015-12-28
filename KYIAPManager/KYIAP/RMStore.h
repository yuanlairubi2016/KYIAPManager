//
//  Created by Hermes Pique on 12/6/09.
//  Copyright (c) 2013 Robot Media SL (http://www.robotmedia.net)
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

//交易失败block
typedef void (^RMSKPaymentTransactionFailureBlock)(SKPaymentTransaction *transaction, NSError *error);
//交易成功block
typedef void (^RMSKPaymentTransactionSuccessBlock)(SKPaymentTransaction *transaction);

//商品信息请求失败
typedef void (^RMSKProductsRequestFailureBlock)(NSError *error);
//商品信息请求成功
typedef void (^RMSKProductsRequestSuccessBlock)(NSArray *products, NSArray *invalidIdentifiers);


//
typedef void (^RMStoreFailureBlock)(NSError *error);
typedef void (^RMStoreSuccessBlock)();

//存储交易失败
typedef void (^RMStoreTransactionsFailureBlock)(NSError *error);
//存储交易成功
typedef void (^RMStoreTransactionsSuccessBlock)(NSArray *transactions);

@protocol RMStoreContentDownloader;
@protocol RMStoreReceiptVerifier;
@protocol RMStoreTransactionPersistor;
@protocol RMStoreObserver;

extern NSString *const RMStoreErrorDomain ;
extern NSInteger const RMStoreErrorCodeDownloadCanceled ;
extern NSInteger const RMStoreErrorCodeUnknownProductIdentifier ;
extern NSInteger const RMStoreErrorCodeUnableToCompleteVerification ;

@interface RMStore : NSObject<SKPaymentTransactionObserver>

+ (RMStore *)defaultStore;

+ (BOOL)canMakePayments;

#pragma mark - 请求商品信息
- (void)requestProducts:(NSSet*)identifiers;

- (void)requestProducts:(NSSet *)identifiers
                success:(RMSKProductsRequestSuccessBlock)successBlock
                failure:(RMSKProductsRequestFailureBlock)failureBlock;

#pragma mark - 发送购买请求
- (void)addPayment:(NSString *)productIdentifier;

- (void)addPayment:(NSString *)productIdentifier
           success:(RMSKPaymentTransactionSuccessBlock)successBlock
           failure:(RMSKPaymentTransactionFailureBlock)failureBlock;

- (void)addPayment:(NSString *)productIdentifier user:(NSString *)userIdentifier
           success:(RMSKPaymentTransactionSuccessBlock )successBlock
           failure:(RMSKPaymentTransactionFailureBlock) failureBlock __attribute__((availability(ios,introduced=7.0)));



//Request to restore previously completed purchases.
#pragma mark - 存储之前的购买
- (void)restoreTransactions;

- (void)restoreTransactionsOnSuccess:(RMStoreTransactionsSuccessBlock )successBlock
                             failure:(RMStoreTransactionsFailureBlock )failureBlock;

- (void)restoreTransactionsOfUser:(NSString *)userIdentifier
                        onSuccess:(RMStoreTransactionsSuccessBlock)successBlock
                           falure:(RMStoreTransactionsFailureBlock)failureBlock __attribute__((availability(ios,introduced=7.0)));

#pragma mark - Receipt and Refresh

+ (NSURL *)receiptURL __attribute__((availability(ios,introduced=7.0)));

- (void)refreshReceipt __attribute__((availability(ios,introduced=7.0)));

- (void)refreshReceiptOnSuccess:(RMStoreSuccessBlock)successBlock
                        failure:(RMStoreFailureBlock)failureBlock __attribute__((availability(ios,introduced=7.0)));



#pragma mark - Setting Delegates
/**
 The content downloader. Required to download product content from your own server.
 @discussion Hosted content from Apple’s server (SKDownload) is handled automatically. You don't need to provide a content downloader for it.
 */
@property(nonatomic, weak)id<RMStoreContentDownloader> contentDownloader;
@property(nonatomic, weak)id<RMStoreReceiptVerifier>receiptVerfier;
@property(nonatomic, weak)id<RMStoreTransactionPersistor>transactionPersistor;


#pragma mark - managerment and 格式化

- (SKProduct *)productForIdentifier:(NSString *)productIdentifier;

+ (NSString *)localizedPriceOfProduct:(SKProduct *)product;

#pragma mark - Notification
- (void)addStoreObserver:(id<RMStoreObserver>)observer;

- (void)removeStoreObserver:(id<RMStoreObserver>)observer;

@end

#pragma mark - RMStoreContentDownloader
@protocol RMStoreContentDownloader <NSObject>

/**
 Downloads the self-hosted content associated to the given transaction and calls the given success or failure block accordingly. Can also call the given progress block to notify progress.
 @param transaction The transaction whose associated content will be downloaded.
 @param successBlock Called if the download was successful. Must be called in the main queue.
 @param progressBlock Called to notify progress. Provides a number between 0.0 and 1.0, inclusive, where 0.0 means no data has been downloaded and 1.0 means all the data has been downloaded. Must be called in the main queue.
 @param failureBlock Called if the download failed. Must be called in the main queue.
 @discussion Hosted content from Apple’s server (@c SKDownload) is handled automatically by RMStore.
 */

- (void)downloadContentForTransaction:(SKPaymentTransaction *)transaction
                              success:(void(^)())successBlock
                             progress:(void(^)(float progress))progressBlock
                              failure:(void(^)(NSError *error))failureBlock;


@end
#pragma mark - RMStoreTransactionPersistor
@protocol RMStoreTransactionPersistor <NSObject>

- (void)persistTransaction:(SKPaymentTransaction *)transaction;

@end

#pragma mark - RMStoreReceiptVerifier

@protocol RMStoreReceiptVerifier <NSObject>

- (void)verifyTransaction:(SKPaymentTransaction *)transaction
                  success:(void(^)())successBlock
                  failure:(void(^)(NSError *error)) failureBlock;

@end

#pragma mark - RMStoreObserver

@protocol RMStoreObserver <NSObject>

@optional

- (void)storeDownloadCanceled:(NSNotification *) notification __attribute__((availability(ios,introduced=6.0)));
- (void)storeDownloadFailed:(NSNotification *) notification;
- (void)storeDownloadFinished:(NSNotification *) notification;
- (void)storeDownloadPaused:(NSNotification *) notification;
- (void)storeDownloadUpdated:(NSNotification *) notification;

- (void)storePaymentTransactionDeferred:(NSNotification *)notification __attribute__((availability(ios,introduced=6.0)));
- (void)storePaymentTransactionFailed:(NSNotification *)notification;
- (void)storePaymentTransactionFinished:(NSNotification *)notification;

- (void)storeProductsRequestFailed:(NSNotification *)notification;
- (void)storeProductsRequestFinished:(NSNotification *)notification;

- (void)storeRefreshReceiptFailed:(NSNotification *)notification __attribute__((availability(ios,introduced=7.0)));
- (void)storeRefreshReceiptFinished:(NSNotification *)notification __attribute__((availability(ios,introduced=7.0)));

- (void)storeRestoreTransactionsFailed:(NSNotification *)notification;
- (void)storeRestoreTransactionsFinished:(NSNotification *)notification;


@end

#pragma mark - NSNotification

@interface NSNotification(RMStore)

//
@property (nonatomic, readonly) float rm_downloadProgress;
@property (nonatomic, readonly) NSArray *rm_invalidProductIdentifiers;
@property (nonatomic, readonly) NSString *rm_productIdentifier;
@property (nonatomic, readonly) NSArray *rm_products;
@property (nonatomic, readonly) SKDownload *rm_storeDownload __attribute__((availability(ios,introduced=6.0)));
@property (nonatomic, readonly) NSError *rm_storeError;
@property (nonatomic, readonly) SKPaymentTransaction *rm_transaction;
@property (nonatomic, readonly) NSArray *rm_transactions;

@end