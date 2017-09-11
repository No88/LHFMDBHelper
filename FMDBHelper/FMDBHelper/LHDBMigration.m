//
//  LHDBMigration.m
//  FMDBHelper
//
//  Created by Elegant on 2017/9/11.
//  Copyright © 2017年 Elegant. All rights reserved.
//

#import "LHDBMigration.h"

@interface LHDBMigration ()

@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) uint64_t version;
@property (nonatomic, strong, readwrite) NSArray *updateArray;

@end

@implementation LHDBMigration

- (instancetype)initWithName:(NSString *)name andVersion:(uint64_t)version andExecuteUpdateArray:(NSArray *)updateArray {
    if (self = [super init]) {
        _name = name;
        _version = version;
        _updateArray = updateArray;
    }
    return self;
}

- (NSString *)name {
    return _name;
}

- (uint64_t)version {
    return _version;
}

- (BOOL)migrateDatabase:(FMDatabase *)database error:(out NSError *__autoreleasing *)error {
    [_updateArray enumerateObjectsUsingBlock:^(NSString * updateStr, NSUInteger idx, BOOL * _Nonnull stop) {
        [database executeUpdate:updateStr];
    }];
    return YES;
}

@end
