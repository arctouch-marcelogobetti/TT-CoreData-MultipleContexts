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

#import "AddItemViewController.h"
#import "APLEvent.h"
#import "CoreDataStack.h"
#import "NSManagedObjectContext+Convenient.h"
#import "NSString+Custom.h"

@interface AddItemViewController()
{
    __weak IBOutlet UIDatePicker* _datePicker;
}
@end


@implementation AddItemViewController : UIViewController

- (IBAction)addItem:(UIBarButtonItem *)sender {
    NSDate *date = [_datePicker date];
    if (!date) {
        return;
    }
    
    NSManagedObjectContext* privateMoc = [CoreDataStack privateQueueMoc];
    APLEvent *newEvent = [NSEntityDescription insertNewObjectForEntityForName:@"APLEvent" inManagedObjectContext:privateMoc];
    newEvent.timeStamp = date;
    newEvent.title = [NSString customStringFromDate:date];
    [privateMoc saveAll];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end