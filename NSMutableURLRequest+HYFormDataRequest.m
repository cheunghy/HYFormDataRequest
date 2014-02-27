/*
 Copyright (c) 2014 Zhang Kai Yu
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "NSMutableURLRequest+HYFormDataRequest.h"
#import <objc/runtime.h>

NSString const * kBoundaryStringKey = @"kBoundaryStringKey";
NSString const * kFormDataBodyKey = @"kFormDataBodyKey";
NSString const * kFormDataContentTypeKey = @"kFormDataContentTypeKey";

@implementation NSMutableURLRequest (HYFormDataRequest)

#pragma mark - Associated Accessors

- (NSString *)ky_boundaryString
{
    NSString *boundaryString = objc_getAssociatedObject(self, &kBoundaryStringKey);
    if (!boundaryString) {
        return @"UNIQUE_BOUNDARY_I_AM";
    } else return boundaryString;
}

- (void)ky_setFormDataBody:(NSMutableDictionary *)body
{
    objc_setAssociatedObject(self, &kFormDataBodyKey, body, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)ky_formDataBody
{
    NSMutableDictionary *body = objc_getAssociatedObject(self, &kFormDataBodyKey);
    if (!body) {
        [self ky_setFormDataBody:[NSMutableDictionary dictionary]];
        return [self ky_formDataBody];
    }
    return body;
}

- (void)ky_setFormDataContentTypeDictionary:(NSMutableDictionary *)dictionary
{
    objc_setAssociatedObject(self, &kFormDataContentTypeKey, dictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)ky_formDataContentTypeDictionary
{
    NSMutableDictionary *contentTypeDic = objc_getAssociatedObject(self, &kFormDataContentTypeKey);
    if (!contentTypeDic) {
        [self ky_setFormDataContentTypeDictionary:[NSMutableDictionary dictionary]];
        return [self ky_formDataContentTypeDictionary];
    }
    return contentTypeDic;
}

#pragma mark - Reconstruct Methods

- (void)ky_setContentType
{
    NSString *boundaryString = [self ky_boundaryString];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundaryString];
    [self setValue:contentType forHTTPHeaderField:@"Content-Type"];
}

- (void)ky_setHTTPMethod
{
    [self setHTTPMethod:@"POST"];
}

- (void)ky_reconstructHTTPBody
{
    [self ky_setHTTPMethod];
    [self ky_setContentType];
    
    NSMutableData *mutableBody = [NSMutableData data];
    
    NSMutableDictionary *body = [self ky_formDataBody];
    NSMutableDictionary *contentType = [self ky_formDataContentTypeDictionary];
    
    [body enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        NSAssert([obj isKindOfClass:[NSData class]] || [obj isKindOfClass:[NSString class]], @"Value Must Be NSData Or NSString");
        
        [mutableBody appendData:[self ky_boundaryData]];
        NSString *contentDisposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n", key];
        [mutableBody appendData:[contentDisposition dataUsingEncoding:NSUTF8StringEncoding]];
        if (contentType[key]) {
            NSString *contentTypeString = [NSString stringWithFormat:@"Content-Type: %@\r\n", contentType[key]];
            [mutableBody appendData:[contentTypeString dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [mutableBody appendData:[self ky_crlfData]];
        if ([obj isKindOfClass:[NSData data]]) {
            [mutableBody appendData:obj];
        } else if ([obj isKindOfClass:[NSString class]]) {
            [mutableBody appendData:[obj dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [mutableBody appendData:[self ky_crlfData]];
        
    }];
    
    [mutableBody appendData:[self ky_lastBoundaryData]];
    
    [self setHTTPBody:[mutableBody copy]];
    
//    NSString *bodyString = [[NSString alloc] initWithData:self.HTTPBody encoding:NSUTF8StringEncoding];
//    NSLog(@"HTTP BODY DEBUG LOG:\n %@", bodyString);
}

#pragma mark - Data Construct Helper Methods

- (NSData *)ky_boundaryData
{
    NSString *realBoundary = [NSString stringWithFormat:@"\r\n--%@\r\n", [self ky_boundaryString]];
    return [realBoundary dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)ky_lastBoundaryData
{
    NSString *lastBoundary = [NSString stringWithFormat:@"\r\n--%@--", [self ky_boundaryString]];
    return [lastBoundary dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)ky_crlfData
{
    NSString *crlf = [NSString stringWithFormat:@"\r\n"];
    return [crlf dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark - User Methods

- (void)ky_setBoundaryString:(NSString *)boundaryString
{
    NSAssert([boundaryString length] <= 70, @"Boundary String Must Be No Longer Than 70 Characters!");
    objc_setAssociatedObject(self, &kBoundaryStringKey, boundaryString, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self ky_reconstructHTTPBody];
}

- (void)ky_setValue:(id)value forKey:(NSString *)key
{
    return [self ky_setValue:value forKey:key contentType:nil];
}

- (void)ky_setValue:(id)value forKey:(NSString *)key contentType:(NSString *)contentType
{
    NSAssert([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSData class]], @"Value Must Be NSString or NSData, Must Not Be Nil");
    
    NSMutableDictionary *body = [self ky_formDataBody];
    [body setValue:value forKey:key];
    if (contentType && [contentType length] != 0) {
        NSMutableDictionary *contentType = [self ky_formDataContentTypeDictionary];
        [contentType setValue:contentType forKey:key];
    }
    [self ky_reconstructHTTPBody];
}

@end
