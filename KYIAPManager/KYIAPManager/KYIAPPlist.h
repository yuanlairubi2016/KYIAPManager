//
//  KYIAPPlist.h
//  KYIAPManager
//
//  Created by bruce on 15/11/25.
//  Copyright © 2015年 KY. All rights reserved.
//


#import <Foundation/Foundation.h>

extern NSString * const KYIAPPLIST;


@interface KYIAPPlist : NSObject

+ (KYIAPPlist *)shareInstance;

- (void)writeToPlist:(NSString *)plistName andParams:(NSDictionary *)params;

- (NSString *)readFromPlist:(NSString *)plistName andKey:(NSString *)key;

- (void)removeFromPlist:(NSString *)plistName andKey:(NSString *)key;

- (NSDictionary *)readFromPlist:(NSString *)plistName;


@end
