//
//  HTTPNSURLConnection.h
//  KYIAPManager
//
//  Created by bruce on 15/11/27.
//  Copyright © 2015年 KY. All rights reserved.
//  

#import <Foundation/Foundation.h>

typedef void (^FinishBlock)(BOOL isSuccess, NSDictionary *dataDic);

@interface HTTPNSURLConnection : NSObject

@property (strong, nonatomic) FinishBlock finishBlock;

+ (void)postRequestWithURL:(NSString *)urlStr
                 paramters:(NSDictionary *)paramters
              finshedBlock:(FinishBlock)block;

+ (void)getRequestWithURL:(NSString *)urlStr
                 paramters:(NSDictionary *)paramters
              finshedBlock:(FinishBlock)block;
@end
