//
//  CUGestGameManager.h
//  ActivityGame
//
//  Created by curer on 11/2/14.
//  Copyright (c) 2014 lion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVOSCloud/AVOSCloud.h>


@interface CUGestGameManager : NSObject<AVSessionDelegate>

- (instancetype)initWithSession:(AVSession *)session;

- (void)joinGame;

@end