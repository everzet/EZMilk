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

#import "EZMilkService.h"

#define EZM_API_KEY   @"api_key"
#define EZM_PERMS     @"perms"
#define EZM_FROB      @"frob"
#define EZM_TOKEN     @"token"
#define EZM_AUTH      @"auth"
#define EZM_TIMELINE  @"timeline"

static EZMilkService* sharedEZMilkService = nil;

NSString* md5(NSString *str)
{
  const char *cStr = [str UTF8String];
  unsigned char result[CC_MD5_DIGEST_LENGTH];
  CC_MD5(cStr, strlen(cStr), result);
  return [[NSString stringWithFormat:
           @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
           result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
           result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
           ] lowercaseString];
}

NSComparisonResult sortParameterKeysByChars(NSString* string1, NSString* string2, NSInteger charNum)
{
  if ([string1 length] == (charNum + 1) || [string2 length] == (charNum + 1))
  {
    return NSOrderedSame;
  }
  
  char v1 = [string1 characterAtIndex:charNum];
  char v2 = [string2 characterAtIndex:charNum];
  
  if (v1 < v2)
  {
    return NSOrderedAscending;
  }
  else if (v1 > v2)
  {
    return NSOrderedDescending;
  }
  else
  {
    return sortParameterKeysByChars(string1, string2, charNum + 1);
  }
}

NSComparisonResult sortParameterKeys(NSString* string1, NSString* string2, void *context)
{
  return sortParameterKeysByChars(string1, string2, 0);
}

@implementation EZMilkService

@synthesize apiKey, apiSecret, lastApiCall, token, timeline;

- (id)initWithApiKey:(NSString*)anApiKey andApiSecret:(NSString*)anApiSecret
{
  [self setApiKey:anApiKey];
  [self setApiSecret:anApiSecret];

  return [self init];
}

- (id)init
{
  if (!(self = [super init]))
  {
    return nil;
  }
  sharedEZMilkService = self;

  return self;
}

+ (EZMilkService*)sharedService
{
	return sharedEZMilkService;
}

- (void)dealloc
{
  [timeline release];
  [token release];
  [apiKey release];
  [apiSecret release];
  [lastApiCall release];
  
  [super dealloc];
}

- (NSString*)timeline
{
  if (!timeline)
  {
    [self getTimeline];
  }

  return timeline;
}

- (void)getTimeline
{
  NSError* error = nil;
  NSDictionary* response = [self dataByCallingMethod:@"rtm.timelines.create" error:&error];

  if (nil != response)
  {
    [self setTimeline:[[response objectForKey:EZM_TIMELINE] retain]];
  }
  else
  {
    [NSApp presentError:error];

    return;
  }
}

- (NSString*)frob
{
  NSError* error = nil;
  NSDictionary* response = [self dataByCallingMethod:@"rtm.auth.getFrob" andParameters:[NSDictionary dictionary] error:&error];
  
  if (nil != response)
  {
    return [response objectForKey:EZM_FROB];
  }
  else
  {
    [NSApp presentError:error];
    
    return nil;
  }
}

- (NSString*)tokenWithFrob:(NSString*)aFrob
{
  NSError* error = nil;
  NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                              aFrob, EZM_FROB, nil];
  NSDictionary* response = [self dataByCallingMethod:@"rtm.auth.getToken" andParameters:parameters error:&error];
  
  if (nil != response)
  {
    return [[response objectForKey:EZM_AUTH] objectForKey:EZM_TOKEN];
  }
  else
  {
    [NSApp presentError:error];

    return nil;
  }
}

- (NSString*)authUrlForPerms:(NSString*)aPerms withFrob:(NSString*)aFrob
{
  NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                              apiKey, EZM_API_KEY,
                              aPerms, EZM_PERMS,
                              aFrob,  EZM_FROB, nil];
  NSString* parametersString = [self urlParametersWithDictionary:parameters];
  
  return [NSString stringWithFormat:@"http://www.rememberthemilk.com/services/auth/?%@api_sig=%@",
          parametersString, [self apiSigFromParameters:parameters]];
}

+ (NSString*)rtmDateFromDate:(NSDate*)aDate
{
  NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
  [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
  NSString* dateString = [dateFormatter stringFromDate:aDate];
  [dateFormatter release];
  
  return dateString;
}

+ (NSDate*)dateFromRtmDate:(NSString*)anSqlDate
{
  NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
  [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
  NSDate* date = [dateFormatter dateFromString:anSqlDate];
  [dateFormatter release];
  
  return date;
}

- (BOOL)noErrorsInResponse:(NSDictionary*)anResponse
{
  return (NSOrderedSame == [[anResponse objectForKey:@"stat"] localizedCaseInsensitiveCompare:@"ok"]);
}

- (NSString*)errorMsgInResponse:(NSDictionary*)anResponse
{
  return [[anResponse objectForKey:@"err"] objectForKey:@"msg"];
}

- (NSDictionary*)dataByCallingMethod:(NSString*)aMethod error:(NSError**)error
{
  return [self dataByCallingMethod:aMethod andParameters:nil withToken:YES error:error];
}

- (NSDictionary*)dataByCallingMethod:(NSString*)aMethod andParameters:(NSDictionary*)aParameters error:(NSError**)error
{
  return [self dataByCallingMethod:aMethod andParameters:aParameters withToken:YES error:error];
}

- (NSDictionary*)dataByCallingMethod:(NSString*)aMethod andParameters:(NSDictionary*)aParameters withToken:(BOOL)useToken error:(NSError**)error
{
  // Checking that last API call was made more than a second ago & if not - waiting for a second (RTM recomendations)
  if (lastApiCall && (([lastApiCall timeIntervalSinceNow] * -1.0) < 1.0))
  {
    [NSThread sleepForTimeInterval:1.0 - ([lastApiCall timeIntervalSinceNow] * -1)];
  }

  NSURL* url = [NSURL URLWithString:[self urlStringWithMethod:aMethod andParameters:aParameters withToken:useToken]];
  NSString* response = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
  [self setLastApiCall:[NSDate date]];

  NSDictionary* data = [[response JSONValue] objectForKey:@"rsp"];

  if (![self noErrorsInResponse:data])
  {
    NSDictionary* errorDetail = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSString stringWithFormat:@"RTM API Error:\n%@", [self errorMsgInResponse:data]], NSLocalizedDescriptionKey,
                                 nil];
    *error = [NSError errorWithDomain:@"EZMilk" code:100 userInfo:errorDetail];

    return nil;
  }

  return data;
}

- (NSString*)urlParametersWithDictionary:(NSDictionary*)aParameters
{
  NSMutableString* parametersString = [NSMutableString string];
  NSArray* keys = [aParameters allKeys];

  for (int i = 0; i < [keys count]; i++)
  {
    NSString* key = [NSString stringWithString:[keys objectAtIndex:i]];
    [parametersString appendFormat:@"%@=%@&", key, [aParameters objectForKey:key]];
  }

  return [NSString stringWithString:parametersString];
}

- (NSString*)urlStringWithMethod:(NSString*)aMethod
{
  return [self urlStringWithMethod:aMethod andParameters:nil withToken:YES];
}

- (NSString*)urlStringWithMethod:(NSString*)aMethod andParameters:(NSDictionary*)aParameters
{
  return [self urlStringWithMethod:aMethod andParameters:aParameters withToken:YES];
}

- (NSString*)urlStringWithMethod:(NSString*)aMethod andParameters:(NSDictionary*)aParameters withToken:(BOOL)useToken
{
  NSMutableDictionary* parameters;
  parameters = (nil != aParameters) ? [[aParameters mutableCopy] autorelease] : [NSMutableDictionary dictionary];

  [parameters setObject:apiKey forKey:@"api_key"];
  [parameters setObject:aMethod forKey:@"method"];
  [parameters setObject:@"json" forKey:@"format"];
  [parameters setObject:[NSString stringWithFormat:@"%d", [NSDate timeIntervalSinceReferenceDate]] forKey:@"nocache"];

  if (useToken && nil != token)
  {
    [parameters setObject:token forKey:@"auth_token"];
  }

  NSString* parametersString = [self urlParametersWithDictionary:parameters];
  NSString* signedParameters = [self apiSigFromParameters:parameters];
  NSString* url = [[NSString stringWithFormat:@"http://api.rememberthemilk.com/services/rest/?%@api_sig=%@",
                    parametersString, signedParameters] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  NSLog(@"RTM URL: %@", url);

  return url;
}

- (NSString*)apiSigFromParameters:(NSDictionary*)aParameters
{
  NSArray* sortedKeys = [[aParameters allKeys] sortedArrayUsingFunction:sortParameterKeys context:nil];
  NSMutableString* parametersString = [NSMutableString stringWithString:apiSecret];

  for (int i = 0; i < [sortedKeys count]; i++)
  {
    NSString* key = [NSString stringWithString:[sortedKeys objectAtIndex:i]];
    [parametersString appendFormat:@"%@%@", key, [aParameters objectForKey:key]];
  }

  return [md5(parametersString) lowercaseString];
}

@end
