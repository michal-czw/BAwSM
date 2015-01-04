//
//  RecordedVideosViewController.m
//  iCarTools
//
//  Created by Michał Czwarnowski on 03.01.2015.
//  Copyright (c) 2015 Michał Czwarnowski. All rights reserved.
//

#import "RecordedVideosViewController.h"

@interface RecordedVideosViewController ()

@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) MPMoviePlayerViewController *moviePlayer;

@end

@implementation RecordedVideosViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        _path =[documentsDirectory stringByAppendingPathComponent:@"/iCarTools"];
        _wantsCustomAnimation = YES;
        _videosArray = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Recorded videos", nil)];
    navigationItem.leftBarButtonItem = barButton;
    [_navigationBar pushNavigationItem:navigationItem animated:NO];
    
    [_videosTableView setRowHeight:80.0];
    [_videosTableView setEstimatedRowHeight:80.0];
    
    _videosArray = [[NSMutableArray alloc] initWithArray:[self listFileAtPath]];
    
    [_videosTableView reloadData];
}

- (void) cancelAction:(id)sender {
    [self.revealViewController setFrontViewController:_parentView animated:YES];
    _parentView = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"singleVideoCell";
    RecordedVideosTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"singleVideoCell"];
    
    if (cell == nil) {
        cell = [[RecordedVideosTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
    [cell setTitleText:[NSString stringWithFormat:@"%@%d", NSLocalizedString(@"Video #", nil), [[NSNumber numberWithInteger:indexPath.row + 1] intValue]]
              dateText:[[_videosArray objectAtIndex:indexPath.row] objectForKey:@"date"]
        movieThumbnail:[UIImage imageWithData:[[_videosArray objectAtIndex:indexPath.row] objectForKey:@"thumbnail"]]
                 route:[[[_videosArray objectAtIndex:indexPath.row] objectForKey:@"route"] copy]
           andAssetURL:[[_videosArray objectAtIndex:indexPath.row] objectForKey:@"assetURL"]];
    
    return cell;
}



- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _videosArray.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.moviePlayer =[[MPMoviePlayerViewController alloc] initWithContentURL:[[_videosArray objectAtIndex:indexPath.row] objectForKey:@"assetURL"]];
    [self presentMoviePlayerViewControllerAnimated:self.moviePlayer];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
}

-(NSArray *)listFileAtPath
{
    int count;
    
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_path error:NULL];
    
    NSMutableArray *filteredVideos = [[NSMutableArray alloc] initWithCapacity:0];
    
    for (count = (int)[directoryContent count]-1; count >= 0; count--)
    {
        //NSLog(@"File %d: %@", (count + 1), [directoryContent objectAtIndex:count]);
        
        NSDictionary *movieInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:[NSString stringWithFormat:@"%@/%@", _path, [directoryContent objectAtIndex:count]]];
        NSURL *mediaURL = [movieInfo objectForKey:@"assetURL"];
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
        dispatch_async(queue, ^{
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            [library assetForURL:mediaURL resultBlock:^(ALAsset *asset) {
                if (asset) {
                    
                    [filteredVideos addObject:@{    @"date" : [movieInfo objectForKey:@"date"],
                                                    @"assetURL" : [movieInfo objectForKey:@"assetURL"],
                                                    @"route" : [movieInfo objectForKey:@"route"],
                                                    @"thumbnail" : [movieInfo objectForKey:@"thumbnail"]}];
                    
                    dispatch_semaphore_signal(semaphore);
                } else {
                    //NSError *error;
                    //[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", path,[directoryContent objectAtIndex:count]] error:&error];
                    //NSLog(@"Can't delete file: %@", [error localizedDescription]);
                    dispatch_semaphore_signal(semaphore);
                }
            } failureBlock:^(NSError *error) {
                NSLog(@"Error %@", error);
            }];
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    return filteredVideos;
}

#pragma mark- UINavigationController Delegates
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
