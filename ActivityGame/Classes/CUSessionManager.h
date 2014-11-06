//
//  CUSessionManager.h
//  ActivityGame
//
//  Created by curer on 11/1/14.
//  Copyright (c) 2014 lion. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVSession;
@interface CUSessionManager : NSObject

+ (instancetype)sharedInstance;

- (AVSession *)createSession;

@end
