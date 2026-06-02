//
//  Person.m
//  InterviewDemo - 属性关键字综合演示模型
//

#import "Person.h"

@interface Person ()
// 类扩展中重新声明为 readwrite，让内部可以修改
@property (nonatomic, readwrite, copy) NSString *identifier;
@end

@implementation Person

- (instancetype)init {
    if (self = [super init]) {
        _identifier = [[NSUUID UUID] UUIDString];
        _requiredName = @"未命名";
    }
    return self;
}

- (void)dealloc {
    printf("💀 [Person dealloc] %s 被释放，weak 引用即将自动置 nil\n\n",
           [self.name UTF8String] ?: "(null)");
}

// MARK: - KVO: 手动通知 fullName 依赖 firstName / lastName

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:@"fullName"]) {
        return NO;  // 手动发送 KVO 通知
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

- (void)setFirstName:(NSString *)firstName {
    [self willChangeValueForKey:@"firstName"];
    [self willChangeValueForKey:@"fullName"];   // fullName 依赖 firstName
    _firstName = [firstName copy];
    [self didChangeValueForKey:@"fullName"];
    [self didChangeValueForKey:@"firstName"];
}

- (void)setLastName:(NSString *)lastName {
    [self willChangeValueForKey:@"lastName"];
    [self willChangeValueForKey:@"fullName"];   // fullName 依赖 lastName
    _lastName = [lastName copy];
    [self didChangeValueForKey:@"fullName"];
    [self didChangeValueForKey:@"lastName"];
}

- (NSString *)fullName {
    NSString *first = self.firstName ?: @"";
    NSString *last  = self.lastName ?: @"";
    if (first.length == 0 && last.length == 0) return @"未知";
    return [NSString stringWithFormat:@"%@ %@", first, last];
}

// MARK: - null_resettable: getter 中自动创建默认值

- (NSString *)resettableTitle {
    NSString *title = _resettableTitle;
    if (title == nil) {
        title = @"默认标题";
        _resettableTitle = title;
    }
    return title;
}

// MARK: - Class property + 单例

static Person *_sharedPerson = nil;

+ (Person *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedPerson = [[Person alloc] init];
        _sharedPerson.name = @"共享Person";
    });
    return _sharedPerson;
}

@end
