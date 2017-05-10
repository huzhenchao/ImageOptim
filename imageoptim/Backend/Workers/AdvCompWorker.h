//
//  AdvCompWorker.h
//
//  Created by porneL on 30.wrz.07.
//

#import <Cocoa/Cocoa.h>
#import "CommandWorker.h"

@interface AdvCompWorker : CommandWorker {
    NSInteger level;

	NSInteger fileSizeOptimized;
}

- (instancetype)initWithLevel:(NSInteger)opt file:(Job *)aFile;
@end
