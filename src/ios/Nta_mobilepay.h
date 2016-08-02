//
//  Nta_mobilepay.h
//  NTA Grabngo
//
//  Created by WSY on 04/05/2016.
//
//

#ifndef Nta_mobilepay_h
#define Nta_mobilepay_h
#import <Cordova/CDV.h>

@interface Nta_mobilepay : CDVPlugin

- (void)echo:(CDVInvokedUrlCommand*)command;
- (void)makePayment:(CDVInvokedUrlCommand*)command;
- (void)handleOpenURL:(NSNotification*)notification;

@end

#endif /* Nta_mobilepay_h */
