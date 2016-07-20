//
// Copyright 2016 ArcTouch LLC.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

#import "NSManagedObjectContext+Convenient.h"

@implementation NSManagedObjectContext (Convenient)

NSInteger _requestsToSaveToDisk;

- (void)saveRecursively {
    [self saveAndHandle];
    if (!self.parentContext) {
        return;
    }
    
    NSManagedObjectContext* parentContext = self.parentContext;
    if (!parentContext.parentContext) {
        // parentContext is the master context
        [self requestToSaveMoc:parentContext];
        return;
    }
    
    [parentContext performBlockAndWait:^{
        [parentContext saveRecursively];
    }];
}

- (void)requestToSaveMoc:(NSManagedObjectContext *)moc {
    _requestsToSaveToDisk++;
    if (_requestsToSaveToDisk == 10) {
        [moc performBlockAndWait:^{
            [moc saveAndHandle];
        }];
        _requestsToSaveToDisk = 0;
    }
}

// copied from Apple's APLAppDelegate
- (void)saveAndHandle {
    NSError *error;
    if (![self hasChanges]) {
        return;
    }
    
    if (![self obtainPermanentIDsForObjects:self.insertedObjects.allObjects error:&error]
        || ![self save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}
@end
