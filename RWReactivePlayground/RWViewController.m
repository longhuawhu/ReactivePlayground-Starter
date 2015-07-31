//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

@property (nonatomic) BOOL passwordIsValid;
@property (nonatomic) BOOL usernameIsValid;
@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.signInService = [RWDummySignInService new];
  
  // handle text changes for both text fields
  RACSignal *vaildUserNameSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *text) {
      return @([self isValidUsername:text]);
  }];

  RACSignal *vaildPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *text) {
       return @([self isValidPassword:text]);
  }];
    
  RAC(self.usernameTextField, backgroundColor) = [vaildUserNameSignal map:^id(NSString *usernameValid) {
      return [usernameValid boolValue] ? [UIColor clearColor] : [UIColor yellowColor];
  }];
  
  RAC(self.passwordTextField, backgroundColor) = [vaildPasswordSignal map:^id(NSString *passwordValid) {
        return [passwordValid boolValue] ? [UIColor clearColor] : [UIColor yellowColor];
  }];
    
  RACSignal *signUpActionSignal = [RACSignal combineLatest:@[vaildUserNameSignal, vaildPasswordSignal] reduce:^id(NSString *usernameValid, NSString *passwordValid){
      return @([usernameValid boolValue] && [passwordValid boolValue]);
  }];
                                   
  [signUpActionSignal subscribeNext:^(NSString *validString) {
      self.signInButton.enabled = [validString boolValue];
  }];
    
  [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside]
   doNext:^(id x) {
       self.signInButton.enabled = NO;
       self.signInFailureText.hidden = YES;
   }]
   flattenMap:^id(id value) {
       return [self signInSignal];
   }]
   subscribeNext:^(NSString *signedIn) {
       self.signInButton.enabled = YES;
       BOOL success = [signedIn boolValue];
       self.signInFailureText.hidden = success;
       if (success) {
           [self performSegueWithIdentifier:@"signInSuccess" sender:self];
       }
      
  }];
                                   
    
  
  // initially hide the failure message
  self.signInFailureText.hidden = YES;
}

-(RACSignal *)signInSignal{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.signInService signInWithUsername:self.usernameTextField.text password:self.passwordTextField.text complete:^(BOOL success) {
            [subscriber sendNext:@(success)];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}

- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 3;
}


@end
