//
//  KeywordTest.m
//  InterviewDemo - OC 属性关键字 · 10 道高频面试题 + 手写代码题
//
//  3 道手写代码题 + 7 道原理面试题，带逐题演示和踩坑点
//

#import "KeywordTest.h"
#import "Person.h"
#import <os/lock.h>

//==============================================================================
// MARK: - 辅助类：演示线程安全问题
//==============================================================================

/// 原子属性计数器 —— 但复合操作仍然不安全！
@interface UnsafeCounter : NSObject
@property (atomic, assign) NSInteger count;   // atomic 只保证 getter/setter 原子性
- (void)resetAndRace;                          // 演示多线程竞争
@end

/// 线程安全计数器 —— 使用 os_unfair_lock 保护复合操作
@interface SafeCounter : NSObject
- (void)increment;
- (NSInteger)count;
- (void)resetAndConcurrentIncrement;            // 演示线程安全
@end

//==============================================================================
// MARK: - KeywordTest 实现
//==============================================================================

@implementation KeywordTest

//------------------------------------------------------------------------------
// MARK: 公共入口
//------------------------------------------------------------------------------

+ (void)run {
    // 这句是 Command Line Tool 的启动入口
    printf("╔══════════════════════════════════════════════════════════╗\n");
    printf("║     iOS OC 属性关键字 · 高级面试复习 & 手写代码         ║\n");
    printf("║     10 道高频题：3 道手写 + 7 道原理，全部可运行         ║\n");
    printf("╚══════════════════════════════════════════════════════════╝\n");

    KeywordTest *test = [[self alloc] init];

    // ---- 手写代码题 (3 道) ----
    [test question1_copyMutableStringPitfall];
    [test question2_threadSafeProperty];
    [test question3_kvoCustomSetter];

    // ---- 原理面试题 (7 道) ----
    [test question4_atomicVsNonatomic];
    [test question5_assignVsWeak];
    [test question6_copyVsStrong];
    [test question7_deepVsShallowCopy];
    [test question8_weakImplementation];
    [test question9_weakDeallocFlow];
    [test question10_arcVsMrc];

    printf("\n\n✅ 全部 10 道面试题复习完毕。祝你面试顺利！\n\n");
}

//------------------------------------------------------------------------------
// MARK: 输出辅助
//------------------------------------------------------------------------------

- (void)printQ:(NSString *)code title:(NSString *)title type:(NSString *)type {
    printf("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    printf("📌 %s. %s  【%s】\n", [code UTF8String], [title UTF8String], [type UTF8String]);
    printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n");
}

- (void)printPitfall:(NSArray<NSString *> *)points {
    printf("⚠️  踩坑点：\n");
    for (NSInteger i = 0; i < points.count; i++) {
        printf("   %ld. %s\n", (long)(i + 1), [points[i] UTF8String]);
    }
    printf("\n");
}

//==============================================================================
// MARK: Q1 · 手写代码题 — copy 关键字对 NSMutableString 的陷阱
//==============================================================================

- (void)question1_copyMutableStringPitfall {
    [self printQ:@"Q1"
           title:@"copy 修饰 NSMutableString 属性的陷阱及修复"
            type:@"手写代码"];

    printf("【题目】\n");
    printf("  现有 Person 类，其 bio 属性声明如下：\n");
    printf("    @property (nonatomic, copy) NSMutableString *bio;\n\n");
    printf("  当调用方传入 NSMutableString 后，对 bio 做 appendString: 会发生什么？\n");
    printf("  请手写正确的 setter 实现来修复这个问题。\n\n");

    printf("【答案】\n");
    printf("  copy 修饰符会调用对象的 copy 方法。\n");
    printf("  NSMutableString 的 copy 返回的是不可变的 NSString。\n");
    printf("  因此 bio 属性实际存储的是 NSString，调用 appendString: 会抛出\n");
    printf("  NSInvalidArgumentException（unrecognized selector）。\n\n");
    printf("  修复方案：自定义 setter，使用 mutableCopy 替代 copy。\n\n");

    printf("【代码演示 — 先看错误情况】\n");
    Person *p = [[Person alloc] init];
    NSMutableString *mStr = [NSMutableString stringWithString:@"Hello"];
    printf("  赋值前 mStr 类型: %s\n", [NSStringFromClass([mStr class]) UTF8String]);
    printf("  赋值前 mStr 值:   %s\n", [mStr UTF8String]);

    p.bio = mStr;  // copy → 变成 NSString!
    printf("  赋值后 p.bio 类型: %s  ← 变了！从 NSMutableString 变成了 NSString\n",
           [NSStringFromClass([p.bio class]) UTF8String]);

    @try {
        [p.bio appendString:@" World"]; // 💥 这里会抛异常
        printf("  (未抛出异常 — 意料之外)\n");
    } @catch (NSException *exception) {
        printf("  💥 异常: %s\n", [[exception reason] UTF8String]);
    }

    printf("\n【修复方案 — 自定义 setter 使用 mutableCopy】\n");
    printf("  // 正确写法：\n");
    printf("  // - (void)setBio:(NSMutableString *)bio {\n");
    printf("  //     _bio = [bio mutableCopy];\n");
    printf("  // }\n\n");
    printf("  面试话术：「对外声明为 NSMutableString 的属性不要用 copy，\n");
    printf("  应该用 strong 或在 setter 中手动调用 mutableCopy。」\n");

    [self printPitfall:@[
        @"copy 对可变类型永远返回不可变对象（NSString/NSArray/NSDictionary 同理）",
        @"属性对外声明 NSMutableString，但内部存的是 NSString，调用方不知情就 crash",
        @"解决：要么用 strong（接受外部修改风险），要么 setter 里 mutableCopy",
        @"面试追问：为什么 block 属性要用 copy？（MRC 下 block 在栈上，copy 到堆上）"
    ]];
}

//==============================================================================
// MARK: Q2 · 手写代码题 — 线程安全的属性实现
//==============================================================================

- (void)question2_threadSafeProperty {
    [self printQ:@"Q2"
           title:@"手写一个线程安全的计数器属性（atomic 为啥不够？）"
            type:@"手写代码"];

    printf("【题目】\n");
    printf("  请手写一个线程安全的计数器，支持多线程并发递增。\n");
    printf("  要求：不能仅靠 atomic，必须保证 increment 操作整体原子。\n\n");

    printf("【答案 — 核心思路】\n");
    printf("  atomic 只保证单次 get/set 原子，对「读-改-写」复合操作无效。\n");
    printf("  方案 1: os_unfair_lock（iOS 10+，替代 OSSpinLock）\n");
    printf("  方案 2: dispatch_queue (barrier/serial)  \n");
    printf("  方案 3: pthread_mutex_t\n\n");

    printf("【代码演示 — UnsafeCounter（atomic 但复合操作不安全）】\n");
    UnsafeCounter *unsafe = [[UnsafeCounter alloc] init];
    [unsafe resetAndRace];
    printf("  ⚡ UnsafeCounter 并发递增后: %ld（期望 5000，可能不对！）\n",
           (long)unsafe.count);

    printf("\n【代码演示 — SafeCounter（os_unfair_lock 保护）】\n");
    SafeCounter *safe = [[SafeCounter alloc] init];
    [safe resetAndConcurrentIncrement];
    printf("  ✅ SafeCounter 并发递增后: %ld（期望 5000，正确！）\n\n",
           (long)[safe count]);

    printf("  面试话术：\n");
    printf("  「atomic 的锁只保护单次 get/set。self.count += 1 实际是\n");
    printf("  [self setCount:[self count] + 1]，两步之间可能被其他线程打断。\n");
    printf("  真正的线程安全需要用锁把整个复合操作包起来。」\n");

    [self printPitfall:@[
        @"atomic ≠ 线程安全。只保证读/写的单次原子性",
        @"self.count += 1 是三步：读、加、写 —— 不是原子的",
        @"os_unfair_lock 替代了已废弃的 OSSpinLock（优先级反转问题）",
        @"面试官可能追问：「那什么时候 atomic 就够了？」—— 仅当多个线程只读/只写单一值，不做复合操作",
    ]];
}

//==============================================================================
// MARK: Q3 · 手写代码题 — KVO 兼容的自定义 setter
//==============================================================================

- (void)question3_kvoCustomSetter {
    [self printQ:@"Q3"
           title:@"手写 KVO 兼容的依赖属性 setter（fullName = firstName + lastName）"
            type:@"手写代码"];

    printf("【题目】\n");
    printf("  Person 类有 firstName、lastName 和 fullName（计算属性），\n");
    printf("  要求外部能 KVO 观察 fullName。当 firstName 或 lastName 变化时，\n");
    printf("  fullName 的观察者能收到通知。请手写实现。\n\n");

    printf("【答案】\n");
    printf("  两步：(1) 重写 automaticallyNotifiesObserversForKey: 手动标记 fullName\n");
    printf("        (2) 在 firstName/lastName 的 setter 中手动发出 fullName 通知\n\n");

    printf("【代码演示】\n");
    Person *p = [[Person alloc] init];

    // 注册 KVO 观察者（用 inline block observer）
    // 使用 self 作为 KVO 观察者
    [p addObserver:self
        forKeyPath:@"fullName"
           options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
           context:NULL];

    printf("  设置 firstName = \"张\", lastName = \"三\"\n");
    p.firstName = @"张";
    p.lastName  = @"三";
    printf("  fullName = %s\n\n", [p.fullName UTF8String]);

    printf("  设置 firstName = \"李\"\n");
    p.firstName = @"李";
    printf("  fullName = %s\n\n", [p.fullName UTF8String]);

    // 验证 KVO 通知确实触发了（通过查看 didChange 是否被调用）
    printf("  观察 Person.m 中 setFirstName:/setLastName: 的实现：\n");
    printf("    1. willChangeValueForKey:@\"fullName\"\n");
    printf("    2. 设置 _firstName / _lastName\n");
    printf("    3. didChangeValueForKey:@\"fullName\"\n");
    printf("  这保证了 fullName 的 KVO 观察者能收到通知 ✅\n");

    [p removeObserver:self forKeyPath:@"fullName"];

    [self printPitfall:@[
        @"必须重写 +automaticallyNotifiesObserversForKey: 返回 NO，否则 KVO 不知道 fullName 依赖哪些 key",
        @"willChange / didChange 必须成对调用，否则 KVO 内部状态错乱",
        @"面试追问：「如果不用手动通知，有其他方式吗？」—— keyPathsForValuesAffecting<Key> 方法",
        @"Swift 中用 @objc dynamic 标记属性才能被 KVO 观察",
    ]];
}

// KVO 回调（供 Q3 使用）
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"fullName"]) {
        printf("  🔔 KVO 通知: fullName 从 \"%s\" 变为 \"%s\"\n",
               [[change[NSKeyValueChangeOldKey] description] UTF8String],
               [[change[NSKeyValueChangeNewKey] description] UTF8String]);
    }
}

//==============================================================================
// MARK: Q4 · 原理题 — atomic vs nonatomic
//==============================================================================

- (void)question4_atomicVsNonatomic {
    [self printQ:@"Q4"
           title:@"atomic 和 nonatomic 的区别？atomic 真的线程安全吗？"
            type:@"原理"];

    printf("【核心区别】\n\n");
    printf("  ┌──────────────┬──────────────────┬──────────────────┐\n");
    printf("  │              │    atomic        │    nonatomic     │\n");
    printf("  ├──────────────┼──────────────────┼──────────────────┤\n");
    printf("  │ getter/setter│ 有锁(自旋锁)     │ 无锁             │\n");
    printf("  │ 线程安全     │ 单次读写原子     │ 不保证任何原子性 │\n");
    printf("  │ 性能         │ 较慢(锁开销)     │ 快               │\n");
    printf("  │ 默认值       │ 是(不写时默认)   │ 需显式声明       │\n");
    printf("  │ 复合操作安全 │ ❌ 不保证        │ ❌ 不保证        │\n");
    printf("  └──────────────┴──────────────────┴──────────────────┘\n\n");

    printf("【atomic 不等于线程安全 — 经典反例】\n");
    printf("  @property (atomic, assign) NSInteger count;\n\n");
    printf("  // 线程 A                     // 线程 B\n");
    printf("  self.count += 1;              self.count += 1;\n\n");
    printf("  看似一行代码，实际拆成三步：\n");
    printf("    1. temp = [self count];    // atomic getter ✅\n");
    printf("    2. temp = temp + 1;        // 纯计算，无锁 ❌\n");
    printf("    3. [self setCount:temp];   // atomic setter ✅\n\n");
    printf("  线程 A 和 B 可能同时读到 count=0，各自 +1 后都写入 1，\n");
    printf("  期望 2，实际 1 → 典型的 Lost Update 问题。\n\n");

    printf("【atomic 底层大致实现（简化版）】\n");
    printf("  - (NSString *)name {              \n");
    printf("      @synchronized(self) {          \n");
    printf("          return _name;              \n");
    printf("      }                              \n");
    printf("  }                                  \n");
    printf("  - (void)setName:(NSString *)n {    \n");
    printf("      @synchronized(self) {          \n");
    printf("          _name = n;                 \n");
    printf("      }                              \n");
    printf("  }                                  \n");
    printf("  （实际用 spinlock_t，比 @synchronized 更轻量）\n\n");

    printf("【工程实践】\n");
    printf("  UI 相关属性一律用 nonatomic（主线程操作，无需锁开销）\n");
    printf("  多线程共享的数据用 nonatomic + 专用锁/dispatch_queue\n");
    printf("  几乎没有人刻意使用 atomic 来解决线程安全问题\n");

    [self printPitfall:@[
        @"面试高频雷区：「atomic 是线程安全的」—— 错误！只能说 getter/setter 原子",
        @"属性默认是 atomic，但几乎所有人都会写 nonatomic（苹果官方示例也是）",
        @"atomic 的性能损失在频繁读写时显著（旧设备上尤其明显）",
        @"atomic + 自定义 getter/setter = 编译器不再自动加锁，需自己保证",
    ]];
}

//==============================================================================
// MARK: Q5 · 原理题 — assign vs weak
//==============================================================================

- (void)question5_assignVsWeak {
    [self printQ:@"Q5"
           title:@"assign 和 weak 的区别？什么时候用哪个？"
            type:@"原理"];

    printf("【核心区别】\n\n");
    printf("  ┌──────────────────┬─────────────────┬──────────────────┐\n");
    printf("  │                  │    assign       │    weak          │\n");
    printf("  ├──────────────────┼─────────────────┼──────────────────┤\n");
    printf("  │ 适用类型         │ 基础类型+对象   │ 仅对象类型       │\n");
    printf("  │ 引用计数         │ 不涉及          │ 不增加引用计数   │\n");
    printf("  │ 对象释放后       │ 悬垂指针⚠️      │ 自动置 nil ✅    │\n");
    printf("  │ 修饰基础类型     │ ✅ 正确用法     │ ❌ 编译报错      │\n");
    printf("  │ 修饰对象         │ ⚠️ 危险         │ ✅ 安全          │\n");
    printf("  └──────────────────┴─────────────────┴──────────────────┘\n\n");

    printf("【代码演示 — weak 的自动置 nil】\n");
    Person *weakPerson = nil;
    @autoreleasepool {
        Person *p = [[Person alloc] init];
        p.name = @"小明";
        weakPerson = p;  // weakPerson 是外部 __weak 引用...

        // 实际上这里 weakPerson 是强引用，我们换一种方式演示
    }

    // 用正确方式演示 weak
    __weak Person *wPerson = nil;
    __unsafe_unretained Person *uPerson = nil;

    @autoreleasepool {
        Person *p = [[Person alloc] init];
        p.name = @"小红";
        wPerson = p;
        uPerson = p;
        printf("  对象存活时: weak → %s, unsafe_unretained → %s\n",
               [wPerson.name UTF8String],
               [uPerson.name UTF8String]);
    } // p 离开作用域 → dealloc → weak 自动置 nil

    printf("  对象释放后: weak → %s（自动 nil ✅）\n",
           wPerson == nil ? "nil" : "非nil(异常)");

    // ⚠️ 注意：打印 uPerson 是未定义行为，可能 crash
    printf("  对象释放后: unsafe_unretained → 悬垂指针！访问即 EXC_BAD_ACCESS 💀\n");

    printf("\n【使用场景】\n");
    printf("  assign → NSInteger, CGFloat, BOOL, CGRect, CGPoint 等值类型\n");
    printf("  assign → struct / union / enum\n");
    printf("  weak   → delegate 代理对象\n");
    printf("  weak   → IBOutlet（Storyboard 中的 UI 控件引用）\n");
    printf("  weak   → block 外捕获 self（打破循环引用）\n");

    [self printPitfall:@[
        @"assign 修饰对象是 MRC 时代的习惯，ARC 下对象必须用 weak/strong",
        @"assign 修饰对象 + 对象释放后访问 = EXC_BAD_ACCESS，极难排查",
        @"unsafe_unretained 和 assign 对对象的效果一样（都是悬垂指针），只是语义更明确",
        @"weak 只能用于 ARC，且部署目标 ≥ iOS 5 / macOS 10.7",
    ]];
}

//==============================================================================
// MARK: Q6 · 原理题 — 为什么 NSString 要用 copy
//==============================================================================

- (void)question6_copyVsStrong {
    [self printQ:@"Q6"
           title:@"为什么 NSString / NSArray / NSDictionary 要用 copy 而不是 strong？"
            type:@"原理"];

    printf("【一句话答案】\n");
    printf("  防止外部传入的可变对象被意外修改，破坏封装性。\n\n");

    printf("【代码演示 — strong 的风险】\n");
    Person *pStrong = [[Person alloc] init];
    NSMutableString *mutableName = [NSMutableString stringWithString:@"张三"];

    pStrong.name = mutableName;   // strong: 指向同一个 NSMutableString 对象
    printf("  赋值后 pStrong.name = %s\n", [pStrong.name UTF8String]);

    [mutableName appendString:@"(已被篡改)"];  // 外部修改！
    printf("  外部修改 mutableName 后 pStrong.name = %s\n", [pStrong.name UTF8String]);
    printf("  ❌ 属性在不知情的情况下被修改了！这违反了封装原则。\n\n");

    printf("【代码演示 — copy 的保护】\n");
    Person *pCopy = [[Person alloc] init];
    NSMutableString *mutableNick = [NSMutableString stringWithString:@"李四"];

    pCopy.nickname = mutableNick;   // copy: 创建了一个不可变的 NSString 副本
    printf("  赋值后 pCopy.nickname 类型: %s（已经是不可变 NSString）\n",
           [NSStringFromClass([pCopy.nickname class]) UTF8String]);

    [mutableNick appendString:@"(篡改失败)"];  // 外部修改不影响属性
    printf("  外部修改 mutableNick 后 pCopy.nickname = %s\n", [pCopy.nickname UTF8String]);
    printf("  ✅ 属性不受影响！\n\n");

    printf("【工程设计原则】\n");
    printf("  1. 对外暴露不可变类型的属性，一律用 copy\n");
    printf("  2. 对外暴露可变类型的属性，用 strong（别用 copy！见 Q1）\n");
    printf("  3. Block 属性在 MRC 下用 copy（栈→堆），ARC 下编译器自动处理\n");
    printf("  4. 自定义对象要实现 NSCopying 协议才能用 copy\n");

    [self printPitfall:@[
        @"NSString 属性用 strong 没问题的情况：确定外部不会传 NSMutableString",
        @"但无法保证 — 防御性编程要求用 copy，代价极小（不可变对象 copy 就是 retain）",
        @"不可变对象的 copy 是浅拷贝（甚至直接返回自己），性能开销几乎为零",
        @"面试追问：「那 NSMutableString 属性用 strong 还是 copy？」→ strong！原因见 Q1",
    ]];
}

//==============================================================================
// MARK: Q7 · 原理题 — 深拷贝 vs 浅拷贝
//==============================================================================

- (void)question7_deepVsShallowCopy {
    [self printQ:@"Q7"
           title:@"深拷贝(mutableCopy)和浅拷贝(copy)的本质区别？集合类型的拷贝有什么坑？"
            type:@"原理"];

    printf("【核心概念】\n\n");
    printf("  浅拷贝 (Shallow Copy)：只拷贝容器本身，内部元素还是同一个对象\n");
    printf("  深拷贝 (Deep Copy)：  容器和内部元素都创建新的副本\n\n");

    printf("  copy       → 返回不可变对象（如果原对象不可变，可能返回自身）\n");
    printf("  mutableCopy → 返回可变对象（永远是新的）\n\n");

    printf("【代码演示】\n");

    // 1. NSString 的 copy（不可变 → 返回自身，Tagged Pointer 除外）
    NSString *str = @"Hello";
    NSString *copiedStr = [str copy];
    printf("  str == copiedStr: %s（同一个对象，copy 只 retain）\n",
           str == copiedStr ? "YES ✅" : "NO");

    // 2. NSMutableString 的 copy（可变 → 返回不可变副本）
    NSMutableString *mStr = [NSMutableString stringWithString:@"World"];
    NSString *mCopied = [mStr copy];
    printf("  mStr == mCopied: %s（不同对象，新创建的不可变副本）\n",
           mStr == mCopied ? "YES" : "NO ✅");
    printf("  mCopied 类型: %s\n", [NSStringFromClass([mCopied class]) UTF8String]);

    // 3. 集合类型的浅拷贝（只拷贝数组结构，元素还是同一个）
    NSMutableString *elem = [NSMutableString stringWithString:@"原始值"];
    NSArray *arr1 = @[elem];
    NSArray *arr2 = [arr1 copy];  // 浅拷贝

    printf("\n  arr1 == arr2: %s（容器不同对象）\n",
           arr1 == arr2 ? "YES" : "NO ✅");
    printf("  arr1[0] == arr2[0]: %s（元素是同一个对象！⚠️）\n",
           arr1[0] == arr2[0] ? "YES ⚠️" : "NO");

    [elem appendString:@" - 被改了!"];
    printf("  修改原始元素后 arr2[0] = %s（浅拷贝的元素也被影响了！）\n",
           [[arr2[0] description] UTF8String]);

    // 4. 集合深拷贝
    printf("\n【集合深拷贝的正确姿势】\n");
    NSArray *deepArr = [[NSArray alloc] initWithArray:arr1 copyItems:YES];
    printf("  arr1[0] == deepArr[0]: %s（深拷贝后元素也不同 ✅）\n",
           arr1[0] == deepArr[0] ? "YES" : "NO ✅");

    printf("\n【集合拷贝总结表】\n");
    printf("  ┌────────────────────┬─────────────┬──────────────┐\n");
    printf("  │ 操作               │ 容器        │ 内部元素     │\n");
    printf("  ├────────────────────┼─────────────┼──────────────┤\n");
    printf("  │ [arr copy]         │ 新(不可变)  │ 同一对象     │\n");
    printf("  │ [arr mutableCopy]  │ 新(可变)    │ 同一对象     │\n");
    printf("  │ initWithArray:copyItems:YES│ 新   │ 新(copy)     │\n");
    printf("  │ 手动遍历 copy 元素 │ 新          │ 新           │\n");
    printf("  └────────────────────┴─────────────┴──────────────┘\n");

    [self printPitfall:@[
        @"集合类型的 copy/mutableCopy 都是浅拷贝（内部元素不复制）",
        @"需要深拷贝时使用 initWithArray:copyItems:YES，但要求元素实现 NSCopying",
        @"不可变对象的 copy 可能直接返回自身（优化），不要依赖指针比较来判断拷贝成功",
        @"Tagged Pointer（短字符串、小数字）的 copy 行为特殊，面试时提到可加分",
    ]];
}

//==============================================================================
// MARK: Q8 · 原理题 — weak 底层实现
//==============================================================================

- (void)question8_weakImplementation {
    [self printQ:@"Q8"
           title:@"weak 引用的底层实现原理是什么？（SideTable + weak_entry_t）"
            type:@"原理"];

    printf("【面试标准答案框架】\n\n");
    printf("  weak 的底层依赖 runtime 的 SideTable 机制，核心数据结构有：\n\n");

    printf("  1. StripedMap（分片哈希表）\n");
    printf("     - 全局有 64 个 SideTable（实际数量可配置）\n");
    printf("     - 根据对象地址哈希分散到不同 SideTable\n");
    printf("     - 分片=减少锁竞争（不同对象走不同的 SideTable 锁）\n\n");

    printf("  2. SideTable 结构\n");
    printf("     - spinlock_t: 自旋锁保护并发访问\n");
    printf("     - RefcountMap: 引用计数表（对象的 isa 不够存时溢出到这里）\n");
    printf("     - weak_table_t: 弱引用表\n\n");

    printf("  3. weak_table_t → weak_entry_t\n");
    printf("     - 以对象地址为 key\n");
    printf("     - weak_entry_t 包含一个数组，存储所有指向该对象的弱引用指针地址\n");
    printf("     - 初始容量 4 个指针，超过后动态扩容\n\n");

    printf("【weak 引用建立流程】\n");
    printf("  id obj = [[NSObject alloc] init];\n");
    printf("  __weak id weakObj = obj;\n\n");
    printf("  1. objc_initWeak(&weakObj, obj)\n");
    printf("  2. storeWeak(&weakObj, obj)\n");
    printf("  3. 获取 obj 所在的 SideTable（obj → hash → SideTable index）\n");
    printf("  4. 加锁，在 SideTable.weak_table 中注册 weakObj 的地址\n");
    printf("  5. weak_entry_t 数组追加 &weakObj\n\n");

    printf("【weak 置 nil 流程（dealloc 时）】\n");
    printf("  1. dealloc → _objc_rootDealloc → objc_destructInstance\n");
    printf("  2. objc_destructInstance 中调用 weak_clear_no_lock\n");
    printf("  3. 遍历该对象 weak_entry_t 中所有弱引用指针地址\n");
    printf("  4. 逐个将 *ptr = nil（零化）\n");
    printf("  5. 从 weak_table 中移除该 entry\n\n");

    printf("【性能考量】\n");
    printf("  - 大量 weak 引用会拖慢 dealloc（需遍历置 nil）\n");
    printf("  - SideTable 分片设计减少锁竞争\n");
    printf("  - weak 引用的创建/销毁都比 strong 贵（需操作 SideTable）\n");

    [self printPitfall:@[
        @"SideTable 数量不是固定的（StripedMap），别在面试中说「全局只有一个 SideTable」",
        @"weak 指针地址存在 weak_entry_t 中，不是存对象本身",
        @"面试加分项：提到 Swift 的 weak 实际上也是用的 ObjC runtime 这套机制",
        @"面试加分项：weak 不支持 Tagged Pointer（Tagged Pointer 不是真正的对象指针）",
    ]];
}

//==============================================================================
// MARK: Q9 · 原理题 — dealloc 时 weak 引用发生了什么
//==============================================================================

- (void)question9_weakDeallocFlow {
    [self printQ:@"Q9"
           title:@"对象 dealloc 时，weak 引用到底经历了什么？（完整流程）"
            type:@"原理"];

    printf("【dealloc 完整调用栈】\n\n");
    printf("  -[NSObject dealloc]\n");
    printf("    └── _objc_rootDealloc(self)\n");
    printf("        └── objc_destructInstance(self)\n");
    printf("            ├── object_cxxDestruct(self)       // C++ 析构\n");
    printf("            ├── _object_remove_assocations(self) // 移除关联对象\n");
    printf("            └── weak_clear_no_lock(&table, self) // ⭐ 清零弱引用\n");
    printf("        └── free(self)                          // 释放内存\n\n");

    printf("  关键：weak 引用在 free() 之前全部置 nil。\n");
    printf("  所以 weak 是安全的——要么指向有效对象，要么是 nil。\n\n");

    printf("【代码演示】\n");
    __weak Person *wPerson = nil;
    printf("  1. 创建对象前: wPerson = %s\n", wPerson == nil ? "nil" : "非nil");

    @autoreleasepool {
        Person *p = [[Person alloc] init];
        p.name = @"测试对象";
        wPerson = p;
        printf("  2. 对象存活中: wPerson.name = %s\n", [wPerson.name UTF8String]);
    } // ← p 离开作用域，引用计数归零 → dealloc → weak_clear_no_lock

    printf("  3. dealloc 后: wPerson = %s\n", wPerson == nil ? "nil ✅" : "非nil ❌");
    printf("  4. 访问 wPerson.name 是安全的，返回 nil（向 nil 发消息返回 0/nil）\n\n");

    printf("【对比 unsafe_unretained / assign】\n");
    printf("  unsafe_unretained 在 dealloc 后不会置 nil，指针还指向已释放的内存。\n");
    printf("  再次访问 = 野指针 = EXC_BAD_ACCESS 💀\n");
    printf("  这也是为什么 ARC 引入了 weak 来替代 MRC 的 assign。\n");

    [self printPitfall:@[
        @"weak 置 nil 发生在 free() 之前，确保安全窗口",
        @"如果有大量 weak 引用指向同一个对象，dealloc 时会遍历全部置 nil，耗时 O(n)",
        @"MRC 下没有 weak，只能用 assign/unsafe_unretained + 手动置 nil（容易忘）",
        @"面试追问：「weak 引用在哪个线程被置 nil？」→ 最后一个 release 的那个线程",
    ]];
}

//==============================================================================
// MARK: Q10 · 原理题 — @property 在 ARC vs MRC 时代
//==============================================================================

- (void)question10_arcVsMrc {
    [self printQ:@"Q10"
           title:@"@property 关键字在 ARC 和 MRC 时代有什么区别？retain 和 strong 是什么关系？"
            type:@"原理"];

    printf("【属性关键字演变】\n\n");
    printf("  ┌──────────────────┬─────────────────┬──────────────────────┐\n");
    printf("  │ 关键字           │ MRC             │ ARC                  │\n");
    printf("  ├──────────────────┼─────────────────┼──────────────────────┤\n");
    printf("  │ strong           │ ❌ 不存在       │ ✅ 强引用(替代retain) │\n");
    printf("  │ retain           │ ✅ 强引用       │ ✅ 等同于 strong      │\n");
    printf("  │ weak             │ ❌ 不存在       │ ✅ 安全的弱引用       │\n");
    printf("  │ assign           │ ✅ 基础类型+对象│ ✅ 仅基础类型使用     │\n");
    printf("  │ unsafe_unretained│ ❌ 不存在(MRC不区分)│ ✅ 不安全的弱引用   │\n");
    printf("  │ copy             │ ✅ (block必须)  │ ✅ (block自动处理)    │\n");
    printf("  │ atomic/nonatomic │ ✅              │ ✅ 默认atomic         │\n");
    printf("  │ readonly/readwrite│ ✅             │ ✅                    │\n");
    printf("  └──────────────────┴─────────────────┴──────────────────────┘\n\n");

    printf("【strong vs retain】\n");
    printf("  二者 100%% 等价。strong 是 ARC 时代的命名，语义更清晰（强引用）。\n");
    printf("  编译器处理完全一致，可以互换使用。\n");
    printf("  面试时说「strong 和 retain 等价，strong 是 ARC 时代的推荐写法」即可。\n\n");

    printf("【@synthesize 的演变】\n");
    printf("  - 早期 ObjC: 必须手动写 @synthesize name = _name;\n");
    printf("  - 现代 ObjC: 编译器自动合成（除非同时重写 getter 和 setter）\n");
    printf("  - 自动合成 = 自动生成 _ivar + getter + setter\n");
    printf("  - 如果同时重写 getter AND setter，需手动 @synthesize\n\n");

    printf("【ARC 自动插入的内存管理代码】\n");
    printf("  MRC:                             ARC（编译器自动插入）:\n");
    printf("  Person *p = [[Person alloc] init];   Person *p = [[Person alloc] init];\n");
    printf("  [p setName:@\"hi\"];                  p.name = @\"hi\";\n");
    printf("  // ...                               // ...\n");
    printf("  [p release];  ← 手动释放            // 编译器自动插入 release\n\n");

    printf("【Block 属性的变化】\n");
    printf("  MRC: @property (nonatomic, copy) void(^block)(void);\n");
    printf("       MRC 下 block 在栈上创建，copy 将其拷贝到堆上保留\n\n");
    printf("  ARC: @property (nonatomic, strong) void(^block)(void);\n");
    printf("       ARC 下编译器自动将 block copy 到堆上，strong 就够用\n");
    printf("       但出于习惯 + 防御性编程，仍有很多团队用 copy 修饰 block\n");

    [self printPitfall:@[
        @"MRC 下没有 weak，代理用 assign 修饰，需在 dealloc 中手动置 nil",
        @"ARC 下 assign 只能用于基础类型，修饰对象是严重错误",
        @"面试被问「strong 和 retain 有什么区别」→ 答「没有区别，等同」",
        @"现代 ObjC 几乎不需要手动写 @synthesize（除非同时重写 getter + setter）",
    ]];
}

@end

//==============================================================================
// MARK: - UnsafeCounter 实现（Q2 辅助类）
//==============================================================================

@implementation UnsafeCounter

- (void)resetAndRace {
    self.count = 0;
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    for (int i = 0; i < 5000; i++) {
        dispatch_group_async(group, queue, ^{
            // ⚠️ 这是复合操作：读-改-写，atomic 保护不了！
            self.count = self.count + 1;
        });
    }

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

@end

//==============================================================================
// MARK: - SafeCounter 实现（Q2 辅助类）
//==============================================================================

@implementation SafeCounter {
    os_unfair_lock _lock;
    NSInteger _count;
}

- (instancetype)init {
    if (self = [super init]) {
        _lock = OS_UNFAIR_LOCK_INIT;
        _count = 0;
    }
    return self;
}

- (void)increment {
    os_unfair_lock_lock(&_lock);
    _count++;
    os_unfair_lock_unlock(&_lock);
}

- (NSInteger)count {
    os_unfair_lock_lock(&_lock);
    NSInteger c = _count;
    os_unfair_lock_unlock(&_lock);
    return c;
}

- (void)resetAndConcurrentIncrement {
    os_unfair_lock_lock(&_lock);
    _count = 0;
    os_unfair_lock_unlock(&_lock);

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    for (int i = 0; i < 5000; i++) {
        dispatch_group_async(group, queue, ^{
            [self increment];  // 整个操作在锁保护下完成
        });
    }

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

@end
