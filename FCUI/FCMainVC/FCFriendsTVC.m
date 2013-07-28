//
//  FCFriendsTVC.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import "FCFriendsTVC.h"
#import "Conversation.h"
#import "FCConversationModel.h"
#import "UIImageView+WebCache.h"
#import "TDBadgedCell.h"
#import "ChatViewController.h"
#import "XMPP.h"
#import "Message.h"
#import "NSString+Additions.h"

@interface FCFriendsTVC ()
@property (nonatomic, strong) NSArray *conversations;
@end

@implementation FCFriendsTVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Friends", @"Friends");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.conversations = [Conversation MR_findAll];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationItem setHidesBackButton:YES animated:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageReceived:)
                                                 name:@"messageCome"
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)messageReceived:(NSNotification*)textMessage {
    
    XMPPMessage *message = textMessage.object;
    if([message isChatMessageWithBody]) {
        
        NSString *adressString = [NSString stringWithFormat:@"%@",[message fromStr]];
        NSString *newStr = [adressString substringWithRange:NSMakeRange(1, [adressString length]-1)];
        NSString *facebookID = [NSString stringWithFormat:@"%@",[[newStr componentsSeparatedByString:@"@"] objectAtIndex:0]];
        
        NSLog(@"FACEBOOK_ID:%@",facebookID);
        
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];   // Build the predicate to find the person sought
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"facebookId = %@", facebookID];
        Conversation *conversation = [Conversation MR_findFirstWithPredicate:predicate inContext:localContext];

                
        Message *msg = (Message *)[NSEntityDescription
                                   insertNewObjectForEntityForName:@"Message"
                                   inManagedObjectContext:conversation.managedObjectContext];
        
        msg.text = [NSString stringWithFormat:@"%@",[[message elementForName:@"body"] stringValue]];
        msg.sentDate = [NSDate date];
        
        // message did come, this will be on left
        msg.messageStatus = @(TRUE);
        
        // increase badge number.
        int badgeNumber = [conversation.badgeNumber intValue];
        badgeNumber++;
        conversation.badgeNumber = [NSNumber numberWithInt:badgeNumber];
        
        [conversation addMessagesObject:msg];
        NSError *error;
        if (![conversation.managedObjectContext save:&error]) {
            // TODO: Handle the error appropriately.
            NSLog(@"Mass message creation error %@, %@", error, [error userInfo]);
        }
        
        [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.conversations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    TDBadgedCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[TDBadgedCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    Conversation *conversation = [self.conversations objectAtIndex:indexPath.row];
    if([conversation.badgeNumber intValue] != 0) {
        cell.badgeString = [NSString stringWithFormat:@"%d", [conversation.badgeNumber intValue]];
        cell.badgeColor = [UIColor colorWithRed:0.197 green:0.592 blue:0.219 alpha:1.000];
        cell.badge.radius = 9;
    }
    
    NSString *url = [[NSString alloc]
                     initWithFormat:@"https://graph.facebook.com/%@/picture",conversation.facebookId];
    [cell.imageView setImageWithURL:[NSURL URLWithString:url]
                   placeholderImage:nil
                          completed:^(UIImage *image, NSError *error, SDImageCacheType type){}];
    cell.textLabel.text = conversation.facebookName;
    return cell;
}


#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatViewController *chatViewController = [[ChatViewController alloc] init];
    chatViewController.conversation = [self.conversations objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:chatViewController animated:YES];
}

@end