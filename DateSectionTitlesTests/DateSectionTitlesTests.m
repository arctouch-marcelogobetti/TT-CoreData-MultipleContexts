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

#import <XCTest/XCTest.h>
#import "CoreDataStack.h"

#define ITERATIONS 5000


@interface DateSectionTitlesTests : XCTestCase

@end


@implementation DateSectionTitlesTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)doSomething {
    for (int i = 0; i < 10; i++) {
        
    }
}

- (void)testChildrenPrivateMocsCreationFromStack {
    [CoreDataStack mainQueueMoc]; // ensuring initialization out of the measure block
    [self measureBlock:^{
        for (int i = 0; i < ITERATIONS; i++) {
            NSManagedObjectContext* privateQueueContext = [CoreDataStack createChildMoc];
            [privateQueueContext performBlock:^{
                [self doSomething];
            }];
        }
    }];
}

- (void)testChildrenPrivateMocsCreation {
    NSManagedObjectContext* mainQueueContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [self measureBlock:^{
        for (int i = 0; i < ITERATIONS; i++) {
            NSManagedObjectContext* privateQueueContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            privateQueueContext.parentContext = mainQueueContext;
            [privateQueueContext performBlock:^{
                [self doSomething];
            }];
        }
    }];
}

- (void)testThreadsCreation {
    [self measureBlock:^{
        for (int i = 0; i < ITERATIONS; i++) {
            NSThread *t = [[NSThread alloc] initWithTarget:self selector:@selector(doSomething) object:nil];
            t.threadPriority = 1.0;
            [t start];
        }
    }];
}

- (void)testDetachNewThread {
    [self measureBlock:^{
        for (int i = 0; i < ITERATIONS; i++) {
            [NSThread detachNewThreadSelector:@selector(doSomething) toTarget:self withObject:nil];
        }
    }];
}

- (void)testDispatchAsyncGlobalQueue {
    [self measureBlock:^{
        for (int i = 0; i < ITERATIONS; i++) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [self doSomething];
            });
        }
    }];
}

@end
