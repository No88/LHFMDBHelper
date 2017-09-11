//
//  ViewController.m
//  FMDBHelper
//
//  Created by Elegant on 2017/9/8.
//  Copyright © 2017年 Elegant. All rights reserved.
//

#import "ViewController.h"
#import "LHFMDBHelper.h"
#import "LHPerson.h"
#import "LHDog.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readwrite) NSMutableArray *array;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    LHDog *dog = [LHDog new];
//    dog.age = 10;
//    dog.name = @"haha";
//    dog.master = @"heiehi";
//    [[LHFMDBHelper shareInstace] insertModel:dog complete:^(BOOL success) {
//        NSLog(@"success = %zd", success);
//    }];
//    return;
    // Do any additional setup after loading the view, typically from a nib.
    _array = @[].mutableCopy;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (NSInteger i = 0; i < 10; i++) {
            LHPerson *person = [[LHPerson alloc] init];
            person.age = i;
            person.tid = [NSString stringWithFormat:@"%zd", i];
            person.lastName = [NSString stringWithFormat:@"lastName%zd", i];
            person.firstName = [NSString stringWithFormat:@"firstName%zd", i];
            [_array addObject:person];
        }
        
        [[LHFMDBHelper shareInstace] insertModel:_array complete:^(BOOL success) {
            NSLog(@"保存数据%zd", success);
        }];
    });
    
    NSMutableArray *array = @[].mutableCopy;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (NSInteger i = 10; i < 20; i++) {
            LHPerson *person = [[LHPerson alloc] init];
            person.age = i;
            person.tid = [NSString stringWithFormat:@"%zd", i];
            person.lastName = [NSString stringWithFormat:@"lastName%zd", i];
            person.firstName = [NSString stringWithFormat:@"firstName%zd", i];
            [array addObject:person];
        }
        
        [[LHFMDBHelper shareInstace] insertModel:array complete:^(BOOL success) {
            NSLog(@"保存数据%zd", success);
        }];
    });
}

- (void)logResults {
    [[LHFMDBHelper shareInstace] searchModelArrayWithModelClass:NSClassFromString(@"LHPerson") byKey:@"99" complete:^(NSArray *results) {
        NSLog(@"results = %@", results);
    }];}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
//    for (NSInteger i = 0; i < 10; i++) {
//        
//        [self logResults];
//    }
    [[LHFMDBHelper shareInstace] deleteModelClass:NSClassFromString(@"LHPerson") complete:^(BOOL success) {
        NSLog(@"删除%zd", success);
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"row = %zd", indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[LHFMDBHelper shareInstace] searchModelArrayWithModelClass:NSClassFromString(@"LHPerson") byKey:@"99" complete:^(NSArray *results) {
        NSLog(@"results = %@", results);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
