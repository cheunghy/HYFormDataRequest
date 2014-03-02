HYFormDataRequest
=================

HYFormDataRequest is a very delightful NSMutableURLRequest Category that constructs multipart form data for you.

**Usage:**
    
    NSURL *url = [NSURL URLWithString:@"http://www.example.org/example"];
    NSMutableURLRequest *mutableURLRequest = [NSMutableURLRequest requestWithURL:url];
    
    [mutableURLRequest ky_setBoundaryString:@"EXAMPLE_BOUNDARY"];
    [mutableURLRequest ky_setValue:username forKey:@"username"];
    [mutableURLRequest ky_setValue:password forKey:@"password"];
    [mutableURLRequest ky_setValue:imageData forKey:@"avatar" contentType:"image/jpeg"];
    
    NSURLSessionDataTask *dataTask = [aURLSession dataTaskWithRequest:mutableURLRequest ...
