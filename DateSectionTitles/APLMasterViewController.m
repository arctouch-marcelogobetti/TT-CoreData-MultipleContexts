
/*
     File: APLMasterViewController.m
 Abstract: Table view controller to display Events by section.
 
  Version: 2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "APLMasterViewController.h"
#import "APLEvent.h"
#import "CoreDataStack.h"
#import "NSManagedObjectContext+Convenient.h"
#import "NSString+Custom.h"


@interface APLMasterViewController ()
{
    NSFetchedResultsController* _fetchedResultsController;
    NSManagedObjectContext* _uiMoc;
}
@end


@implementation APLMasterViewController

- (NSManagedObjectContext *)uiMoc {
    if (_uiMoc != nil)
    {
        return _uiMoc;
    }
    
    _uiMoc = [CoreDataStack createScratchpadMoc];
    [CoreDataStack registerMainQueueMocObserver:_uiMoc];
    return _uiMoc;
}

- (void)dealloc {
    if ([self uiMoc]) {
        [CoreDataStack removeMainQueueMocObserver:[self uiMoc]];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	NSError *error;

	if (![[self fetchedResultsController] performFetch:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.

         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
    
    // Refresh control:
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(slowDataHandling:)
                  forControlEvents:UIControlEventValueChanged];
}

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSInteger count = [[[self fetchedResultsController] sections] count];
	return count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetchedResultsController] sections] objectAtIndex:section];

	NSInteger count = [sectionInfo numberOfObjects];
	return count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    /*
     Use a default table view cell to display the event's title.
     */
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	APLEvent *event = [[self fetchedResultsController] objectAtIndexPath:indexPath];
	cell.textLabel.text = event.title;

    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> theSection = [[[self fetchedResultsController] sections] objectAtIndex:section];

    /*
     Section information derives from an event's sectionIdentifier, which is a string representing the number (year * 1000) + month.
     To display the section title, convert the year and month components to a string representation.
     */
    static NSDateFormatter *formatter = nil;

    if (!formatter)
    {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setCalendar:[NSCalendar currentCalendar]];

        NSString *formatTemplate = [NSDateFormatter dateFormatFromTemplate:@"MMMM YYYY" options:0 locale:[NSLocale currentLocale]];
        [formatter setDateFormat:formatTemplate];
    }

    NSInteger numericSection = [[theSection name] integerValue];
	NSInteger year = numericSection / 1000;
	NSInteger month = numericSection - (year * 1000);
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = year;
    dateComponents.month = month;
    NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:dateComponents];

	NSString *titleString = [formatter stringFromDate:date];

	return titleString;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        id objectToDelete = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        NSManagedObjectContext *moc = [CoreDataStack createChildMocForMoc:[self uiMoc]];
        [moc performBlock:^{
            NSError* error;
            NSManagedObject* objectToDeleteInPrivateMoc = [moc existingObjectWithID:[objectToDelete objectID] error:&error];
            NSAssert(error == nil, @"Error while trying to access object to delete in the private MOC: %@", [error userInfo]);
            NSAssert(objectToDeleteInPrivateMoc, @"Returned object to delete is nil in the private MOC");
            
            [moc deleteObject:objectToDeleteInPrivateMoc];
            [moc save:&error]; // changes are pushed only 1 level up, i.e. only to the uiMoc, not to the PSC
            NSAssert(error == nil, @"Error while trying to save private MOC after deleting object: %@", [error userInfo]);
            
            if ([[self fetchedResultsController].fetchedObjects count] == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self onEditOrDoneTap:nil];
                });
            }
            
            [NSThread sleepForTimeInterval:5]; // simulating any kind of slow operation
            
            if (arc4random() % 2) {
                NSLog(@"Deletion authorized!");
                // save to the PSC:
                [[self uiMoc] performBlock:^{
                    [[self uiMoc] saveRecursively];
                }];
            }
            else {
                NSLog(@"Deletion denied.");
                // undo changes:
                [[self uiMoc] performBlock:^{
                    NSError* error;
                    [[self uiMoc] refreshObject:objectToDelete mergeChanges:NO];
                    [[self uiMoc] save:&error]; // no need to save parent contexts
                    NSAssert(error == nil, @"Error while trying to save the UI MOC after reverting deletion of object: %@", [error userInfo]);
                }];
            }
        }];
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
    {
        return _fetchedResultsController;
    }
    
    /*
	 Set up the fetched results controller.
     */
	// Create the fetch request for the entity.
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"APLEvent" inManagedObjectContext:[self uiMoc]];
	[fetchRequest setEntity:entity];

	// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:20];

	// Sort using the timeStamp property.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
	[fetchRequest setSortDescriptors:@[sortDescriptor ]];

    // Use the sectionIdentifier property to group into sections.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[self uiMoc] sectionNameKeyPath:@"sectionIdentifier" cacheName:nil];
    _fetchedResultsController.delegate = self;

	return _fetchedResultsController;
}

// begin: https://developer.apple.com/library/tvos/documentation/Cocoa/Conceptual/CoreData/nsfetchedresultscontroller.html
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}
// end: https://developer.apple.com/library/tvos/documentation/Cocoa/Conceptual/CoreData/nsfetchedresultscontroller.html

#pragma mark UI actions

- (void)slowDataHandling:(UIRefreshControl *)sender {
    NSManagedObjectContext *moc = [CoreDataStack createChildMoc];
    [moc performBlock:^{
        [NSThread sleepForTimeInterval:5]; // simulating any kind of slow operation
        APLEvent *newEvent = [NSEntityDescription insertNewObjectForEntityForName:@"APLEvent" inManagedObjectContext:moc];
        NSDate* date = [self randomDate];
        NSLog(@"%@", date);
        newEvent.timeStamp = date;
        newEvent.title = [NSString customStringFromDate:date];
        
        [moc saveRecursively];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
        });
    }];
}

- (NSDate *)randomDate {
    NSTimeInterval wholeInterval = [NSDate timeIntervalSinceReferenceDate];
    div_t d = div(wholeInterval, 86400);
    int daysInterval = d.quot;
    int randomDay = arc4random_uniform(daysInterval);
    return [NSDate dateWithTimeIntervalSinceReferenceDate:(double)randomDay * 86400.0];
}

- (IBAction)onEditOrDoneTap:(UIBarButtonItem *)sender {
    self.tableView.editing = !self.tableView.editing;
    
    UIBarButtonItem* barButtonItem;
    if (self.tableView.editing) {
        barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onEditOrDoneTap:)];
    }
    else {
        barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(onEditOrDoneTap:)];
    }
    
    self.navigationItem.leftBarButtonItem = barButtonItem;
}

@end
