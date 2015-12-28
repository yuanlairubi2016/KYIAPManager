//
//  Created by Hermes Pique on 12/6/09.
//  Copyright (c) 2013 Robot Media SL (http://www.robotmedia.net)
//

#import "RMStore.h"

NSString *const RMStoreErrorDomain = @"net.robotmedia.store";
NSInteger const RMStoreErrorCodeDownloadCanceled = 300;
NSInteger const RMStoreErrorCodeUnknownProductIdentifier = 100;
NSInteger const RMStoreErrorCodeUnableToCompleteVerification = 200;

NSString *const RMSKDownloadCanceled = @"KYSKDownloadCancled";
NSString *const RMSKDownloadFailed = @"KYSKDownloadfailed";
NSString *const RMSKDownloadFinished = @"KYSKDownloadfinished";
NSString *const RMSKDownloadPaused = @"KYSKDownloadPaused";
NSString *const RMSKDownloadUpdated = @"KYSKDownloadUpdated";

NSString *const RMSKPaymentTransactionDeferred = @"KYSKPaymentTransactionDeferred";
NSString *const RMSKPaymentTransactionFailed = @"KYSKPaymentTransactionFailed";
NSString *const RMSKPaymentTransactionFinished = @"KYSKPaymentTransactionFinished";

NSString *const RMSKProductsRequestFailed = @"KYSKProductsRequestFailed";
NSString *const RMSKProductsRequestFinished = @"KYSKProductsRequestFinished";

NSString *const RMSKRefreshReceiptFailed = @"KYSKRefreshReceiptFailed";
NSString *const RMSKRefreshReceiptFinished = @"KYSKRefreshReceiptFinished";

NSString *const RMSKRestoreTransactionsFailed = @"KYSKRestoreTransactionsFailed";
NSString *const RMSKRestoreTransactionsFinished = @"KYSKRestoreTransactionsFinished";

NSString *const RMStoreNotificationInvalidProductIdentifiers = @"KYIAPNotificationInvalidProductIdentifiers";
NSString *const RMStoreNotificationDownloadProgress = @"KYIAPNotificationDownloadProgress";
NSString *const RMStoreNotificationProductIdentifier = @"KYIAPNotificationProductIdentifier";
NSString *const RMStoreNotificationProducts = @"KYIAPNotificationProducts";
NSString *const RMStoreNotificationStoreDownload = @"KYIAPNotificationStoreDownload";
NSString *const RMStoreNotificationStoreError = @"KYIAPNotificationStoreError";
NSString *const RMStoreNotificationStoreReceipt = @"KYIAPNotificationStoreReceipt";
NSString *const RMStoreNotificationTransaction = @"KYIAPNotificationTransaction";
NSString *const RMStoreNotificationTransactions = @"KYIAPNotificationTransactions";

#if DEBUG
//#define RMStoreLog(...) NSLog(@"RMStore: %@", [NSString stringWithFormat:__VA_ARGS__]);

#define RMStoreLog(...) NSLog(@"KYIAP: %@",[NSString stringWithFormat:__VA_ARGS__])
//#define RMStoreLog(...) NSLog(@"RMStore: %@", [NSString stringWithFormat:__VA_ARGS__]);

#else
#define RMStoreLog(...)
#endif




@implementation NSNotification(RMStore)

- (float)rm_downloadProgress {
    return [self.userInfo[RMStoreNotificationDownloadProgress] floatValue];
}

- (NSArray *)rm_invalidProductIdentifiers {
    return self.userInfo[RMStoreNotificationInvalidProductIdentifiers];
}

- (NSString *)rm_productIdentifier{
    return self.userInfo[RMStoreNotificationProductIdentifier];
}

- (NSArray *)rm_products {
    return self.userInfo[RMStoreNotificationProducts];
}

- (SKDownload *)rm_storeDownload {
    return self.userInfo[RMStoreNotificationStoreDownload];
}

- (NSError *)rm_storeError {
    return self.userInfo[RMStoreNotificationStoreError];
}

- (SKPaymentTransaction *)rm_transaction {
    return self.userInfo[RMStoreNotificationTransaction];
}

- (NSArray *)rm_transactions {
    return self.userInfo[RMStoreNotificationTransactions];
}

@end

@interface RMProductsRequestDelegate : NSObject<SKProductsRequestDelegate>

@property(nonatomic, strong) RMSKProductsRequestSuccessBlock successBlock;
@property(nonatomic, strong) RMSKProductsRequestFailureBlock failureBlock;
@property(nonatomic, weak) RMStore *store;

@end


@interface RMAddPaymentParameters : NSObject

@property(nonatomic, strong) RMSKPaymentTransactionFailureBlock failureBlock;
@property(nonatomic, strong) RMSKPaymentTransactionSuccessBlock successBlock;

@end

@implementation RMAddPaymentParameters


@end

@interface RMStore()<SKRequestDelegate>

@end

@implementation RMStore {
    NSMutableDictionary *_addPaymentParameters;
    NSMutableDictionary *_products;
    NSMutableSet *_productsRequestDelegates;
    NSMutableArray *_restoredTransactions;
    
    NSInteger _pendingRestoredTransactionsCount;
    BOOL _restoredCompletedTransactionsFinished;
    
    SKReceiptRefreshRequest *_refreshReceiptRequest;
    void (^_refreshReceiptFailureBlock)(NSError * error);
    void (^_refreshReceiptSuccessBlock)();
    
    void (^_restoreTransactionsFailureBlock)(NSError *error);
    void (^_restoreTransactionsSuccessBlock)(NSArray *transactions);
}

- (instancetype)init {
    if(self = [super init]) {
        _addPaymentParameters = [NSMutableDictionary dictionary];
        _products = [NSMutableDictionary dictionary];
        _productsRequestDelegates = [NSMutableSet set];
        _restoredTransactions = [NSMutableArray array];
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
    }
    
    return self;
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}



+ (RMStore *)defaultStore {
    static RMStore *shareInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[[self class] alloc] init];
    });
    
    return shareInstance;
}


#pragma mark - StoreKit wrapper

+ (BOOL)canMakePayments {
    return [SKPaymentQueue canMakePayments];
}

- (void)addPayment:(NSString *)productIdentifier {
    [self addPayment:productIdentifier success:nil failure:nil];
}

- (void)addPayment:(NSString *)productIdentifier
           success:(RMSKPaymentTransactionSuccessBlock)successBlock
           failure:(RMSKPaymentTransactionFailureBlock)failureBlock {
    [self addPayment:productIdentifier user:nil success:nil failure:nil];
}

- (void)addPayment:(NSString *)productIdentifier user:(NSString *)userIdentifier
           success:(RMSKPaymentTransactionSuccessBlock )successBlock
           failure:(RMSKPaymentTransactionFailureBlock) failureBlock {
    SKProduct *product = [self productForIdentifier:productIdentifier];
    
    if(product == nil){
        RMStoreLog(@"unknown product id %@", productIdentifier);
        if(failureBlock != nil) {
            NSError *error = [NSError errorWithDomain:RMStoreErrorDomain code:RMStoreErrorCodeUnknownProductIdentifier userInfo:@{NSLocalizedDescriptionKey:NSLocalizedStringFromTable(@"Unknown product indentifier", @"RMStore", @"Error description")}];
            
            failureBlock(nil, error);
        }
        return ;
    }
    
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    if([payment respondsToSelector:@selector(setApplicationUsername:)]) {
        payment.applicationUsername = userIdentifier;
    }
    
    RMAddPaymentParameters *parameters = [[RMAddPaymentParameters alloc] init];
    parameters.successBlock = successBlock;
    parameters.failureBlock = failureBlock;
    
    _addPaymentParameters[productIdentifier] = parameters;
    
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
    
}


#pragma mark - product 购买
- (void)requestProducts:(NSSet *)identifiers {
    [self requestProducts:identifiers success:nil failure:nil];
}

- (void)requestProducts:(NSSet *)identifiers
                success:(RMSKProductsRequestSuccessBlock)successBlock
                failure:(RMSKProductsRequestFailureBlock)failureBlock {
    RMProductsRequestDelegate *delegate = [[RMProductsRequestDelegate alloc] init];
    delegate.store = self;
    delegate.successBlock = successBlock;
    delegate.failureBlock = failureBlock;
    [_productsRequestDelegates  addObject:delegate];
    
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:identifiers];
    productsRequest.delegate = delegate;
    [productsRequest start];
}


#pragma mark - restore

- (void)restoreTransactions {
    
}

- (void)restoreTransactionsOnSuccess:(RMStoreTransactionsSuccessBlock )successBlock
                             failure:(RMStoreTransactionsFailureBlock )failureBlock {
    _restoredCompletedTransactionsFinished = NO;
    _pendingRestoredTransactionsCount = 0;
    _restoredTransactions = [NSMutableArray array];
    _restoreTransactionsSuccessBlock = successBlock;
    _restoreTransactionsFailureBlock = failureBlock;
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)restoreTransactionsOfUser:(NSString *)userIdentifier
                        onSuccess:(RMStoreTransactionsSuccessBlock)successBlock
                           falure:(RMStoreTransactionsFailureBlock)failureBlock{
    NSAssert([[SKPaymentQueue defaultQueue] respondsToSelector:@selector(restoreCompletedTransactionsWithApplicationUsername:)],@"restoreCompletedTransactionsWithApplicationUsername: not supported in this iOS version. Use restoreTransactionsOnSuccess:failure: instead.");
    
    _restoredCompletedTransactionsFinished = NO;
    _pendingRestoredTransactionsCount = 0;
    _restoredTransactions = [NSMutableArray array];
    _restoreTransactionsSuccessBlock = successBlock;
    _restoreTransactionsFailureBlock = failureBlock;
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactionsWithApplicationUsername:userIdentifier];
}


#pragma mark - Product management 
- (SKProduct *)productForIdentifier:(NSString *)productIdentifier {
    return _products[productIdentifier];
}

+ (NSString *)localizedPriceOfProduct:(SKProduct *)product {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    numberFormatter.locale = product.priceLocale;
    
    NSString *formattedString = [numberFormatter stringFromNumber:product.price];
    return formattedString;
}


#pragma mark - Receipt
+ (NSURL *)receiptURL {
    NSAssert(floor(NSFoundationVersionNumber)>NSFoundationVersionNumber_iOS_6_1,@"appStoreReceiptURL not supported in this iOS version.");
    NSURL *url = [[NSBundle mainBundle] appStoreReceiptURL];
    return url;
}

- (void)refreshReceipt {
    [self refreshReceiptOnSuccess:nil failure:nil];
}

- (void)refreshReceiptOnSuccess:(RMStoreSuccessBlock)successBlock
                        failure:(RMStoreFailureBlock)failureBlock {
    _refreshReceiptSuccessBlock = successBlock;
    _refreshReceiptFailureBlock = failureBlock;
    
    _refreshReceiptRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:@{}];
    _refreshReceiptRequest.delegate = self;
    [_refreshReceiptRequest start];
}

#pragma mark Observers

- (void)addStoreObserver:(id<RMStoreObserver>)observer
{

    
    [self addStoreObserver:observer selector:@selector(storeDownloadCanceled:) notificationName:RMSKDownloadCanceled];
    [self addStoreObserver:observer selector:@selector(storeDownloadFailed:) notificationName:RMSKDownloadFailed];
    [self addStoreObserver:observer selector:@selector(storeDownloadFinished:) notificationName:RMSKDownloadFinished];
    [self addStoreObserver:observer selector:@selector(storeDownloadPaused:) notificationName:RMSKDownloadPaused];
    [self addStoreObserver:observer selector:@selector(storeDownloadUpdated:) notificationName:RMSKDownloadUpdated];
    [self addStoreObserver:observer selector:@selector(storeProductsRequestFailed:) notificationName:RMSKProductsRequestFailed];
    [self addStoreObserver:observer selector:@selector(storeProductsRequestFinished:) notificationName:RMSKProductsRequestFinished];
    [self addStoreObserver:observer selector:@selector(storePaymentTransactionDeferred:) notificationName:RMSKPaymentTransactionDeferred];
    [self addStoreObserver:observer selector:@selector(storePaymentTransactionFailed:) notificationName:RMSKPaymentTransactionFailed];
    [self addStoreObserver:observer selector:@selector(storePaymentTransactionFinished:) notificationName:RMSKPaymentTransactionFinished];
    [self addStoreObserver:observer selector:@selector(storeRefreshReceiptFailed:) notificationName:RMSKRefreshReceiptFailed];
    [self addStoreObserver:observer selector:@selector(storeRefreshReceiptFinished:) notificationName:RMSKRefreshReceiptFinished];
    [self addStoreObserver:observer selector:@selector(storeRestoreTransactionsFailed:) notificationName:RMSKRestoreTransactionsFailed];
    [self addStoreObserver:observer selector:@selector(storeRestoreTransactionsFinished:) notificationName:RMSKRestoreTransactionsFinished];
}

- (void)removeStoreObserver:(id<RMStoreObserver>)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKDownloadCanceled object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKDownloadFailed object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKDownloadFinished object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKDownloadPaused object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKDownloadUpdated object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKProductsRequestFailed object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKProductsRequestFinished object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKPaymentTransactionDeferred object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKPaymentTransactionFailed object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKPaymentTransactionFinished object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKRefreshReceiptFailed object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKRefreshReceiptFinished object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKRestoreTransactionsFailed object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:RMSKRestoreTransactionsFinished object:self];
}


- (void)addStoreObserver:(id<RMStoreObserver>)observer selector:(SEL)aSelector notificationName:(NSString *)notificationName {
    if([observer respondsToSelector:aSelector]) {
        [[NSNotificationCenter defaultCenter] addObserver:observer selector:aSelector name:notificationName object:self];
    }
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased: {
                [self didPurchaseTransaction:transaction queue:queue];
                break;
            }
            case SKPaymentTransactionStateFailed: {
                [self didFailTransaction:transaction queue:queue error:transaction.error];
                break;
            }
            case SKPaymentTransactionStateRestored: {
                [self didRestoreTransaction:transaction queue:queue];
                break;
            }
            case SKPaymentTransactionStateDeferred: {
                [self didDeferTransaction:transaction];
                break;
            }
            default:
                break;
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    RMStoreLog(@"restore transactions finished");
    _restoredCompletedTransactionsFinished = YES;
    
    [self notifyRestoreTransactionFinishedIfApplicableAfterTransaction:nil];
}


- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(nonnull NSError *)error {
    RMStoreLog(@"restored transactions failed with error %@",error.debugDescription);
    
    if(_restoreTransactionsFailureBlock != nil) {
        _restoreTransactionsFailureBlock(error);
        _restoreTransactionsFailureBlock = nil;
    }
    
    NSDictionary *userInfo = nil;
    if(error) {
        userInfo = @{RMStoreNotificationStoreError:error};
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKRestoreTransactionsFailed object:self userInfo:userInfo];
    
}




- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(nonnull NSArray<SKDownload *> *)downloads {
    for (SKDownload *download in downloads) {
        switch (download.downloadState) {
            case SKDownloadStateActive:{
                [self didUpdateDownload:download queue:queue];
                break;
            }
            case SKDownloadStateCancelled:{
                [self didCancelDownload:download queue:queue];
                break;
            }
            case SKDownloadStateFailed:{
                [self didFailDownload:download queue:queue];
                break;
            }
            case SKDownloadStateFinished:{
                [self didFinishDownload:download queue:queue];
                break;
            }
            case SKDownloadStatePaused:{
                [self didPauseDownload:download queue:queue];
                break;
            }
            case SKDownloadStateWaiting:{
                //do nothing
                break;
            }
                
            default:
                break;
        }
    }
}

#pragma mark - Download state 

- (void)didCancelDownload:(SKDownload *)download queue:(SKPaymentQueue *)queue {
    SKPaymentTransaction *transaction = download.transaction;
    RMStoreLog(@"download %@ for product %@ canceled", download.contentIdentifier,download.transaction.payment.productIdentifier);
    [self postNotificationWithName:RMSKDownloadCanceled download:download userInfoExtras:nil];
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:NSLocalizedStringFromTable(@"Download Cancel", @"RMStore", @"Error description")};
    NSError *error = [NSError errorWithDomain:RMStoreErrorDomain code:RMStoreErrorCodeDownloadCanceled userInfo:userInfo];
    
    const BOOL hasPendingDwonloads = [self.class  hasPendingDownloadsInTransaction:transaction];
    
    if(!hasPendingDwonloads) {
        [self didFailTransaction:transaction queue:queue error:error];
    }
}

- (void)didFailDownload:(SKDownload *)download queue:(SKPaymentQueue *)queue {
    NSError *error = download.error;
    SKPaymentTransaction *transaction = download.transaction;
    
    RMStoreLog(@"download %@ for product %@ failed with error %@",download.contentIdentifier,transaction.payment.productIdentifier,error.debugDescription);
    NSDictionary *extras = error? @{RMStoreNotificationStoreError:error}:nil;
    [self postNotificationWithName:RMSKDownloadFailed download:download userInfoExtras:extras];
    
    const BOOL hasPendingDownloads = [self.class hasPendingDownloadsInTransaction:transaction];
    if(!hasPendingDownloads) {
        [self didFailTransaction:transaction queue:queue error:error];
    }

}

- (void)didFinishDownload:(SKDownload *)download queue:(SKPaymentQueue *)queue{
    SKPaymentTransaction *transaction = download.transaction;
    RMStoreLog(@"download %@,for product %@ finished ",download.contentIdentifier,transaction.payment.productIdentifier);
    
    const BOOL hasPendingDownloads = [self.class hasPendingDownloadsInTransaction:transaction];
    if(!hasPendingDownloads) {
        [self finishTransaction:download.transaction queue:queue];
    }
}


- (void)didPauseDownload:(SKDownload *)download queue:(SKPaymentQueue *)queue {
    RMStoreLog(@"download %@ for product %@ paused",download.contentIdentifier,download.transaction.payment.productIdentifier);
    [self postNotificationWithName:RMSKDownloadPaused download:download userInfoExtras:nil];
}

- (void)didUpdateDownload:(SKDownload *)download queue:(SKPaymentQueue *)queue {
    RMStoreLog(@"download %@ for product %@ updated",download.contentIdentifier,download.transaction.payment.productIdentifier);
    NSDictionary *extras = @{RMStoreNotificationDownloadProgress:@(download.progress)};
    [self postNotificationWithName:RMSKDownloadUpdated download:download userInfoExtras:extras];
}


+ (BOOL)hasPendingDownloadsInTransaction:(SKPaymentTransaction *)transaction {
    for(SKDownload *download in transaction.downloads) {
        switch (download.downloadState) {
            case SKDownloadStateActive:
            case SKDownloadStatePaused:
            case SKDownloadStateWaiting:
                return YES;
            case SKDownloadStateCancelled:
            case SKDownloadStateFailed:
            case SKDownloadStateFinished:
                continue;

        }
    }
    
    return NO;
}

#pragma mark - transaction state

- (void)didPurchaseTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue *)queue {
    RMStoreLog(@"transaction purchased with product %@", transaction.payment.productIdentifier);
    if(self.receiptVerfier != nil) {
        [self.receiptVerfier verifyTransaction:transaction success:^{
            [self didVerifyTransaction:transaction queue:queue];
        } failure:^(NSError *error) {
            [self didFailTransaction:transaction queue:queue error:error];
        }];
    }else{
        RMStoreLog(@"WARNING: no receipt verification");
        [self didVerifyTransaction:transaction queue:queue];
    }
}

- (void)didFailTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue *)queue error:(NSError *)error {
    SKPayment *payment = transaction.payment;
    NSString *procudtIdentifier = payment.productIdentifier;
    RMStoreLog(@"transaction failed with product %@ and erro %@",procudtIdentifier,error.debugDescription);
    
    // If we were unable to complete the verification we want StoreKit to keep reminding us of the transaction
    if(error.code != RMStoreErrorCodeUnableToCompleteVerification) {
        [queue finishTransaction:transaction];
    }
    
    RMAddPaymentParameters *parameters = [self popAddPaymentParametersForIdentifier:procudtIdentifier];
    if(parameters.failureBlock != nil) {
        parameters.failureBlock(transaction,error);
    }
    
    NSDictionary *extras = error? @{RMStoreNotificationStoreError:error} :nil;
    [self postNotificationWithName:RMSKPaymentTransactionFailed transaction:transaction userInfoExtras:extras];
    
    if(transaction.transactionState == SKPaymentTransactionStateRestored) {
        [self notifyRestoreTransactionFinishedIfApplicableAfterTransaction:transaction];
    }
    
}

- (void)didRestoreTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue *)queue {
    RMStoreLog(@"transaction restored with product %@", transaction.originalTransaction.payment.productIdentifier);
    _pendingRestoredTransactionsCount ++;
    if(self.receiptVerfier != nil) {
        [self.receiptVerfier verifyTransaction:transaction success:^{
            [self didVerifyTransaction:transaction queue:queue];
        } failure:^(NSError *error) {
            [self didFailTransaction:transaction queue:queue error:error];
        }];
    }else {
        RMStoreLog(@"WARNING : no receipt verification");
        [self didVerifyTransaction:transaction queue:queue];
    }
    
    
}

- (void)didDeferTransaction:(SKPaymentTransaction *)transaction {
    [self postNotificationWithName:RMSKPaymentTransactionDeferred transaction:transaction userInfoExtras:nil];
}

- (void)didVerifyTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue *)queue {
    
    if(self.contentDownloader !=nil ) {
        [self.contentDownloader downloadContentForTransaction:transaction success:^{
            [self postNotificationWithName:RMSKDownloadFinished transaction:transaction userInfoExtras:nil];
            [self didDownloadSelfHostedContentForTransaction:transaction queue:queue];
        } progress:^(float progress) {
            NSDictionary *extras = @{RMStoreNotificationDownloadProgress:@(progress)};
            [self postNotificationWithName:RMSKDownloadUpdated transaction:transaction userInfoExtras:extras];
        } failure:^(NSError *error) {
            NSDictionary *extras = error ? @{RMStoreNotificationStoreError:error} : nil;
            [self postNotificationWithName:RMSKDownloadFailed transaction:transaction userInfoExtras:extras];
            [self didFailTransaction:transaction queue:queue error:error];
        }];
    }else{
        [self didDownloadSelfHostedContentForTransaction:transaction queue:queue];
    }
}

- (void)didDownloadSelfHostedContentForTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue *)queue{
    NSArray *downloads = [transaction respondsToSelector:@selector(downloads)] ? transaction.downloads :@[]
    ;
    if(downloads.count > 0){
        
    }else {
        [self finishTransaction:transaction queue:queue];
    }
}


- (void)finishTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue *)queue {
    SKPayment *payment = transaction.payment;
    NSString *productIdentifier = payment.productIdentifier;
    [queue finishTransaction:transaction];
    RMAddPaymentParameters *wrapper = [self popAddPaymentParametersForIdentifier:productIdentifier];
    if(wrapper.successBlock != nil) {
        wrapper.successBlock(transaction);
    }
    
    [self postNotificationWithName:RMSKPaymentTransactionFinished transaction:transaction userInfoExtras:nil];
    
    //不一样的地方
    if(transaction.transactionState == SKPaymentTransactionStateRestored) {
        [self notifyRestoreTransactionFinishedIfApplicableAfterTransaction:transaction];
    }
    
    
}

- (void)notifyRestoreTransactionFinishedIfApplicableAfterTransaction:(SKPaymentTransaction *)transaction {
    if(transaction != nil) {
        [_restoredTransactions addObject:transaction];
        _pendingRestoredTransactionsCount--;
        
    }
    if(_restoredCompletedTransactionsFinished && _pendingRestoredTransactionsCount == 0){
        NSArray *restoredTransactions = [_restoredTransactions copy];
        if(_restoreTransactionsSuccessBlock != nil){
            _restoreTransactionsSuccessBlock(restoredTransactions);
            _restoreTransactionsSuccessBlock = nil;
        }
        NSDictionary *userInfo = @{RMStoreNotificationTransaction :restoredTransactions};
        [[NSNotificationCenter defaultCenter] postNotificationName:RMSKRestoreTransactionsFinished object:self userInfo:userInfo];
    }
}

- (RMAddPaymentParameters *)popAddPaymentParametersForIdentifier:(NSString *)identifier {
    RMAddPaymentParameters *parameters = _addPaymentParameters[identifier];
    [_addPaymentParameters removeObjectForKey:identifier];
    return parameters;
}

#pragma mark - SKRequestDelegate

- (void)requestDidFinish:(SKRequest *)request {
    RMStoreLog(@"refresh receipt finished");
    if(_refreshReceiptSuccessBlock) {
        _refreshReceiptSuccessBlock();
        _refreshReceiptSuccessBlock = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKRefreshReceiptFinished object:self];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    RMStoreLog(@"refresh receipt failed with error %@",error.debugDescription);
}


#pragma mark - private 

- (void)addProduct:(SKProduct *)product {
    _products[product.productIdentifier] = product;
}

- (void)postNotificationWithName:(NSString *)notificationName download:(SKDownload *)download userInfoExtras:(NSDictionary *)extras {
    NSMutableDictionary *mutableExtras = extras ? [NSMutableDictionary dictionaryWithDictionary:extras]:[NSMutableDictionary dictionary];
    mutableExtras[RMStoreNotificationStoreDownload] = download;
    
    [self postNotificationWithName:notificationName transaction:download.transaction userInfoExtras:mutableExtras];
}

- (void)postNotificationWithName:(NSString *)notificationName transaction:(SKPaymentTransaction *)transaction userInfoExtras:(NSDictionary *)extras {
    NSString *productsIdentifier = transaction.payment.productIdentifier;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[RMStoreNotificationTransaction] = transaction;
    userInfo[RMStoreNotificationProductIdentifier] = productsIdentifier;
    
    if(extras) {
        [userInfo addEntriesFromDictionary:extras];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:userInfo];
}

- (void)removeProductsRequestDelegate:(RMProductsRequestDelegate *)delegate {
    [_productsRequestDelegates removeObject:delegate];
}

@end


#pragma mark - ProductsRequest
@implementation RMProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    RMStoreLog(@"products request received response");
    NSArray *products = [NSArray arrayWithArray:response.products];
    NSArray *invalidProductIdentifiers = [NSArray arrayWithArray:response.invalidProductIdentifiers];
    
    for(SKProduct *product in products) {
        RMStoreLog(@"received product with id %@",product.productIdentifier);
        [self.store addProduct:product];
        
    }
    [invalidProductIdentifiers enumerateObjectsUsingBlock:^( NSString *invalid, NSUInteger idx, BOOL *stop) {
        RMStoreLog(@"invalid product with id %@",invalid);
    }];
    
    if(self.successBlock) {
        self.successBlock(products,invalidProductIdentifiers);
    }
    NSDictionary *userInfo = @{RMStoreNotificationProducts:products,RMStoreNotificationInvalidProductIdentifiers:invalidProductIdentifiers};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKProductsRequestFinished object:self.store userInfo:userInfo];
}

- (void)requestDidFinish:(SKRequest *)request {
    [self.store removeProductsRequestDelegate:self];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    RMStoreLog(@"products request failed with error %@",error.debugDescription);
    if(self.failureBlock) {
        self.failureBlock(error);
    }
    NSDictionary *userInfo = nil;
    if(error) {
        userInfo = @{RMStoreNotificationStoreError:error};
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RMSKProductsRequestFailed object:self.store userInfo:userInfo];
    
}

@end

