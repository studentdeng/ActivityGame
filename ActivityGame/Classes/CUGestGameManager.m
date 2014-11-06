//
//  CUGestGameManager.m
//  ActivityGame
//
//  Created by curer on 11/2/14.
//  Copyright (c) 2014 lion. All rights reserved.
//

#import "CUGestGameManager.h"
#import <TransitionKit.h>
#import <AVOSCloud/AVOSCloud.h>
#import <SVProgressHUD.h>


NSString *CUGestGameManagerSearchingEvent = @"searchingEvent";
NSString *CUGestGameManagerReceiveConfirmEvent = @"ReceiveConfirmEvent";
NSString *CUGestGameManagerDisconnectedEvent = @"DisconnectedEvent";

@interface CUGestGameManager ()<AVSignatureDelegate>

@property (nonatomic, strong) TKStateMachine *stateMachine;
@property (nonatomic, strong) AVSession *session;
@property (nonatomic, copy) NSString *otherPeerId;

@end

@implementation CUGestGameManager

- (instancetype)initWithSession:(AVSession *)session {
  if (self = [self init]) {
    [self setup];
    _session = session;
  }

  return self;
}

- (void)setup {
  
  self.stateMachine = [TKStateMachine new];
  
  __weak typeof(self)selfWeak = self;
  
  TKState *idleState = [TKState stateWithName:@"idle"];
  TKState *waitingReplyState = [TKState stateWithName:@"waitingReply"];
  TKState *goState = [TKState stateWithName:@"go"];
  TKState *errorState = [TKState stateWithName:@"error"];
  
  [self.stateMachine addStates:@[idleState, waitingReplyState, goState, errorState]];
  self.stateMachine.initialState = idleState;
  
  [waitingReplyState setWillEnterStateBlock:^(TKState *state, TKTransition *transition) {
    [selfWeak searchingGames];
  }];
  
  [goState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
    [selfWeak sendGo];
    
    NSLog(@"happy ending");
    
    [SVProgressHUD showSuccessWithStatus:@"ok"];
    
  }];
  
  TKEvent *searchingEvent = [TKEvent eventWithName:CUGestGameManagerSearchingEvent
                           transitioningFromStates:@[idleState]
                                           toState:waitingReplyState];
  
  TKEvent *receiveConfirmEvent = [TKEvent eventWithName:CUGestGameManagerReceiveConfirmEvent
                                transitioningFromStates:@[waitingReplyState]
                                                toState:goState];
  
  TKEvent *disconnectedEvent = [TKEvent eventWithName:CUGestGameManagerDisconnectedEvent
                              transitioningFromStates:nil
                                              toState:idleState];
  
  [self.stateMachine addEvents:@[searchingEvent,
                                 receiveConfirmEvent,
                                 disconnectedEvent
                                 ]];
  [self.stateMachine activate];
}

#pragma mark - state machine

- (void)joinGame {
  
  if (![self.stateMachine.currentState.name isEqual:@"idle"]) {
    [self fireEvent:CUGestGameManagerDisconnectedEvent userInfo:nil];
  }
  
  [self fireEvent:CUGestGameManagerSearchingEvent userInfo:nil];
}

- (void)searchingGames {
  AVQuery *query = [AVQuery queryWithClassName:@"waiting_join_Ids"];
  [query orderByDescending:@"updatedAt"];
  [query setLimit:1];
  
  [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    NSMutableArray *installationIds = [[NSMutableArray alloc] init];
    for (AVObject *object in objects) {
      if ([object objectForKey:@"peerId"]) {
        [installationIds addObject:[object objectForKey:@"peerId"]];
      }
    }
    
    [self.session watchPeerIds:installationIds];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendJoinRequest) object:nil];
    [self performSelector:@selector(sendJoinRequest)
               withObject:nil
               afterDelay:2.0f];
  }];
}

- (void)sendJoinRequest {
  
  for (NSString *item in self.session.watchedPeerIds) {
    AVMessage *message = [AVMessage messageForPeerWithSession:self.session
                                                     toPeerId:item
                                                      payload:@"join"];
    [self.session sendMessage:message transient:YES];
  }
}

- (void)sendGo{
  AVMessage *message = [AVMessage messageForPeerWithSession:self.session
                                                   toPeerId:self.otherPeerId
                                                    payload:@"go"];
  [self.session sendMessage:message transient:YES];
}

#pragma mark - AVSessionDelegate
- (void)onSessionOpen:(AVSession *)session {
  NSLog(@"%s", __FUNCTION__);
}

- (void)onSessionPaused:(AVSession *)session {
  NSLog(@"%s", __FUNCTION__);
  
  [self fireEvent:CUGestGameManagerDisconnectedEvent userInfo:nil];
}

- (void)onSessionResumed:(AVSession *)seesion {
  NSLog(@"%s", __FUNCTION__);
  
  [self fireEvent:CUGestGameManagerDisconnectedEvent userInfo:nil];
}

- (void)sessionFailed:(AVSession *)session error:(NSError *)error
{
  [self fireEvent:CUGestGameManagerDisconnectedEvent userInfo:nil];
}

- (void)session:(AVSession *)session didReceiveMessage:(AVMessage *)message
{
  if ([message.payload isEqualToString:@"join_confirm"]) {
    
    self.otherPeerId = message.fromPeerId;
    
    if ([self.session.watchedPeerIds containsObject:self.otherPeerId]) {
      [self fireEvent:CUGestGameManagerReceiveConfirmEvent userInfo:nil];
    }
  }
}

- (void)session:(AVSession *)session didReceiveStatus:(AVPeerStatus)status peerIds:(NSArray *)peerIds
{
  NSLog(@"peerIds :%@ statusId:%lu", peerIds, status);
}

- (void)session:(AVSession *)session messageSendFinished:(AVMessage *)message
{
  NSLog(@"%s", __FUNCTION__);
  [self fireEvent:CUGestGameManagerDisconnectedEvent userInfo:nil];
}

- (void)session:(AVSession *)session messageSendFailed:(AVMessage *)message error:(NSError *)error
{
  NSLog(@"%s", __FUNCTION__);
  [self fireEvent:CUGestGameManagerDisconnectedEvent userInfo:nil];
}

- (void)onSessionMessageSent:(AVSession *)session message:(NSString *)message toPeerIds:(NSArray *)peerIds {
  NSLog(@"on session message sent %@", message);
}

- (void)fireEvent:(NSString *)eventName userInfo:(NSDictionary *)userInfo {
  NSError *error;
  BOOL bRes =
  [self.stateMachine fireEvent:eventName
                      userInfo:userInfo
                         error:&error];
  if (!bRes) {
    NSLog(@"event error %@", [error localizedDescription]);
  }
}

@end
