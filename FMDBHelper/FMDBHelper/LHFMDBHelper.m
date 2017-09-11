//
//  LHFMDBHelper.m
//  FMDBHelper
//
//  Created by Elegant on 2017/9/8.
//  Copyright © 2017年 Elegant. All rights reserved.
//

#import "LHFMDBHelper.h"
#import "FMDB.h"
#import <objc/runtime.h>
#import "LHDBMigration.h"

#define SAFE_BLOCK(BlockName, ...) ({ !BlockName ? nil : BlockName(__VA_ARGS__); })

static LHFMDBHelper *_instace = nil;

@interface LHFMDBHelper ()

@property (nonatomic, strong, readwrite) FMDatabaseQueue *databaseQueue;

@end

@implementation LHFMDBHelper

+ (dispatch_queue_t)databaseQueue {
    static dispatch_queue_t databaseQueue = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        databaseQueue = dispatch_queue_create("com.FMDBHelper.LHFMDBHelper.databaseQueue", DISPATCH_QUEUE_CONCURRENT);
        dispatch_set_target_queue(databaseQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0));
    });
    return databaseQueue;
}

+ (void)load {
    _instace = [[self alloc] init];
}

+ (instancetype)shareInstace {
    return _instace;
}

+ (instancetype)alloc {
    if (_instace) {
        NSException *expc = [NSException exceptionWithName:@"NSInternalInconsistencyException" reason:@"There can only be one LHFMDBHelper instance." userInfo:nil];
        [expc raise];
    }
    return [super alloc];
}

- (instancetype)init {
    if (self = [super init]) {
        _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:[LHFMDBHelper getDbPath]];
        
        NSLog(@"%@", [LHFMDBHelper getDbPath]);
        
        BOOL isCreatePerson = [self createTable:NSClassFromString(@"LHPerson")];
        NSLog(@"isCreatePerson = %zd", isCreatePerson);
        
        BOOL isCreateDog = [self createTable:NSClassFromString(@"LHDog")];
        NSLog(@"isCreateDog = %zd", isCreateDog);
        
        // 数据库升级
//        FMDBMigrationManager *manager = [FMDBMigrationManager managerWithDatabaseAtPath:[LHFMDBHelper getDbPath] migrationsBundle:[NSBundle mainBundle]];
//        LHDBMigration *migration_1 = [[LHDBMigration alloc]initWithName:@"LHDog表新增字段master" andVersion:2 andExecuteUpdateArray:@[@"alter table LHDog add master text"]];
//        
//        [manager addMigration:migration_1];
//        
//        BOOL resultState = NO;
//        NSError * error = nil;
//        if (!manager.hasMigrationsTable) {
//            resultState=[manager createMigrationsTable:&error];
//        }
//        resultState = [manager migrateDatabaseToVersion:UINT64_MAX progress:nil error:&error];
//        NSLog(@"resultState = %zd", resultState);
    }
    return self;
}

#pragma mark - public
- (void)insertModel:(id)model complete:(void(^)(BOOL success))complete {
    dispatch_async([LHFMDBHelper databaseQueue], ^{
        [_databaseQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            void (^endBlock)(BOOL) = ^(BOOL su) {
                if (!su) {
                    *rollback = YES;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    SAFE_BLOCK(complete, su);
                });
            };
            if ([model isKindOfClass:[NSArray class]] ||
                [model isKindOfClass:[NSMutableArray class]]) {
                [self insertModelArr:model db:db complete:^(BOOL success) {
                    SAFE_BLOCK(endBlock, success);
                }];
            } else {
                [self insertModel:model db:db complete:^(BOOL success) {
                    SAFE_BLOCK(endBlock, success);
                }];
            }
        }];
    });
}

- (void)searchModelArrayWithModelClass:(Class)modelClass byKey:(NSString *)key complete:(void(^)(NSArray *results))complete {
    dispatch_async([LHFMDBHelper databaseQueue], ^{
        [_databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
            // 查询数据
            NSMutableString *sql = [NSString stringWithFormat:@"SELECT * FROM %@",modelClass].mutableCopy;
            if (!key) {
                // 加载消息
                [sql appendString:[NSString stringWithFormat:@" order by tid DESC limit 0,20"]];
            } else {
                // 历史
                [sql appendString:[NSString stringWithFormat:@" where tid < %zd order by tid DESC limit 0,20", key.integerValue]];
            }
            
            // NSMutableString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ order by id DESC limit 0,20",modelClass].mutableCopy;
            
            FMResultSet *rs = [db executeQuery:sql];
            NSMutableArray *modelArrM = [NSMutableArray array];
            // 遍历结果集
            while ([rs next]) {
                
                // 创建对象
                id object = [[modelClass class] new];
                
                unsigned int outCount;
                Ivar * ivars = class_copyIvarList(modelClass, &outCount);
                for (int i = 0; i < outCount; i ++) {
                    Ivar ivar = ivars[i];
                    NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
                    if([[key substringToIndex:1] isEqualToString:@"_"]){
                        key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
                    }
                    
                    id value = [rs objectForColumn:key];
                    if ([value isKindOfClass:[NSString class]]) {
                        NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
                        id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                        if ([result isKindOfClass:[NSDictionary class]] || [result isKindOfClass:[NSMutableDictionary class]] || [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSMutableArray class]]) {
                            [object setValue:result forKey:key];
                        } else {
                            [object setValue:value forKey:key];
                        }
                    } else {
                        [object setValue:value forKey:key];
                    }
                }
                
                // 添加
                [modelArrM addObject:object];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                SAFE_BLOCK(complete, modelArrM);
            });
        }];
    });
}

- (void)searchModel:(Class)modelClass keyValues:(NSDictionary *)keyValues complete:(void(^)(id results))complete {
    dispatch_async([LHFMDBHelper databaseQueue], ^{
        [_databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
            [self searchModel:modelClass keyValues:keyValues db:db complete:complete];
        }];
    });
}

- (void)deleteModelClass:(Class)modelClass complete:(void(^)(BOOL success))complete {
    [self deleteModelClass:modelClass byKey:nil complete:complete];
}

- (void)deleteModelClass:(Class)modelClass byKey:(NSString *)key complete:(void(^)(BOOL success))complete {
    dispatch_async([LHFMDBHelper databaseQueue], ^{
        [_databaseQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            [self deleteModelClass:modelClass keyValues:key ? @{key : key} : nil db:db complete:^(BOOL success) {
                if (!success) {
                    *rollback = YES;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    SAFE_BLOCK(complete, success);
                });
            }];
        }];
    });
}

- (void)deleteModelClass:(Class)modelClass keyValues:(NSDictionary *)keyValues complete:(void(^)(BOOL success))complete {
    dispatch_async([LHFMDBHelper databaseQueue], ^{
        [_databaseQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
            [self deleteModelClass:modelClass keyValues:keyValues ? keyValues : nil db:db complete:^(BOOL success) {
                if (!success) {
                    *rollback = YES;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    SAFE_BLOCK(complete, success);
                });
            }];
        }];
    });
}

#pragma mark - private
#pragma mark 创表
- (BOOL)createTable:(Class)modelClass {
    __block BOOL success = NO;
    [_databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
//        if ([self isExitTable:modelClass db:db]) {
//            success = YES;
//        } else {
//        }
        success = [db executeUpdate:[self createTableSQL:modelClass]];
    }];
    
    return success;
}

/**
 *
 *  创建表的SQL语句
 */
- (NSString *)createTableSQL:(Class)modelClass {
    NSMutableString *sqlPropertyM = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (tid INTEGER PRIMARY KEY AUTOINCREMENT ",modelClass];
    
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList(modelClass, &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if ([[key substringToIndex:1] isEqualToString:@"_"]) {
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        if ([key isEqualToString:@"tid"]) continue;
        [sqlPropertyM appendFormat:@", %@",key];
    }
    [sqlPropertyM appendString:@")"];
    
    return sqlPropertyM;
}

/**
 指定表是否存在
 
 @param modelClass 表名
 @return YES OR NO
 */
- (BOOL)isExitTable:(Class)modelClass db:(FMDatabase *)db {
    FMResultSet *success = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@",modelClass]];
    return [success next];
}

#pragma mark 插入
- (void)insertModelArr:(NSArray *)modelArr db:(FMDatabase *)db complete:(void(^)(BOOL success))complete {
    __block BOOL flag = YES;
    [modelArr enumerateObjectsUsingBlock:^(id  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        [self insertModel:model db:db complete:^(BOOL success) {
            if (!success) {
                flag = NO;
                *stop = YES;
            }
        }];
    }];
    SAFE_BLOCK(complete, flag);
}

- (void)insertModel:(id)model db:(FMDatabase *)db complete:(void(^)(BOOL success))complete {
    NSAssert(![model isKindOfClass:[UIResponder class]], @"必须保证模型是NSObject或者NSObject的子类,同时不响应事件");
    
    NSString *dbid = [model valueForKey:@"tid"];
    
    [self searchModel:[model class] byKey:dbid sqlString:nil db:db complete:^(id judgeModle) {
        
        if ([[judgeModle valueForKey:@"tid"] isEqualToString:dbid]) {
            BOOL updataSuccess = [self modifyModel:model byID:dbid db:db];
            SAFE_BLOCK(complete, updataSuccess);
        } else {
            BOOL insertSuccess = [db executeUpdate:[self createInsertSQL:model]];
            SAFE_BLOCK(complete, insertSuccess);
        }
    }];
}

/**
 *  创建插入表的SQL语句
 */
- (NSString *)createInsertSQL:(id)model {
    NSMutableString *sqlValueM = [NSMutableString stringWithFormat:@"INSERT OR REPLACE INTO %@ (",[model class]];
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList([model class], &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if ([[key substringToIndex:1] isEqualToString:@"_"]) {
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        
        if (i == 0) {
            [sqlValueM appendString:key];
        } else {
            [sqlValueM appendFormat:@", %@",key];
        }
    }
    [sqlValueM appendString:@") VALUES ("];
    
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if ([[key substringToIndex:1] isEqualToString:@"_"]) {
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        
        id value = [model valueForKey:key];
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]] || [value isKindOfClass:[NSNull class]]) {
            value = [NSString stringWithFormat:@"%@",value];
        }
        if (i == 0) {
            // sql 语句中字符串需要单引号或者双引号括起来
            [sqlValueM appendFormat:@"%@",[value isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"'%@'",value] : value];
        } else {
            [sqlValueM appendFormat:@", %@",[value isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"'%@'",value] : value];
        }
    }
    // [sqlValueM appendFormat:@" WHERE id = '%@'",[model valueForKey:@"id"]];
    [sqlValueM appendString:@");"];
    
    return sqlValueM;
}

#pragma mark 删
- (void)deleteModelClass:(Class)modelClass keyValues:(NSDictionary *)keyValues db:(FMDatabase *)db complete:(void(^)(BOOL success))complete {
    NSMutableString *sql = [NSString stringWithFormat:@"DELETE FROM %@", modelClass].mutableCopy;
    if (keyValues.count || keyValues) {
        NSArray *values = keyValues.allValues;
        NSArray *keys = keyValues.allKeys;
        [values enumerateObjectsUsingBlock:^(NSString *value, NSUInteger idx, BOOL * stop) {
            if (!idx) {
                [sql appendFormat:@" WHERE %@ = %@ ", keys[idx], [value isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"'%@'", value] : value];
            } else {
                [sql appendFormat:@" and %@ = %@", keys[idx], [value isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"'%@'", value] : value];
            }
        }];
        [sql appendString:@";"];
    }
    BOOL success = [db executeUpdate:sql];
    SAFE_BLOCK(complete, success);
}

#pragma mark 查
- (void)searchModel:(Class)modelClass keyValues:(NSDictionary *)keyValues db:(FMDatabase *)db complete:(void(^)(id results))complete {
    NSArray *values = keyValues.allValues;
    NSArray *keys = keyValues.allKeys;
    NSMutableString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE ", modelClass].mutableCopy;
    [values enumerateObjectsUsingBlock:^(NSString *value, NSUInteger idx, BOOL * stop) {
        if (!idx) {
            [sql appendFormat:@"%@ = %@ ", keys[idx], [value isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"'%@'", value] : value];
        } else {
            [sql appendFormat:@" and %@ = %@", keys[idx], [value isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"'%@'", value] : value];
        }
    }];
    [sql appendString:@";"];
    
    [self searchModel:modelClass byKey:nil sqlString:sql db:db complete:^(id results) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SAFE_BLOCK(complete, results);
        });
    }];
}

- (void)searchModel:(Class)modelClass byKey:(NSString *)key sqlString:(NSString *)sql db:(FMDatabase *)db complete:(void(^)(NSArray *results))complete {
    // 查询数据
    FMResultSet *rs = [db executeQuery:sql ? sql : [NSString stringWithFormat:@"SELECT * FROM %@ WHERE tid = '%@';", modelClass, key]];
    // 创建对象
    id object = [[modelClass class] new];
    
    // 遍历结果集
    while ([rs next]) {
        
        unsigned int outCount;
        Ivar * ivars = class_copyIvarList(modelClass, &outCount);
        for (int i = 0; i < outCount; i ++) {
            Ivar ivar = ivars[i];
            NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
            if([[key substringToIndex:1] isEqualToString:@"_"]){
                key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
            }
            
            id value = [rs objectForColumn:key];
            if ([value isKindOfClass:[NSString class]]) {
                NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
                id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([result isKindOfClass:[NSDictionary class]] || [result isKindOfClass:[NSMutableDictionary class]] || [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSMutableArray class]]) {
                    [object setValue:result forKey:key];
                } else {
                    [object setValue:value forKey:key];
                }
            } else {
                [object setValue:value forKey:key];
            }
        }
    }
    SAFE_BLOCK(complete, object);
}

#pragma mark 改
- (BOOL)modifyModel:(id)model byID:(NSString *)ID db:(FMDatabase *)db {
    
    // 修改数据@"UPDATE t_student SET name = 'liwx' WHERE age > 12 AND age < 15;"
    NSMutableString *sql = [NSMutableString stringWithFormat:@"UPDATE %@ SET ",[model class]];
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList([model class], &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if ([[key substringToIndex:1] isEqualToString:@"_"]) {
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        id value = [model valueForKey:key];
        if (i == 0) {
            [sql appendFormat:@"%@ = %@",key,([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) || [NSNull class] ? [NSString stringWithFormat:@"'%@'",value] : value];
        } else {
            [sql appendFormat:@",%@ = %@",key,([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) || [NSNull class] ? [NSString stringWithFormat:@"'%@'",value] : value];
        }
    }
    
    [sql appendFormat:@" WHERE tid = '%@';",ID];
    BOOL success = [db executeUpdate:sql];
    return success;
}

#pragma mark - other
+ (NSString *)getDbPath {
    NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/com.Elegant.FMDBHelper"];
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:NULL]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [filePath stringByAppendingPathComponent:@"FMDBHelper.db"];
}


@end
