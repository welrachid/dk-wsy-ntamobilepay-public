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
    NSNumber* price = [command.arguments objectAtIndex:0];
    NSString* uuid = [command.arguments objectAtIndex:1];
    NSString* company_id = [command.arguments objectAtIndex:2];
    NSString* auherning = @"15";
    NSString* valby = @"16";


    if([company_id isEqualToString:auherning]){
	[[MobilePayManager sharedInstance] setupWithMerchantId:@"APPDK8490224001" merchantUrlScheme:@"ntamobilepaygrabngofeedyourmind" country:MobilePayCountry_Denmark];
    }
    if([company_id isEqualToString:valby]) {
	[[MobilePayManager sharedInstance] setupWithMerchantId:@"APPDK8749124001" merchantUrlScheme:@"ntamobilepaygrabngofeedyourmind" country:MobilePayCountry_Denmark];
    }
    CDVPluginResult* pluginResult = nil;
    float price_2 = [price floatValue];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"makepaymentSuccess"];
  
    MobilePayPayment *payment = [[MobilePayPayment alloc]initWithOrderId:uuid productPrice:price_2];
    //No need to start a payment if one or more parameters are missing
    if (payment && (payment.orderId.length > 0) && (payment.productPrice >= 0)) {
        
        [[MobilePayManager sharedInstance]beginMobilePaymentWithPayment:payment error:^(NSError * _Nonnull error) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                            message:[NSString stringWithFormat:@"reason: %@, suggestion: %@",error.localizedFailureReason, error.localizedRecoverySuggestion]
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

    } error:^(NSError * _Nonnull error) {
        NSDictionary *dict = error.userInfo;
        NSString *errorMessage = [dict valueForKey:NSLocalizedFailureReasonErrorKey];
        NSLog(@"MobilePay purchase failed:  Error code '%li' and message '%@'",(long)error.code,errorMessage);
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