//
//  URLConnectionDemoViewController.m
//  CoconutKit-demo
//
//  Created by Samuel Défago on 11.04.12.
//  Copyright (c) 2012 Hortis. All rights reserved.
//

#import "URLConnectionDemoViewController.h"

#import "Coconut.h"
#import "CoconutTableViewCell.h"

@interface URLConnectionDemoViewController ()

@property (nonatomic, retain) HLSURLConnection *asynchronousConnection;
@property (nonatomic, retain) NSArray *coconuts;

@end

@implementation URLConnectionDemoViewController

#pragma mark Object creation and destruction

- (id)init
{
    if ((self = [super initWithNibName:[self className] bundle:nil])) {
        
    }
    return self;
}

- (void)dealloc
{
    self.asynchronousConnection = nil;
    self.coconuts = nil;
    
    [super dealloc];
}

- (void)releaseViews
{
    [super releaseViews];
    
    self.tableView = nil;
    self.asynchronousLoadButton = nil;
    self.cancelButton = nil;
    self.synchronousLoadButton = nil;
}

#pragma mark Accessors and mutators

@synthesize asynchronousConnection = m_asynchronousConnection;

@synthesize coconuts = m_coconuts;

@synthesize tableView = m_tableView;

@synthesize asynchronousLoadButton = m_asynchronousLoadButton;

@synthesize cancelButton = m_cancelButton;

@synthesize synchronousLoadButton = m_synchronousLoadButton;

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = [CoconutTableViewCell height];
    
    self.cancelButton.hidden = YES;
}

#pragma mark Orientation management

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (! [super shouldAutorotateToInterfaceOrientation:toInterfaceOrientation]) {
        return NO;
    }
    
    return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

#pragma mark Localization

- (void)localize
{
    [super localize];
    
    self.title = NSLocalizedString(@"Networking with HLSURLConnection", @"Networking with HLSURLConnection");
    
    // Must sort coconuts by name again when switching languages
    NSSortDescriptor *nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" 
                                                                         ascending:YES 
                                                                          selector:@selector(localizedCaseInsensitiveCompare:)];
    self.coconuts = [self.coconuts sortedArrayUsingDescriptor:nameSortDescriptor]; 
    
    [self reloadData];
}

#pragma mark HLSURLConnectionDelegate protocol implementation

- (void)connectionDidStart:(HLSURLConnection *)connection
{
    HLSLoggerInfo(@"Connection did start");
}

- (void)connectionDidProgress:(HLSURLConnection *)connection
{
    HLSLoggerInfo(@"Connection did progress (progress = %f)", connection.progress);
}

- (void)connectionDidFinish:(HLSURLConnection *)connection
{
    HLSLoggerInfo(@"Connection did finish");
    
    self.asynchronousLoadButton.hidden = NO;
    self.synchronousLoadButton.hidden = NO;
    self.cancelButton.hidden = YES;
        
    NSDictionary *coconutsDictionary = [NSDictionary dictionaryWithContentsOfFile:connection.downloadFilePath];
    NSArray *coconuts = [Coconut coconutsFromDictionary:coconutsDictionary];
    
    NSSortDescriptor *nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" 
                                                                         ascending:YES 
                                                                          selector:@selector(localizedCaseInsensitiveCompare:)];
    self.coconuts = [coconuts sortedArrayUsingDescriptor:nameSortDescriptor]; 
    
    [self reloadData];
}

- (void)connection:(HLSURLConnection *)connection didFailWithError:(NSError *)error
{
    HLSLoggerInfo(@"Connection did fail with error: %@", error);
    
    self.asynchronousLoadButton.hidden = NO;
    self.synchronousLoadButton.hidden = NO;
    self.cancelButton.hidden = YES;
    
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                         message:NSLocalizedString(@"The data could not be retrieved", @"The data could not be retrieved") 
                                                        delegate:nil 
                                               cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Dismiss")
                                               otherButtonTitles:nil] autorelease];
    [alertView show];
}

#pragma mark HLSReloadable protocol implementation

- (void)reloadData
{
    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource protocol implementation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.coconuts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    return [CoconutTableViewCell cellForTableView:tableView];
}

#pragma mark UITableViewDelegate protocol implementation

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    CoconutTableViewCell *tableViewCell = (CoconutTableViewCell *)cell;
    
    Coconut *coconut = [self.coconuts objectAtIndex:indexPath.row];
    
    // We must use a customm cell here. If we try to use a standard cell style and its imageView property, refresh does
    // not work correctly. UITableViewCell implementation probably does some nasty things under the hood
    if (coconut.thumbnailImageName) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[[NSURL URLWithString:@"http://localhost:8087"] URLByAppendingPathComponent:coconut.thumbnailImageName]
                                                 cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                             timeoutInterval:10.];
        [tableViewCell.thumbnailImageView loadWithImageRequest:request];
    }
    else {
        tableViewCell.thumbnailImageView.image = nil;
    }
    tableViewCell.nameLabel.text = coconut.name;
    tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
}

#pragma mark Event callbacks

- (IBAction)loadAsynchronously:(id)sender
{
    self.asynchronousLoadButton.hidden = YES;
    self.synchronousLoadButton.hidden = YES;
    self.cancelButton.hidden = NO;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8087/coconuts.plist"]
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                            timeoutInterval:10.];
    self.asynchronousConnection = [HLSURLConnection connectionWithRequest:request];
    self.asynchronousConnection.downloadFilePath = [HLSApplicationTemporaryDirectoryPath() stringByAppendingPathComponent:@"coconuts.plist"];
    
    self.asynchronousConnection.delegate = self;
    [self.asynchronousConnection start];
}

- (IBAction)cancel:(id)sender
{
    self.asynchronousLoadButton.hidden = NO;
    self.synchronousLoadButton.hidden = NO;
    self.cancelButton.hidden = YES;
    
    [self.asynchronousConnection cancel];
}

- (IBAction)loadSynchronously:(id)sender
{
    self.asynchronousLoadButton.hidden = YES;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8087/coconuts.plist"]
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                            timeoutInterval:10.];
    HLSURLConnection *connection = [HLSURLConnection connectionWithRequest:request];
    connection.downloadFilePath = [HLSApplicationTemporaryDirectoryPath() stringByAppendingPathComponent:@"coconuts.plist"];
    [connection startSynchronous];
}

@end
