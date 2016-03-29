//
//  ViewController.m
//  KYIAPManager
//
//  Created by bruce on 15/11/24.
//  Copyright © 2015年 KY. All rights reserved.
//

#import "ViewController.h"
#import "KYIAPManager.h"
#import "RMStoreViewController.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate,KYIAPPurchaseDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSArray *array;

@property (nonatomic,strong) NSArray *products;
@property(nonatomic, strong) NSMutableArray *buyBtnArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //
    self.title = @"KYIAPManager";
    [self payInit];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

}

- (void)payInit {
    self.array = [[NSArray alloc] initWithObjects:
                  @"com.eling.developtest.pay1",@"com.eling.developtest.pay2",
                  @"com.eling.developtest.pay4",@"eling.freesubscription",
                  @"eling.consumable",@"eling.autorenewable",
                  @"eling.noconsumable",@"eling.nonrenewing",nil];
    [[KYIAPManager shareInstance] requestProductWithIdentifiers:[NSSet setWithArray:self.array]];

    //支付开始
    if([[KYIAPManager shareInstance] canMakePayments]){//判断用户是否开启支付功能
        NSLog(@"用户允许内置购买");
    }
    else{
        NSLog(@"请开启允许内置购买");
    }
    //设置支付协议
    [KYIAPManager shareInstance].kyIAPPurchaseDelegate = self;
}

- (void)dealloc {
    //设置支付协议
    [KYIAPManager shareInstance].kyIAPPurchaseDelegate = nil;
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
    [[KYIAPManager shareInstance] buyWithProductId:productID andQuantity:1 andCallbackInfo:@"callback信息"];
    
}


#pragma mark - 购买结果

/**
 *  @brief 获取商品信息
 */
- (void)kyProductInfo:(NSArray *)products{
    self.products = products;
    [self.tableView reloadData];
}

/** 用户支付完成,可以不实现 **/
- (void)kyCompleteTransactionIn:(SKPaymentTransaction *)transaction{
    
}
/** 用户支付失败，包括取消订单什么的 **/
- (void)kyFailedTransactionIn:(SKPaymentTransaction *)transaction{
    NSLog(@"error = %@", transaction.error);
}

/** 物品下发 **/
- (void)didFinishedPayment:(id)result{
    NSLog(@"%@",result);
  
    //根据result 判断物品是否下发，
    //我们假设下发成功
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"购买" message:@"物品已经下发" preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alertController animated:YES completion:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:okAction];
}

/** 购买失败，一般是网络的问题 **/
- (void)didFailedWithError:(NSError *)error{
}

#pragma mark - remove transactions
- (IBAction)removeTransactions:(id)sender {
    [[KYIAPManager shareInstance] removeQueueTransactions];
    
}

#pragma mark - RMStore
- (IBAction)rmStore:(id)sender {
    if(self.products && self.products.count>0){
        RMStoreViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"RMStoreViewController"];
        viewController.products = self.products;
        viewController.array = self.array;
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

@end
