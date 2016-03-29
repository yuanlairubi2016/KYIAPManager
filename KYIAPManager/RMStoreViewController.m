//
//  RMStoreViewController.m
//  KYIAPManager
//
//  Created by bruce on 15/12/24.
//  Copyright © 2015年 KY. All rights reserved.
//

#import "RMStoreViewController.h"
#import "RMStore.h"

@interface RMStoreViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic, strong) NSMutableArray *buyBtnArray;

@end

@implementation RMStoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"RMStore";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    //Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.products.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellN = @"CellN";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellN];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier: cellN];
    }
    
    
    cell.textLabel.text = [_array objectAtIndex:indexPath.row];
    
    UIButton *buyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [buyButton setShowsTouchWhenHighlighted:YES];
    
    buyButton.frame = CGRectMake(5, 0, 100, 40);
    buyButton.backgroundColor = [UIColor colorWithRed:0.318f green:0.729f blue:0.949f alpha:1.00f];
    [buyButton setTitle:@"Buy" forState:UIControlStateNormal];
    buyButton.tag = indexPath.row;
    [buyButton addTarget:self action:@selector(buyButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = buyButton;
    self.buyBtnArray[indexPath.row] = buyButton;
    
    return cell;
}

- (void)buyButtonTapped:(UIButton *)button {
    
    NSString *productID = [self.array objectAtIndex:button.tag];
    
}


@end
