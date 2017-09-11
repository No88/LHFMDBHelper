//
//  LHPerson.h
//  FMDBHelper
//
//  Created by Elegant on 2017/9/8.
//  Copyright © 2017年 Elegant. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LHPerson : NSObject

@property (nonatomic, strong, readwrite) NSString *tid;
@property (nonatomic, assign, readwrite) NSInteger age;
@property (nonatomic, strong, readwrite) NSString *lastName;
@property (nonatomic, strong, readwrite) NSString *firstName;

@end
