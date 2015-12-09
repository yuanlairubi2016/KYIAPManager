//
//  KYIAPPlist.m
//  KYIAPManager
//
//  Created by bruce on 15/11/25.
//  Copyright © 2015年 KY. All rights reserved.
//

#import "KYIAPPlist.h"

NSString * const KYIAPPLIST = @"KYPLIST.plist"; //plistName


@implementation KYIAPPlist

//singleton
+ (KYIAPPlist *)shareInstance{
    static KYIAPPlist *mInstance = nil;
    static dispatch_once_t onceTokenKYIAPPlist;
    dispatch_once(&onceTokenKYIAPPlist, ^{
        mInstance = [[[self class] alloc] init];
    });
    return mInstance;
}

- (void)writeToPlist:(NSString *)plistName andParams:(NSDictionary *)params{
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [path objectAtIndex:0];
    NSString *plistPath = [filePath stringByAppendingPathComponent:plistName];
    BOOL isExist = [fm fileExistsAtPath:filePath];
    if(!isExist){
        [fm createFileAtPath:plistPath contents:nil attributes:nil];
    }
    
    NSMutableDictionary *priorDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    if(!priorDic){//if nil new dic
        priorDic = [[NSMutableDictionary alloc] init];
    }
    [priorDic addEntriesFromDictionary:params];
    [priorDic writeToFile:plistPath atomically:YES];
    
    NSDictionary *dic11 = [self readFromPlist:plistName];
    NSLog(@"%@",dic11);
    NSLog(@"write to file");
}

//delete
- (void)removeFromPlist:(NSString *)plistName andKey:(NSString *)key{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *plistPath = [path stringByAppendingPathComponent:plistName];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    
    [dic removeObjectForKey:key];
    //write back
    [dic writeToFile:plistPath atomically:YES];
    NSLog(@"remove from file");
    
}

- (NSDictionary *)readFromPlist:(NSString *)plistName andKey:(NSString *)key {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *plistPath = [path stringByAppendingPathComponent:plistName];
    NSDictionary *dic = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    
    NSDictionary *resultDic = [dic objectForKey:key];
    return resultDic;
}


- (NSDictionary *)readFromPlist:(NSString *)plistName{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *plistPath = [path stringByAppendingPathComponent:plistName];
    NSDictionary *dic = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    
    //    NSLog(@"%@",[dic allKeys]);
    return dic;
}

//is exist
- (BOOL) isFileExist:(NSString *)fileName {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL result = [fileManager fileExistsAtPath:filePath];
    
    return result;
}

@end
