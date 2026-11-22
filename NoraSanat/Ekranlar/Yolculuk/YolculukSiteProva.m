// Yalnız simülatör CI'ında, yerli görünümün kurulmadığı -yalnizSite açılışı.
#import <TargetConditionals.h>
#if DEBUG && TARGET_OS_SIMULATOR
#import <Foundation/Foundation.h>
extern void NoraYolculukSiteProva(void);
__attribute__((constructor))
static void YolculukProvasiniBaslat(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *args = NSProcessInfo.processInfo.arguments;
        if ([args containsObject:@"-yolculukProva"] && [args containsObject:@"-yalnizSite"]) {
            NoraYolculukSiteProva();
        }
    });
}
#endif
