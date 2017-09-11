//
//  LHDog.h
//  FMDBHelper
//
//  Created by Elegant on 2017/9/11.
//  Copyright © 2017年 Elegant. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LHDog : NSObject

@property (nonatomic, strong, readwrite) NSString *tid;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) NSInteger age;
@property (nonatomic, strong, readwrite) NSString *master;
@end
