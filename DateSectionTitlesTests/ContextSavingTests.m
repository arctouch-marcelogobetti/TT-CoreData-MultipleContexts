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
#import "APLEvent.h"
#import "CoreDataStack.h"
#import "NSManagedObjectContext+Convenient.h"

#define ITERATIONS 1000


@interface ContextSavingTests : XCTestCase
{
    NSManagedObjectContext* _moc;
}
@end


@implementation ContextSavingTests

- (void)setUp {
    [super setUp];
    _moc = [CoreDataStack mainQueueMoc];
    NSArray* allObjects = [_moc executeFetchRequest:[self fetchRequest] error:nil];
    for (id obj in allObjects) {
        [_moc deleteObject:obj];
    }
    NSAssert([_moc countForFetchRequest:[self fetchRequest] error:nil] == 0, @"The test can only start if the database is clean");
}

- (void)tearDown {
    [super tearDown];
}

- (void)insertEntity {
    APLEvent *newEvent = [NSEntityDescription insertNewObjectForEntityForName:@"APLEvent" inManagedObjectContext:_moc];
    NSDate* date = [NSDate date];
    newEvent.timeStamp = date;
    newEvent.title = [date description];
}

- (NSFetchRequest *)fetchRequest {
    return [NSFetchRequest fetchRequestWithEntityName:@"APLEvent"];
}

- (void)testMassiveInsertionsAndSaves {
    __block int n = 0;
    [self measureBlock:^{
        for (int i = 0; i < ITERATIONS; i++) {
            [self insertEntity];
            [_moc saveRecursively];
        }
        n++;
    }];
    XCTAssertEqual([_moc countForFetchRequest:[self fetchRequest] error:nil], n * ITERATIONS);
}

- (void)testMassiveInsertionsWithSingleSave {
    __block int n = 0;
    [self measureBlock:^{
        for (int i = 0; i < ITERATIONS; i++) {
            [self insertEntity];
        }
        [_moc saveRecursively];
        n++;
    }];
    XCTAssertEqual([_moc countForFetchRequest:[self fetchRequest] error:nil], n * ITERATIONS);
}

@end
