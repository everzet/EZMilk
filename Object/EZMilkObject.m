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

#import "EZMilkObject.h"

static const char *property_getType(objc_property_t property)
{
  const char *attributes = property_getAttributes(property);
  char buffer[1 + strlen(attributes)];
  strcpy(buffer, attributes);
  char *state = buffer, *attribute;
  while ((attribute = strsep(&state, ",")) != NULL)
  {
    if (attribute[0] == 'T')
    {
      if (attribute[1] == 'i')
      {
        return [[NSString stringWithString:@"NSInteger"] cString];
      }
      else
      {
        return (const char *)[[NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4] bytes];
      }
    }
  }

  return "@";
}

@implementation EZMilkObject

@synthesize mid;

+ (EZMilkService*)service
{
  return [EZMilkService sharedService];
}

+ (NSString*)timeline
{
  return [[self service] timeline];
}

+ (NSString*)objectNamespace
{
  return @"";
}

+ (NSString*)deleteIdName
{
  return [NSString stringWithFormat:@"%@_id", [self objectNamespace]];
}

+ (NSString*)preparedMethod:(NSString*)method
{
  return [NSString stringWithFormat:@"%@.%@", [NSString stringWithFormat:@"rtm.%@s", [self objectNamespace]], method];
}

+ (NSArray*)itemsFromData:(NSDictionary*)aData
{
  NSDictionary* itemsSpaceData = [aData objectForKey:[NSString stringWithFormat:@"%@s", [self objectNamespace]]];
  if (NSOrderedSame == [[itemsSpaceData className] compare:@"NSCFDictionary"])
  {
    id itemsData = [itemsSpaceData objectForKey:[self objectNamespace]];
    if (NSOrderedSame == [[itemsData className] compare:@"NSCFArray"])
    {
      return itemsData;
    }
    else
    {
      return [NSArray arrayWithObject:itemsData];
    }
  }

  return [NSArray array];
}

+ (id)itemByDictionary:(NSDictionary*)aData
{
  id object = [[[self alloc] init] autorelease];
  [object populateWithDictionary:aData];

  return object;
}

+ (SEL)propertySetterFor:(NSString*)prop
{
  return NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",
                               [[prop substringToIndex:1] uppercaseString],
                               [prop substringFromIndex:1]]);
}

- (void)setProperty:(NSString*)prop ofType:(NSString*)type toValue:(NSString*)value
{
  id data = value;
  if (NSOrderedSame == [type compare:@"NSInteger"])
  {
    data = (id)[value integerValue];
  }
  if (NSOrderedSame == [type compare:@"NSDate"])
  {
    data = [EZMilkService dateFromRtmDate:value];
  }

  [self performSelector: [[self class] propertySetterFor:prop]
             withObject: data];
}

- (void)populateWithDictionary:(NSDictionary*)aData
{
  [self setMid:[[aData objectForKey:@"id"] integerValue]];

  NSArray* props = [[self class] syncableProperties];
  for (NSUInteger i = 0, count = [props count]; i < count; i++)
  {
    NSString* prop = [[props objectAtIndex:i] objectForKey:@"name"];
    NSString* type = [[props objectAtIndex:i] objectForKey:@"type"];

    if (nil != [aData objectForKey:prop])
    {
      [self setProperty:prop ofType:type toValue:[aData objectForKey:prop]];
    }
  }
}

+ (NSArray*)syncablePropertyNames
{
  return nil;
}

+ (NSArray*)syncableProperties
{
  NSArray* allowedProperties = [self syncablePropertyNames];
  NSMutableArray* props = [NSMutableArray array];
  NSUInteger outCount, i;

  objc_property_t *properties = class_copyPropertyList([self class], &outCount);
  for(i = 0; i < outCount; i++)
  {
    objc_property_t property = properties[i];
    const char* propName = property_getName(property);
    const char* propType = property_getType(property);
    if(propName)
    {
      NSString* propertyName = [NSString stringWithCString:propName encoding:[NSString defaultCStringEncoding]];
      NSString* propertyType = [NSString stringWithCString:propType encoding:[NSString defaultCStringEncoding]];

      if (nil == allowedProperties || NSNotFound != [allowedProperties indexOfObject:propertyName])
      {
        [props addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                          propertyName, @"name",
                          propertyType, @"type", nil]];
      }
    }
  }
  free(properties);

  return [NSArray arrayWithArray:props];
}

+ (NSArray*)getListFromDictionary:(NSDictionary*)data
{
  NSArray* itemsData = [self itemsFromData:data];
  NSMutableArray* items = [NSMutableArray array];

  for (NSUInteger i = 0, count = [itemsData count]; i < count; i++)
  {
    NSDictionary* itemData = [itemsData objectAtIndex:i];
    NSObject* item = [self itemByDictionary:itemData];

    if ([self conformsToProtocol:@protocol(EZMilkContainable)])
    {
      id <EZMilkContainable> container = [[[self alloc] init] autorelease];
      Class subitemsParser = [container subitemsParser];
      NSArray* subitems = [subitemsParser getListFromDictionary:itemData];
      [item performSelector: [[self class] propertySetterFor:[NSString stringWithFormat:@"%@s", [subitemsParser objectNamespace]]]
                 withObject: subitems];
    }

    [items addObject:item];
  }

  return [NSArray arrayWithArray:items];
}

+ (NSArray*)getList
{
  if ([self conformsToProtocol:@protocol(EZMilkListable)])
  {
    NSError* error = nil;
    NSDictionary* data = [self dataByCallingMethod: @"getList"
                                             error: &error];
    if (nil == data)
    {
      [NSApp presentError:error];
      
      return nil;
    }
    
    return [self getListFromDictionary:data];
  }
  else
  {
    @throw [NSException exceptionWithName: @"EZMilk objects list exception"
                                   reason: [NSString stringWithFormat:@"Object %@ doesn't conforms to listable protocol", [self className]]
                                 userInfo: nil];
  }

  return nil;
}

- (BOOL)delete
{
  if ([self conformsToProtocol:@protocol(EZMilkDeletable)])
  {
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                [[self class] timeline], @"timeline",
                                [NSString stringWithFormat:@"%d", mid], [[self class] deleteIdName], nil];
    
    NSError* error = nil;
    NSDictionary* data = [[self class] dataByCallingMethod: @"delete"
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
    @throw [NSException exceptionWithName: @"EZMilk object delete exception"
                                   reason: [NSString stringWithFormat:@"Object %@ doesn't conforms to deletable protocol", [self className]]
                                 userInfo: nil];
  }

  return NO;
}

+ (NSDictionary*)dataByCallingMethod:(NSString*)aMethod error:(NSError**)error
{
  return [[self service] dataByCallingMethod:[self preparedMethod:aMethod] error:error];
}

+ (NSDictionary*)dataByCallingMethod:(NSString*)aMethod andParameters:(NSDictionary*)aParameters error:(NSError**)error
{
  return [[self service] dataByCallingMethod:[self preparedMethod:aMethod] andParameters:aParameters error:error];
}

+ (NSDictionary*)dataByCallingMethod:(NSString*)aMethod andParameters:(NSDictionary*)aParameters withToken:(BOOL)useToken error:(NSError**)error
{
  return [[self service] dataByCallingMethod:[self preparedMethod:aMethod] andParameters:aParameters withToken:useToken error:error];
}

@end
