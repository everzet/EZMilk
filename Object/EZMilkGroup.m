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

#import "EZMilkGroup.h"


@implementation EZMilkGroup

@synthesize name, contacts;

- (void)dealloc
{
  [name release];
  [contacts release];

  [super dealloc];
}

+ (NSString*)objectNamespace
{
  return @"group";
}

+ (NSArray*)syncablePropertyNames
{
  return [NSArray arrayWithObjects:@"name", nil];
}

- (Class)subitemsParser
{
  return [EZMilkContact class];
}

+ (EZMilkGroup*)add:(NSString*)aName
{
  EZMilkGroup* object = [[[self alloc] init] autorelease];
  [object setName:aName];

  if ([object add])
  {
    return object;
  }
  else
  {
    return nil;
  }
}

- (BOOL)add
{
  if (name)
  {
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                [[self class] timeline], @"timeline",
                                name, @"group", nil];

    NSError* error = nil;
    NSDictionary* data = [[self class] dataByCallingMethod: @"add"
                                             andParameters: parameters
                                                     error: &error];
    if (nil == data)
    {
      [NSApp presentError:error];

      return NO;
    }
    [self populateWithDictionary:[data objectForKey:@"group"]];

    return YES;
  }
  else
  {
    return NO;
  }
}

- (BOOL)addContact:(EZMilkContact*)contact
{
  if (mid && [contact mid])
  {
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                [[self class] timeline], @"timeline",
                                [NSString stringWithFormat:@"%d", mid], @"group_id",
                                [NSString stringWithFormat:@"%d", [contact mid]], @"contact_id", nil];

    NSError* error = nil;
    NSDictionary* data = [[self class] dataByCallingMethod: @"addContact"
                                             andParameters: parameters
                                                     error: &error];
    if (nil == data)
    {
      [NSApp presentError:error];

      return NO;
    }

    return YES;
  }
  else
  {
    return NO;
  }
}

- (BOOL)removeContact:(EZMilkContact*)contact
{
  if (mid && [contact mid])
  {
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                [[self class] timeline], @"timeline",
                                [NSString stringWithFormat:@"%d", mid], @"group_id",
                                [NSString stringWithFormat:@"%d", [contact mid]], @"contact_id", nil];
    
    NSError* error = nil;
    NSDictionary* data = [[self class] dataByCallingMethod: @"removeContact"
                                             andParameters: parameters
                                                     error: &error];
    if (nil == data)
    {
      [NSApp presentError:error];
      
      return NO;
    }
    
    return YES;
  }
  else
  {
    return NO;
  }
}

@end
