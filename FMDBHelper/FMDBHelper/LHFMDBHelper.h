//
//  LHFMDBHelper.h
//  FMDBHelper
//
//  Created by Elegant on 2017/9/8.
//  Copyright © 2017年 Elegant. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LHFMDBHelper : NSObject

+ (instancetype)shareInstace;

/**
 插入单个模型或者模型数组,如果此时传入的模型对应的FLDBID在表中已经存在，则替换更新旧的
 如果没创建表就自动先创建，表名为模型类名
 此时执行完毕后自动关闭数据库
 */
- (void)insertModel:(id)model complete:(void(^)(BOOL success))complete;


/**
 删除模型

 @param modelClass 表名
 */
- (void)deleteModelClass:(Class)modelClass complete:(void(^)(BOOL success))complete;

/**
 删除模型

 @param modelClass 表
 @param key 条件
 */
- (void)deleteModelClass:(Class)modelClass byKey:(NSString *)key complete:(void(^)(BOOL success))complete;;

/**
 删除模型
 
 @param modelClass 表
 @param keyValues 条件
 */
- (void)deleteModelClass:(Class)modelClass keyValues:(NSDictionary *)keyValues complete:(void(^)(BOOL success))complete;

/**
 查找指定表中模型数组，执行完毕后自动关闭数据库，如果没有对应表，会自动先创建，表名为模型类名

 @param modelClass 表
 @param complete 模型数组
 */
- (void)searchModelArrayWithModelClass:(Class)modelClass byKey:(NSString *)key complete:(void(^)(NSArray *results))complete;

/**
 查找指定表中指定Key的模型，执行完毕后自动关闭数据库，如果没有对应表，会自动先创建，表名为模型类名
 */
- (void)searchModel:(Class)modelClass keyValues:(NSDictionary *)keyValues complete:(void(^)(id results))complete;

@end
