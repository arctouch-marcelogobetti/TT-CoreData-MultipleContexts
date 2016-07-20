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

#import <CoreData/CoreData.h>

@interface CoreDataStack : NSObject

+ (NSManagedObjectContext *)mainQueueMoc;
+ (NSManagedObjectContext *)createScratchpadMoc;
+ (NSManagedObjectContext *)createChildMocForMoc:(NSManagedObjectContext *)moc;
+ (NSManagedObjectContext *)createChildMoc;
+ (void)registerMainQueueMocObserver:(NSManagedObjectContext *)moc;
+ (void)removeMainQueueMocObserver:(NSManagedObjectContext *)moc;

@end
