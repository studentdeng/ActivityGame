//
//  CUSessionManager.m
//  ActivityGame
//
//  Created by curer on 11/1/14.
//  Copyright (c) 2014 lion. All rights reserved.
//

#import "CUSessionManager.h"
#import <AVSession.h>
#import <CommonCrypto/CommonHMAC.h>

@interface CUSessionManager ()<AVSignatureDelegate>

@end

@implementation CUSessionManager

+ (instancetype)sharedInstance {
  static CUSessionManager *_sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedInstance = [CUSessionManager new];
  });
  
  return _sharedInstance;
}

- (AVSession *)createSession {
  AVSession *session = [AVSession new];
  session.signatureDelegate = self;
  return session;
}

#pragma mark - AVSignatureDelegate
- (AVSignature *)createSignature:(NSString *)peerId watchedPeerIds:(NSArray *)watchedPeerIds {
  NSString *appId = @"19y77w6qkz7k5h1wifou7lwnrxf9i3g4qdpxb4k1yeuvjgp7";
  
  AVSignature *signature = [[AVSignature alloc] init];
  signature.timestamp = [[NSDate date] timeIntervalSince1970];
  signature.nonce = @"ForeverAlone";
  
  NSArray *sortedArray = [watchedPeerIds sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    return [obj1 compare:obj2];
  }];
  
  signature.signedPeerIds = sortedArray;
  
  NSMutableArray *tempArray = [[NSMutableArray alloc] init];
  [tempArray addObject:appId];
  [tempArray addObject:peerId];
  
  if ([sortedArray count]> 0) {
    [tempArray addObjectsFromArray:sortedArray];
  } else {
    [tempArray addObject:@""];
  }
  
  [tempArray addObject:@(signature.timestamp)];
  [tempArray addObject:signature.nonce];
  
  NSString *message = [tempArray componentsJoinedByString:@":"];
  NSString *secret = @"qn0p4dq9swan3jvo202jzpsbrtpxy6w279r8ck137i0fwppq";//master
  signature.signature = [self hmacsha1:message key:secret];
  
  return signature;
}

- (NSString *)hmacsha1:(NSString *)text key:(NSString *)secret {
  NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
  NSData *clearTextData = [text dataUsingEncoding:NSUTF8StringEncoding];
  unsigned char result[CC_SHA1_DIGEST_LENGTH];
  CCHmac(kCCHmacAlgSHA1, [secretData bytes], [secretData length], [clearTextData bytes], [clearTextData length], result);
  
  return [self hexStringWithData:result ofLength:CC_SHA1_DIGEST_LENGTH];
}

- (NSString*) hexStringWithData:(unsigned char*) data ofLength:(NSUInteger)len {
  NSMutableString *tmp = [NSMutableString string];
  for (NSUInteger i=0; i<len; i++)
    [tmp appendFormat:@"%02x", data[i]];
  return [NSString stringWithString:tmp];
}

@end
