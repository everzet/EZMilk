/*
 
 The MIT License
 
 Copyright (c) 2009-2010 Konstantin Kudryashov <ever.zet@gmail.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import <Cocoa/Cocoa.h>
#import <CommonCrypto/CommonDigest.h>
#import "JSON.h"


@interface EZMilkService : NSObject {
  NSString* token;
  NSString* timeline;
  NSString* apiKey;
  NSString* apiSecret;
  NSDate*   lastApiCall;
}

@property (retain) NSString* token;
@property (retain) NSString* timeline;
@property (retain) NSString* apiKey;
@property (retain) NSString* apiSecret;
@property (retain) NSDate*   lastApiCall;

// Initializators
- (id)initWithApiKey:(NSString*)anApiKey andApiSecret:(NSString*)anApiSecret;
+ (EZMilkService*)sharedService;

// Authorization & helpers
- (NSString*)frob;
- (NSString*)authUrlForPerms:(NSString*)aPerms withFrob:(NSString*)aFrob;
- (NSString*)tokenWithFrob:(NSString*)aFrob;
- (void)getTimeline;

// Helpers
+ (NSString*)rtmDateFromDate:(NSDate*)aDate;
+ (NSDate*)dateFromRtmDate:(NSString*)anSqlDate;

// Response error checking
- (BOOL)noErrorsInResponse:(NSDictionary*)anResponse;
- (NSString*)errorMsgInResponse:(NSDictionary*)anResponse;

// Calling methods
- (NSDictionary*)dataByCallingMethod:(NSString*)aMethod error:(NSError**)error;
- (NSDictionary*)dataByCallingMethod:(NSString*)aMethod andParameters:(NSDictionary*)aParameters error:(NSError**)error;
- (NSDictionary*)dataByCallingMethod:(NSString*)aMethod andParameters:(NSDictionary*)aParameters withToken:(BOOL)useToken error:(NSError**)error;

// Generating urls with parameters, method name & token
- (NSString*)urlStringWithMethod:(NSString*)aMethod;
- (NSString*)urlStringWithMethod:(NSString*)aMethod andParameters:(NSDictionary*)aParameters;
- (NSString*)urlStringWithMethod:(NSString*)aMethod andParameters:(NSDictionary*)aParameters withToken:(BOOL)useToken;

// Generating url parameters & api_sig
- (NSString*)urlParametersWithDictionary:(NSDictionary*)aParameters;
- (NSString*)apiSigFromParameters:(NSDictionary*)aParameters;

@end
