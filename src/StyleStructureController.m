//
//  StyleStructureController.m
//  TTStyleBuilder
//
//  Created by Keith Lazuka on 6/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "StyleStructureController.h"
#import "StylePreview.h"
#import "StyleStructureDataSource.h"
#import "NewObjectPickerController.h"
#import "SettingsController.h"

@implementation StyleStructureController

- (id)initWithHeadStyle:(TTStyle *)style
{
    if ((self = [super init])) {
        self.title = @"Style Builder";
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(displayAddStylePicker)] autorelease];
        
        styleDataSource = [[StyleStructureDataSource alloc] initWithHeadStyle:style];
        
        previewView = [[StylePreview alloc] initWithFrame:CGRectZero];
        previewView.style = style;
        previewView.backgroundColor = [UIColor whiteColor];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLiveStylePreview) name:kRefreshStylePreviewNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stylePipelineUpdated:) name:kStylePipelineUpdatedNotification object:nil];
    }
    return self;
}

- (id)init
{
    return [self initWithHeadStyle:nil];
}

- (void)refreshLiveStylePreview
{
    [previewView setNeedsDisplay];
}

- (void)stylePipelineUpdated:(NSNotification *)notification
{
    id obj = [notification object];
    if (obj)
        NSAssert([obj isKindOfClass:[TTStyle class]], @"Style pipeline update notification payload must be either a TTStyle instance or nil.");
    previewView.style = obj;
    [self refreshLiveStylePreview];
}

- (void)displaySettingsScreen
{
    // Display settings for the "live preview" area
    SettingsController *controller = [[[SettingsController alloc] init] autorelease];
    [controller showObject:previewView inView:nil withState:nil];
    [self presentModalViewController:[[[UINavigationController alloc] initWithRootViewController:controller] autorelease] animated:YES];
}

- (void)displayAddStylePicker
{
    NewObjectPickerController *controller = [[[NewObjectPickerController alloc] initWithBaseClass:[TTStyle class]] autorelease];
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)appendStyleToPipeline:(TTStyle *)style
{
    NSAssert(style, @"style for appending cannot be nil");
    
    // Add the new style to the end of the rendering pipeline
    [styleDataSource appendStyle:style];
}

- (void)saveStyleToDisk
{
    // Save the TTStyle pipeline to disk
    NSString *fullPath = [StyleArchivesDir() stringByAppendingPathComponent:@"FooBar.ttstyle"];
    NSLog(@"Saving %@ to disk (%@)", [styleDataSource headStyle], fullPath);
    [[NSKeyedArchiver archivedDataWithRootObject:[styleDataSource headStyle]] writeToFile:fullPath atomically:YES];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NewObjectPickerDelegate

- (void)didPickNewObject:(id)newObject
{
    NSAssert1([newObject isKindOfClass:[TTStyle class]], @"expected new object to be of kind TTStyle, but its class is actually %@", [newObject className]);
    [self appendStyleToPipeline:newObject];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UIViewController

- (void)loadView
{
    [super loadView];
    
    const CGFloat stylePreviewHeight = 80.f;
    
    // Table view (each row is a style in the rendering pipeline)
    CGRect tableFrame = self.view.bounds;
    tableFrame.size.height -= stylePreviewHeight + TOOLBAR_HEIGHT;
    self.tableView = [[[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain] autorelease];
	self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    
    // Live preview display of the current rendering pipeline
    CGRect previewFrame = self.view.bounds;
    previewFrame.origin.y = self.view.height - stylePreviewHeight - TOOLBAR_HEIGHT;
    previewFrame.size.height = stylePreviewHeight;
    previewFrame = CGRectInset(previewFrame, 40.f, 10.f);
    [previewView setFrame:previewFrame];
    [self.view addSubview:previewView];
    
    UIToolbar *toolbar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0.f, self.view.height - TOOLBAR_HEIGHT, self.view.width, TOOLBAR_HEIGHT)] autorelease];
    NSMutableArray *items = [NSMutableArray array];
    [items addObject:[self editButtonItem]];
    [items addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    [items addObject:[[[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStyleBordered target:self action:@selector(displaySettingsScreen)] autorelease]];
    [items addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    [items addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveStyleToDisk)] autorelease]];
    [toolbar setItems:items];
    [self.view addSubview:toolbar];
}

// TODO This is a bug in Three20: 
//      TTTableViewController should do this.
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTTableViewController

- (id<TTTableViewDataSource>)createDataSource
{
    return styleDataSource;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTViewController

- (UIImage*)imageForNoData {
    return TTIMAGE(@"bundle://Three20.bundle/images/empty.png");
}

- (NSString*)titleForNoData {
    return NSLocalizedString(@"The style pipeline is empty", @"");
}

- (NSString*)subtitleForNoData {
    return NSLocalizedString(@"Tap the '+' button to add your first style node.", @"");
}

- (UIImage*)imageForError:(NSError*)error {
    return TTIMAGE(@"bundle://Three20.bundle/images/error.png");
}

- (NSString*)subtitleForError:(NSError*)error {
    return NSLocalizedString(@"There was an error displaying the style pipeline.", @"");
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)dealloc
{
    [styleDataSource release];
    [previewView release];
    [super dealloc];
}


@end
