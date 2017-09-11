//
//  LHDBMigration.h
//  FMDBHelper
//
//  Created by Elegant on 2017/9/11.
//  Copyright © 2017年 Elegant. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDBMigrationManager.h"

@interface LHDBMigration : NSObject <FMDBMigrating>

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) uint64_t version;

- (instancetype)initWithName:(NSString *)name andVersion:(uint64_t)version andExecuteUpdateArray:(NSArray *)updateArray;
- (BOOL)migrateDatabase:(FMDatabase *)database error:(out NSError *__autoreleasing *)error;

@end
