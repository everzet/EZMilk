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

#import "EZMilkContact.h"


@implementation EZMilkContact

@synthesize fullname, username;

- (void)dealloc
{
  [fullname release];
  [username release];

  [super dealloc];
}

+ (NSString*)objectNamespace
{
  return @"contact";
}

+ (EZMilkContact*)addByContact:(NSString*)anContact
{
  id object = [[[self alloc] init] autorelease];

  if ([object addByContact:anContact])
  {
    return object;
  }
  else
  {
    return nil;
  }
}

- (BOOL)addByContact:(NSString*)anContact
{
  NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                              [[self class] timeline], @"timeline",
                              anContact, @"contact", nil];

  NSError* error = nil;
  NSDictionary* data = [[self class] dataByCallingMethod: @"add"
                                           andParameters: parameters
                                                   error: &error];
  if (nil == data)
  {
    [NSApp presentError:error];
    
    return NO;
  }

  [self populateWithDictionary:[data objectForKey:@"contact"]];

  return YES;
}

- (BOOL)add
{
  if (username)
  {
    return [self addByContact:username];
  }
  else
  {
    return NO;
  }
}

@end
