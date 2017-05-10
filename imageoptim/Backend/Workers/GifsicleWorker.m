
#import "GifsicleWorker.h"
#import "../Job.h"
#import "../TempFile.h"

@implementation GifsicleWorker

- (instancetype)initWithInterlace:(BOOL)yn quality:(NSUInteger)aQuality file:(Job *)aFile {
    if ((self = [super initWithFile:aFile])) {
        quality = aQuality;
        interlace = yn;
    }
    return self;
}

-(NSInteger)settingsIdentifier {
    return interlace + 2*quality;
}

-(BOOL)optimizeFile:(File *)file toTempPath:(NSURL *)temp {

    NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-o",temp.path,
                            interlace ? @"--interlace" : @"--no-interlace",
                            @"-O3",
                            @"--careful",/* needed for Safari/Preview decoding bug */
                            @"--no-comments",@"--no-names",@"--same-delay",@"--same-loopcount",@"--no-warnings",
                            @"--",file.path,nil];

    BOOL isLossy = quality < 100;

    if (isLossy) {
        int loss = pow(100 - quality, 1.8) / 5.0;
        if ([file isSmall]) {
            loss = 1 + loss / 8; // Spare GIF icons
        } else if (![file isLarge]) {
            loss = 1 + loss / 2; // Spare GIF images
        }
        [args insertObject:[NSString stringWithFormat:@"--lossy=%d", loss] atIndex:0];
    }

    if (![self taskForKey:@"Gifsicle" bundleName:@"gifsicle" arguments:args]) {
        return NO;
    }

    NSFileHandle *devnull = [NSFileHandle fileHandleWithNullDevice];

    [task setStandardInput:devnull];
    [task setStandardError:devnull];
    [task setStandardOutput:devnull];

    [self launchTask];
    BOOL ok = [self waitUntilTaskExit];

    [devnull closeFile];

    if (!ok) return NO;

    NSString *toolName = isLossy ? @"Giflossy" : (interlace ? @"Gifsicle interlaced" : @"Gifsicle");

    TempFile *output = [file tempCopyOfPath:temp];
    if (!output) {
        return NO;
    }

    if (isLossy) {
        BOOL isSignificantlySmaller = output.byteSize * (105 + (100 - quality)/2) / 100 < file.byteSize;
        if (!isSignificantlySmaller) {
            return NO;
        }
    }

    return [job setFileOptimized:output toolName:toolName];
}

@end
