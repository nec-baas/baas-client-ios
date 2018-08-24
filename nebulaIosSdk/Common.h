//
// Common header
//
//  COPYRIGHT (C) 2014-2018 NEC CORPORATION

#ifdef DEBUG
    #define DLog(fmt,...) NSLog((@"%s %d "fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
    #define DLog(...)
#endif
