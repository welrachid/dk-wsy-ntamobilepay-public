//
//  Nta_mobilepay.m
//  NTA Grabngo
//
//  Created by WSY on 04/05/2016.
//
//

#import "Nta_mobilepay.h"
#import <Cordova/CDV.h>
#import "MobilePayManager.h"
#import "MobilePayPayment.h"
#import "MobilePaySuccessfulPayment.h"
#import "MobilePayCancelledPayment.h"

@implementation Nta_mobilepay

- (void)echo:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* msg = [command.arguments objectAtIndex:0];
    
    if (msg == nil || [msg length] == 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    } else {
        /* http://stackoverflow.com/questions/18680891/displaying-a-message-in-ios-which-has-the-same-functionality-as-toast-in-android */
        UIAlertView *toast = [
                              [UIAlertView alloc] initWithTitle:@""
                              message:msg
                              delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:nil, nil];
        
        [toast show];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [toast dismissWithClickedButtonIndex:0 animated:YES];
        });
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:msg];
    }
    
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
- (void)makePayment:(CDVInvokedUrlCommand*)command
{
    NSDecimalNumber* price =[[NSDecimalNumber alloc] initWithString:[command.arguments objectAtIndex:0]];
    NSString* uuid = [command.arguments objectAtIndex:1];
    NSString* appswitch_id = [command.arguments objectAtIndex:2];
    NSString* url_scheme = [command.arguments objectAtIndex:3]; //ntamobilepaygrabngofeedyourmind

    [[MobilePayManager sharedInstance] setupWithMerchantId:appswitch_id merchantUrlScheme:url_scheme timeoutSeconds:90 captureType:MobilePayCaptureType_Reserve country:MobilePayCountry_Denmark];

    CDVPluginResult* pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"makepaymentSuccess"];
  
    MobilePayPayment *payment = [[MobilePayPayment alloc]initWithOrderId:uuid productPrice:price];
    //No need to start a payment if one or more parameters are missing
    if (payment && (payment.orderId.length > 0) && (payment.productPrice >= 0)) {
        
        [[MobilePayManager sharedInstance]beginMobilePaymentWithPayment:payment error:^(MobilePayErrorPayment * _Nullable MobilePayErrorPayment) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:MobilePayErrorPayment.error.localizedDescription
                                                            message:[NSString stringWithFormat:@"reason: %@, suggestion: %@",MobilePayErrorPayment.error.localizedFailureReason, MobilePayErrorPayment.error.localizedRecoverySuggestion]
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Install MobilePay",nil];
            [alert show];
            
        }];
        
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /*
     * INFO!!! See the example app for more details on how to use the SDK.
     */
    [[MobilePayManager sharedInstance] setupWithMerchantId:@"APPDK0000000000" merchantUrlScheme:@"ntamobilepaygrabngofeedyourmind" country:MobilePayCountry_Denmark];
    return YES;
}

-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
    //IMPORTANT - YOU MUST USE THIS IF YOU COMPILING YOUR AGAINST IOS9 SDK
    [self handleMobilePayPaymentWithUrl:url];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    //IMPORTANT - THIS IS DEPRECATED IN IOS9 - USE 'application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options' INSTEAD
    [self handleMobilePayPaymentWithUrl:url];
    return YES;
}

-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {

    //IMPORTANT - THIS IS DEPRECATED IN IOS9 - USE 'application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options' INSTEAD
    [self handleMobilePayPaymentWithUrl:url];
    return YES;
}
- (void)handleOpenURL:(NSNotification*)notification
{
    // override to handle urls sent to your app
    // register your url schemes in your App-Info.plist

    NSURL* url = [notification object];

    if ([url isKindOfClass:[NSURL class]]) {
        /* Do your thing! */
    }
    NSLog(@"TESTER OM HANDLE OPEN URL KALDES");
}
- (void)handleMobilePayPaymentWithUrl:(NSURL *)url
{
    [[MobilePayManager sharedInstance]handleMobilePayPaymentWithUrl:url success:^(MobilePaySuccessfulPayment * _Nullable mobilePaySuccessfulPayment) {
        NSString *orderId = mobilePaySuccessfulPayment.orderId;
        NSString *transactionId = mobilePaySuccessfulPayment.transactionId;
        NSString *amountWithdrawnFromCard = [NSString stringWithFormat:@"%f",mobilePaySuccessfulPayment.amountWithdrawnFromCard];
        NSLog(@"MobilePay purchase succeeded: Your have now paid for order with id '%@' and MobilePay transaction id '%@' and the amount withdrawn from the card is: '%@'", orderId, transactionId,amountWithdrawnFromCard);
        //[ViewHelper showAlertWithTitle:@"MobilePay Succeeded" message:[NSString stringWithFormat:@"You have now paid with MobilePay. Your MobilePay transactionId is '%@'", transactionId]];

    } error:^(MobilePayErrorPayment * _Nullable MobilePayErrorPayment) {
        NSDictionary *dict = MobilePayErrorPayment.error.userInfo;
        NSString *errorMessage = [dict valueForKey:NSLocalizedFailureReasonErrorKey];
        NSLog(@"MobilePay purchase failed:  Error code '%li' and message '%@'",(long)MobilePayErrorPayment.error.code,errorMessage);
        //[ViewHelper showAlertWithTitle:[NSString stringWithFormat:@"MobilePay Error %li",(long)error.code] message:errorMessage];

        //TODO: show an appropriate error message to the user. Check MobilePayManager.h for a complete description of the error codes

        //An example of using the MobilePayErrorCode enum
        //if (error.code == MobilePayErrorCodeUpdateApp) {
        //    NSLog(@"You must update your MobilePay app");
        //}
    } cancel:^(MobilePayCancelledPayment * _Nullable mobilePayCancelledPayment) {
        NSLog(@"MobilePay purchase with order id '%@' cancelled by user", mobilePayCancelledPayment.orderId);
        //[ViewHelper showAlertWithTitle:@"MobilePay Canceled" message:@"You cancelled the payment flow from MobilePay, please pick a fruit and try again"];

    }];
}
@end
