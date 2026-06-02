//
//  Person.h
//  InterviewDemo - 属性关键字综合演示模型
//
//  Created by 杨 on 2026/6/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Person 类用于演示 Objective-C 属性关键字的方方面面：
 * - 内存管理: strong, weak, copy, assign, unsafe_unretained
 * - 原子性: atomic, nonatomic
 * - 读写控制: readonly
 * - 命名: getter, setter
 * - 可空性: nullable, nonnull, null_resettable
 * - 类属性: class
 * - KVO 兼容的依赖属性
 */
@interface Person : NSObject

// MARK: - strong: 强引用（ARC 下引用计数 +1）
@property (nonatomic, strong) NSString *name;

// MARK: - copy: 赋值时调用 copy 方法创建不可变副本
@property (nonatomic, copy) NSString *nickname;
// ⚠️ 陷阱! copy 修饰的可变类型：传入 NSMutableString 会被 copy 成不可变 NSString
@property (nonatomic, copy) NSMutableString *bio;

// MARK: - weak: 弱引用（对象释放时 runtime 自动置 nil，安全）
@property (nonatomic, weak) id delegate;

// MARK: - assign: 直接赋值，不涉及引用计数（基础类型专用）
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) CGFloat height;

// MARK: - unsafe_unretained: 不安全的弱引用（对象释放后不置 nil → 悬垂指针）
@property (nonatomic, unsafe_unretained) id observer;

// MARK: - readonly: 只读（外部 .h 声明只读，内部 .m 类扩展可声明 readwrite）
@property (nonatomic, readonly, copy) NSString *identifier;

// MARK: - 自定义 getter/setter 命名 (getter=)
@property (nonatomic, strong, getter=isActive) NSNumber *active;

// MARK: - atomic: 原子性（默认，getter/setter 有锁，保证读写原子性但不保证线程安全）
@property (atomic, strong) NSNumber *atomicBalance;

// MARK: - nullability: Swift 互操作 + 编译器检查
@property (nullable, nonatomic, copy) NSString *email;
@property (nonnull, nonatomic, copy) NSString *requiredName;
@property (null_resettable, nonatomic, copy) NSString *resettableTitle;

// MARK: - KVO 兼容的依赖属性（fullName 依赖 firstName + lastName）
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, readonly, copy) NSString *fullName;

// MARK: - class property: 类属性
@property (class, nonatomic, strong, readonly) Person *shared;

@end

NS_ASSUME_NONNULL_END
