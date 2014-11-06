//
//  CUHostGameManager.m
//  ActivityGame
//
//  Created by curer on 11/2/14.
//  Copyright (c) 2014 lion. All rights reserved.
//

#import "CUHostGameManager.h"
#import <TransitionKit.h>
#import <SVProgressHUD.h>


NSString *CUHostGameManagerWaitingJoinEvent = @"waitingJoinEvent";
NSString *CUHostGameManagerReceiveInviteEvent = @"ReceiveInviteEvent";
NSString *CUHostGameManagerReceiveConfirmEvent = @"ReceiveConfirmEvent";
NSString *CUHostGameManagerDisconnectedEvent = @"DisconnectedEvent";

@interface CUHostGameManager ()

@property (nonatomic, strong) TKStateMachine *stateMachine;
@property (nonatomic, strong) AVSession *session;
@property (nonatomic, copy) NSString *peerId;

@end

@implementation CUHostGameManager

- (instancetype)initWithSession:(AVSession *)session {
  if (self = [super init]) {
    [self setup];
    _session = session;
  }
  
  return self;
}

- (void)setup {
  
  self.stateMachine = [TKStateMachine new];
  
  __weak typeof(self)selfWeak = self;

  TKState *idleState = [TKState stateWithName:@"idle"];
  TKState *waitingJoinState = [TKState stateWithName:@"waitingJoin"];
  TKState *waitingConfirmState = [TKState stateWithName:@"waitingConfirm"];
  TKState *goState = [TKState stateWithName:@"go"];
  TKState *errorState = [TKState stateWithName:@"error"];
  
  [self.stateMachine addStates:@[idleState, waitingConfirmState, goState, waitingJoinState, errorState]];
  self.stateMachine.initialState = idleState;
  
  [waitingConfirmState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
    [selfWeak sendJoinConfirm];
  }];
  
  [goState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
    NSLog(@"happy ending");
                                      
    [SVProgressHUD showSuccessWithStatus:@"ok"];
  }];
  
  TKEvent *waitingJoinEvent = [TKEvent eventWithName:CUHostGameManagerWaitingJoinEvent
                           transitioningFromStates:@[idleState]
                                           toState:waitingJoinState];
  
  TKEvent *receiveInviteEvent = [TKEvent eventWithName:CUHostGameManagerReceiveInviteEvent
                               transitioningFromStates:@[waitingJoinState]
                                               toState:waitingConfirmState];
  
  TKEvent *receiveConfirmEvent = [TKEvent eventWithName:CUHostGameManagerReceiveConfirmEvent
                                transitioningFromStates:@[waitingConfirmState]
                                                toState:goState];
  
  TKEvent *disconnectedEvent = [TKEvent eventWithName:CUHostGameManagerDisconnectedEvent
                              transitioningFromStates:nil
                                              toState:idleState];
  
  [self.stateMachine addEvents:@[waitingJoinEvent,
                                 receiveInviteEvent,
                                 receiveConfirmEvent,
                                 disconnectedEvent
                                 ]];
  [self.stateMachine activate];
}

#pragma mark - state machine

- (void)startGame {
  
  NSAssert(self.session.peerId != nil, @"");
  
  if (![self.stateMachine.currentState.name isEqual:@"idle"]) {
    [self fireEvent:CUHostGameManagerDisconnectedEvent userInfo:nil];
  }
  
  AVObject *waitingId = [AVObject objectWithClassName:@"waiting_join_Ids"];
  [waitingId setObject:self.session.peerId forKey:@"peerId"];
  [waitingId saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    [self fireEvent:CUHostGameManagerWaitingJoinEvent userInfo:nil];
  }];
}

- (void)sendJoinConfirm {
  AVMessage *message = [AVMessage messageForPeerWithSession:self.session
                                                   toPeerId:self.peerId
                                                    payload:@"join_confirm"];
  [self.session sendMessage:message transient:YES];
}

#pragma mark - AVSessionDelegate
- (void)onSessionOpen:(AVSession *)session {
  NSLog(@"%s", __FUNCTION__);
}

- (void)onSessionPaused:(AVSession *)session {
  NSLog(@"%s", __FUNCTION__);
  [self fireEvent:CUHostGameManagerDisconnectedEvent userInfo:nil];
}

- (void)onSessionResumed:(AVSession *)seesion {
  NSLog(@"%s", __FUNCTION__);
  [self fireEvent:CUHostGameManagerDisconnectedEvent userInfo:nil];
}

- (void)sessionFailed:(AVSession *)session error:(NSError *)error
{
  NSLog(@"%s", __FUNCTION__);
  [self fireEvent:CUHostGameManagerDisconnectedEvent userInfo:nil];
}

- (void)session:(AVSession *)session didReceiveMessage:(AVMessage *)message
{
  if ([message.payload isEqualToString:@"join"]) {
    
    self.peerId = message.fromPeerId;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendInviteConfirmRequest:) object:nil];
    [self performSelector:@selector(sendInviteConfirmRequest:)
               withObject:@[message.fromPeerId]
               afterDelay:2.0f];
  }
  else if ([message.payload isEqualToString:@"go"]) {
    [self fireEvent:CUHostGameManagerReceiveConfirmEvent userInfo:nil];
  }
}

- (void)sendInviteConfirmRequest:(NSArray *)watchPeerIds {
  [self.session watchPeerIds:watchPeerIds];
  [self fireEvent:CUHostGameManagerReceiveInviteEvent userInfo:nil];
}

- (void)session:(AVSession *)session didReceiveStatus:(AVPeerStatus)status peerIds:(NSArray *)peerIds
{
  NSLog(@"peerIds :%@ statusId:%lu", peerIds, status);
}

- (void)session:(AVSession *)session messageSendFinished:(AVMessage *)message
{
  NSLog(@"%s", __FUNCTION__);
}

- (void)session:(AVSession *)session messageSendFailed:(AVMessage *)message error:(NSError *)error
{
  NSLog(@"%s", __FUNCTION__);
}

- (void)onSessionMessageSent:(AVSession *)session message:(NSString *)message toPeerIds:(NSArray *)peerIds{
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
