## LHFMDBHelper

### 前言
LHFMDBHelper是对FMDB的二次封装(虽然封装的不咋地, 但是凑合能用)，支持异步读写。只需使用LHFMDBHelper对象而不是FMDatabase对象，LHFMDBHelper将确保您的应用程序滚动顺利。

### 依赖

- [FMDB](https://github.com/ccgus/fmdb)
- 导入libsqlite3.0.tbd

### 快速入门

- 增

```objc
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

```


- 删

```objc
[[LHFMDBHelper shareInstace] deleteModelClass:NSClassFromString(@"LHPerson") complete:^(BOOL success) {
        NSLog(@"删除%zd", success);
    }];
```

- 查



```objc
[[LHFMDBHelper shareInstace] searchModelArrayWithModelClass:NSClassFromString(@"LHPerson") byKey:@"99" complete:^(NSArray *results) {
        NSLog(@"results = %@", results);
    }];
```

### 希望

- **如果您在使用时发现错误，希望您可以发问，谢谢或尝试下载此框架的最新代码，以查看BUG是否已修复）**
- **如果你发现使用的功能不够，希望你可以问我，我希望的为这个框架添加更多有用的功能，谢谢!**

