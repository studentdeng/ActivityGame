//
//  ViewController.m
//  ActivityGame
//
//  Created by curer on 10/27/14.
//  Copyright (c) 2014 lion. All rights reserved.
//

#import "ViewController.h"
#import "CUSessionManager.h"
#import <AVOSCloud/AVOSCloud.h>
#import "NSString+MD5.h"
#import "CUHostGameManager.h"
#import "CUGestGameManager.h"

@interface KAMessage : NSObject

- (id)initWithMessage:(NSString *)message fromMe:(BOOL)fromMe;

@property (nonatomic, strong, readonly) NSString *message;
@property (nonatomic, readonly) BOOL fromMe;

@end

@implementation KAMessage

- (id)initWithMessage:(NSString *)message fromMe:(BOOL)fromMe;
{
  self = [super init];
  if (self) {
    _fromMe = fromMe;
    _message = message;
  }
  
  return self;
}

@end

@interface ViewController ()<AVSessionDelegate>
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;
@property (nonatomic, strong) AVSession *session;

@property (nonatomic, strong) CUHostGameManager *hostGameManager;
@property (nonatomic, strong) CUGestGameManager *gestGameManager;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)setupSession {
  if (self.session.isOpen) {
    [self.session close];
  }
  
  self.session = [[CUSessionManager sharedInstance] createSession];
  [self.session openWithPeerId:[self myPeerId]];
}

- (NSString *)myPeerId {
  NSString *displayName = self.nameTextField.text;
  return displayName;
  return displayName.MD5Hash;
}

#pragma mark - action
- (IBAction)createGame:(id)sender {
  [self setupSession];
  
  self.hostGameManager = [[CUHostGameManager alloc] initWithSession:self.session];
  self.session.sessionDelegate = self.hostGameManager;
  [self.hostGameManager startGame];
}

- (IBAction)joinGame:(id)sender {
  [self setupSession];
  
  self.gestGameManager = [[CUGestGameManager alloc] initWithSession:self.session];
  self.session.sessionDelegate = self.gestGameManager;
  [self.gestGameManager joinGame];
}


@end
