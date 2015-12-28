//
//  HTTPNSURLConnection.m
//  KYIAPManager
//
//  Created by bruce on 15/11/27.
//  Copyright © 2015年 KY. All rights reserved.
//

#import "HTTPNSURLConnection.h"
#import <Foundation/Foundation.h>


@interface HTTPNSURLConnection()<NSURLConnectionDataDelegate>

@property (strong, nonatomic) NSMutableData *resultData;

@end

@implementation HTTPNSURLConnection

+ (void)getRequestWithURL:(NSString *)urlStr
                paramters:(NSMutableDictionary *)paramters
             finshedBlock:(FinishBlock)block {
    HTTPNSURLConnection *httpNSURLConnection = [[HTTPNSURLConnection alloc] init];
    httpNSURLConnection.finishBlock = block;
    
    NSURL *url = [self requestWithUrl:urlStr params:paramters];
    NSMutableURLRequest *requset = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    [requset setHTTPMethod:@"GET"];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
//    HTTPNSURLConnection *weakSelf = httpNSURLConnection;
    [NSURLConnection sendAsynchronousRequest:requset queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if(!connectionError){
            NSError *error;
            NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            if (httpNSURLConnection.finishBlock) {
                httpNSURLConnection.finishBlock(YES,resultDic);
            }
        }else{
            NSLog(@"%@",connectionError);
            if (httpNSURLConnection.finishBlock) {
                httpNSURLConnection.finishBlock(NO,nil);
            }
        }
    }];
    
}


+ (void)postRequestWithURL:(NSString *)urlStr
                 paramters:(NSDictionary *)paramters
              finshedBlock:(FinishBlock)block {
    HTTPNSURLConnection *httpNSURLConnection = [[HTTPNSURLConnection alloc]init];
    httpNSURLConnection.finishBlock = block;
    
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    [request setHTTPMethod:@"POST"];
    if(paramters!=nil){
        if (![NSJSONSerialization isValidJSONObject:paramters]){
            NSLog(@"inValidJSONObject");
        }
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:paramters options:NSJSONWritingPrettyPrinted error:&error];
        NSString *json =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSString *postLength = [NSString stringWithFormat:@"%zd", [json length]];
        //发送请求
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];////--一般不发送字符串长度也可以返回数据
        [request setHTTPBody:jsonData];
    }

    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if(!connectionError){
            NSError *error;
            NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            if (httpNSURLConnection.finishBlock) {
                httpNSURLConnection.finishBlock(YES,resultDic);
            }
        }else{
            if (httpNSURLConnection.finishBlock) {
                httpNSURLConnection.finishBlock(NO,nil);
            }
        }
    }];

}



+ (NSURL *)requestWithUrl:(NSString *)urlString params:(NSMutableDictionary *)params{
    //get请求
    NSMutableString *url =[NSMutableString stringWithString:urlString];
    NSArray *array = [params allKeys];
    for(int i=0;i<array.count;i++){
        NSString *s = [array objectAtIndex:i];
        if(i==0){
            [url appendString:[NSString stringWithFormat:@"?%@=%@",s,[params objectForKey:s]]];
        }
        else{
            [url appendString:[NSString stringWithFormat:@"&%@=%@",s,[params objectForKey:s]]];
        }
    }
//    NSLog(@"url = %@",url);
    return [NSURL URLWithString:url];
}


@end
