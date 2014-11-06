//
//  CUHostGameManager.h
//  ActivityGame
//
//  Created by curer on 11/2/14.
//  Copyright (c) 2014 lion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVOSCloud/AVOSCloud.h>

@interface CUHostGameManager : NSObject<AVSessionDelegate>

- (instancetype)initWithSession:(AVSession *)session;

- (void)startGame;

@end
