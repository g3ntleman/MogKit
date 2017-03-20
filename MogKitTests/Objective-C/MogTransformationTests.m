//
// MogKit
//
// Copyright (c) 2015 Mikael Hallendal. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MogKit.h"


@interface MogTransformationTests : XCTestCase
@end

@implementation MogTransformationTests

- (void)testEarlyTermination
{
    NSArray *array = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
    NSArray *expected = @[@1, @2, @3, @4, @5];

    MOGReducer *reducer = MOGArrayReducer();
    reducer->reduce = ^id(NSMutableArray *acc, NSNumber *val, BOOL *stop) {
        [acc addObject:val];

        *stop = val.intValue == 5;

        return acc;
    };

    NSArray *result = MOGTransform(array, reducer, MOGIdentity());

    XCTAssertEqualObjects(expected, result);
}

- (void)testMap
{
    NSArray *array = @[@1, @2, @3, @4];
    NSArray *expected = @[@11, @12, @13, @14];
    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGMap(^id(NSNumber *number) {
        return @(number.intValue + 10);
    }));

    XCTAssertEqualObjects(expected, result);
}

- (void)testMapEmptyArray
{
    NSArray *array = @[];
    NSArray *expected = @[];
    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGMap(^id(id o) {
        return o;
    }));

    XCTAssertEqualObjects(expected, result);
}

- (void)testTransduceWithInitialValue
{
    NSArray *array = @[@1, @2, @3];
    NSArray *expected = @[@111, @222, @333, @11, @12, @13];

    NSMutableArray *initialArray = [NSMutableArray arrayWithArray:@[@111, @222, @333]];

    NSArray *result = MOGTransformWithInitial(array, MOGArrayReducer(), initialArray,
                                              MOGMap(^id(NSNumber *val) {
                                                  return @(val.intValue + 10);
                                              }));

    XCTAssertEqualObjects(expected, result);
}

- (void)testFilter
{
    NSArray *array = @[@1, @10, @15, @20];
    NSArray *expected = @[@10, @15];
    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGFilter(^BOOL(NSNumber *number) {
        int n = number.intValue;
        return n >= 10 && n <= 15;
    }));

    XCTAssertEqualObjects(expected, result);
}

- (void)testRemove
{
    NSArray *array = @[@1, @10, @15, @20];
    NSArray *expected = @[@1, @20];
    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGRemove(^BOOL(NSNumber *number) {
        int n = number.intValue;
        return n >= 10 && n <= 15;
    }));

    XCTAssertEqualObjects(expected, result);
}

- (void)testTake
{
    NSArray *array = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
    NSArray *expected = @[@1, @2, @3, @4, @5];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGTake(5));

    XCTAssertEqualObjects(expected, result);
}

- (void)testTakeWithZero
{
    NSArray *array = @[@1, @2];
    NSArray *expected = @[];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGTake(0));

    XCTAssertEqualObjects(expected, result);
}

- (void)testTakeReuseTransformation
{
    NSArray *array = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
    NSArray *expected = @[@1, @2, @3, @4, @5];

    MOGTransformation takingFive = MOGTake(5);

    NSArray *result = MOGTransform(array, MOGArrayReducer(), takingFive);
    XCTAssertEqualObjects(expected, result);

    result = MOGTransform(array, MOGArrayReducer(), takingFive);
    XCTAssertEqualObjects(expected, result);
}

- (void)testTakeWithNULLStop
{
    MOGReducer *reducer = MOGTake(1)(MOGLastValueReducer());

    XCTAssertEqualObjects(@1, reducer->reduce(@0, @1, NULL));
    XCTAssertEqualObjects(@0, reducer->reduce(@0, @2, NULL));

    reducer = MOGTake(3)(MOGLastValueReducer());
    XCTAssertEqualObjects(@1, reducer->reduce(@0, @1, NULL));
    XCTAssertEqualObjects(@2, reducer->reduce(@0, @2, NULL));
}

- (void)testTakeWhileTransformation
{
    NSArray *array = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
    NSArray *expected = @[@1, @2, @3, @4];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGTakeWhile(^BOOL(NSNumber *number) {
        return number.intValue % 5 != 0;
    }));

    XCTAssertEqualObjects(expected, result);
}

- (void)testTakeWhileWithNULLStop
{
    MOGTransformation transformation = MOGTakeWhile(^BOOL(NSNumber *number) {
        return number.intValue % 2 != 0;

        return NO;
    });

    MOGReducer *reducer = transformation(MOGLastValueReducer());

    XCTAssertEqualObjects(@1, reducer->reduce(@0, @1, NULL));
    XCTAssertEqualObjects(@0, reducer->reduce(@0, @2, NULL));
    XCTAssertEqualObjects(@0, reducer->reduce(@0, @3, NULL));

    reducer = transformation(MOGLastValueReducer());
    XCTAssertEqualObjects(@1, reducer->reduce(@0, @1, NULL));
    XCTAssertEqualObjects(@3, reducer->reduce(@0, @3, NULL));
}

- (void)testTakeNthTransformation
{
    NSArray *array = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
    NSArray *expected = @[@1, @4, @7, @10];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGTakeNth(3));

    XCTAssertEqualObjects(expected, result);
}

- (void)testDropTransformation
{
    NSArray *array = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
    NSArray *expected = @[@4, @5, @6, @7, @8, @9, @10];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGDrop(3));

    XCTAssertEqualObjects(expected, result);
}

- (void)testDropWhile
{
    NSArray *array = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
    NSArray *expected = @[@5, @6, @7, @8, @9, @10];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGDropWhile(^BOOL(NSNumber *number) {
        return number.intValue % 5 != 0;
    }));

    XCTAssertEqualObjects(expected, result);
}

- (void)testDropNilTransformation
{
    NSArray *array = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
    NSArray *expected = @[@1, @2, @3, @9, @10];

    MOGTransformation dropNil = MOGCompose(
            MOGMap(^id(NSNumber *number) {
                if (number.intValue > 3 && number.intValue < 9) {
                    return nil;
                }
                return number;
            }),
            MOGDropNil());

    NSArray *result = MOGTransform(array, MOGArrayReducer(), dropNil);

    XCTAssertEqualObjects(expected, result);
}

- (void)testReplaceTransformation
{
    NSArray *array = @[@"1", @"2", @"3", @"4", @"5"];
    NSArray *expected = @[@"a", @"b", @"c", @"d", @"e"];

    NSDictionary *replacementDict = @{ @"1" : @"a", @"2": @"b", @"3" : @"c", @"4" : @"d", @"5" : @"e" };

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGReplace(replacementDict));

    XCTAssertEqualObjects(expected, result);
}

- (void)testReplaceTransformationWithMissingTranslation
{
    NSArray *array = @[@"1", @"2", @"3", @"4", @"5"];
    NSArray *expected = @[@"a", @"2", @"c", @"4", @"e"];

    NSDictionary *replacementDict = @{ @"1" : @"a", @"3" : @"c", @"5" : @"e" };

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGReplace(replacementDict));

    XCTAssertEqualObjects(expected, result);
}

- (void)testReplaceWithDefaultTransformation
{
    NSArray *array = @[@"1", @"2", @"3", @"4", @"5"];
    NSArray *expected = @[@"a", @"-", @"c", @"-", @"e"];

    NSDictionary *replacementDict = @{ @"1" : @"a", @"3" : @"c", @"5" : @"e" };

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGReplaceWithDefault(replacementDict, @"-"));

    XCTAssertEqualObjects(expected, result);
}

- (void)testReplaceWithDefaultTransformationWithNilAsDefault
{
    NSArray *array = @[@"1", @"2", @"3", @"4", @"5"];
    NSArray *expected = @[@"a", @"2", @"c", @"4", @"e"];

    NSDictionary *replacementDict = @{ @"1" : @"a", @"3" : @"c", @"5" : @"e" };

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGReplaceWithDefault(replacementDict, nil));

    XCTAssertEqualObjects(expected, result);
}

- (void)testKeepTransformation
{
    NSArray *array = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
    NSArray *expected = @[@11, @13, @15, @17, @19];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGMapDropNil(^id(NSNumber *number) {
        return number.intValue % 2 == 0 ? nil : @(number.intValue + 10);
    }));

    XCTAssertEqualObjects(expected, result);
}

- (void)testUniqueTransformation
{
    NSArray *array = @[@1, @2, @3, @4, @3, @2, @1, @8, @9, @10];
    NSArray *expected = @[@1, @2, @3, @4, @8, @9, @10];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGUnique());

    XCTAssertEqualObjects(expected, result);
}

- (void)testDedupeTransformation
{
    NSArray *array = @[@1, @2, @2, @3, @4, @4, @4, @5, @4, @1];
    NSArray *expected = @[@1, @2, @3, @4, @5, @4, @1];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGDedupe());

    XCTAssertEqualObjects(expected, result);
}

- (void)testFlattenTransformation
{
    NSArray *array = @[@[@1, @2], @[@3, @4, @5], @[@6]];
    NSArray *expected = @[@1, @2, @3, @4, @5, @6];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGFlatten());

    XCTAssertEqualObjects(expected, result);
}

- (void)testFlattenWithMixOfNormalAndEnumerators
{
    NSArray *array = @[@1, @[@2, @3], @4, @5];
    NSArray *expected = @[@1, @2, @3, @4, @5];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGFlatten());

    XCTAssertEqualObjects(expected, result);
}

- (void)testFlattenWithNULLStop
{
    NSArray *array = @[@1, @2];
    NSArray *expected = @[@1, @2];

    MOGReducer *arrayReducer = MOGArrayReducer();
    MOGReducer *reducer = MOGFlatten()(arrayReducer);

    XCTAssertEqualObjects(expected, reducer->reduce(arrayReducer->initial(), array, NULL));
}

- (void)testFlatMapTransformation
{
    NSArray *array = @[@1, @2, @3];
    NSArray *expected = @[@1, @1, @1, @2, @2, @2, @3, @3, @3];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGFlatMap(^id(id val) {
        return @[val, val, val];
    }));

    XCTAssertEqualObjects(expected, result);
}

- (void)testFlattenTransformationWithEarlyTermination
{
    NSArray *array = @[@[@1, @2, @3], @[@4, @5, @6], @[@7, @8, @9, @10]];
    NSArray *expected = @[@1, @2, @3, @4, @5];

    MOGReducer *reducer = MOGArrayReducer();
    reducer->reduce = ^id(NSMutableArray *acc, NSNumber *val, BOOL *stop) {
        [acc addObject:val];

        *stop = val.intValue == 5;

        return acc;
    };

    NSArray *result = MOGTransform(array, reducer, MOGFlatten());

    XCTAssertEqualObjects(expected, result);
}

- (void)testPartitioningByTransformation
{
    NSArray *array = @[@1, @1, @2, @2, @3, @1];
    NSArray *expected = @[@[@1, @1], @[@2, @2], @[@3], @[@1]];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGPartitionBy(^id(id val) {
        return val;
    }));

    XCTAssertEqualObjects(expected, result);
}

- (void)testPartitionByWithEarlyTermination
{
    NSArray *array = @[@1, @1, @2, @2, @3];
    NSArray *expected = @[@[@1, @1], @[@2, @2]];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGCompose(MOGPartitionBy(^id(id val) {
        return val;
    }), MOGTake(2)));

    XCTAssertEqualObjects(expected, result);
}

- (void)testPartitionByWithNULLStop
{
    MOGReducer *reducer = MOGPartitionBy(^id(NSNumber *val) {
        return @(val.intValue % 2 == 0);
    })(MOGLastValueReducer());

    XCTAssertEqualObjects(@[], reducer->reduce(@[], @1, NULL));
    XCTAssertEqualObjects(@[@1], reducer->reduce(@[], @2, NULL));
}

- (void)testPartitionTransformation
{
    NSArray *array = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
    NSArray *expected = @[@[@1, @2], @[@3, @4], @[@5, @6], @[@7, @8], @[@9, @10]];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGPartition(2));

    XCTAssertEqualObjects(expected, result);
}

- (void)testPartitionWithNonFinishedPartition
{
    NSArray *array = @[@1, @2, @3, @4, @5, @6, @7, @8];
    NSArray *expected = @[@[@1, @2, @3], @[@4, @5, @6], @[@7, @8]];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGPartition(3));

    XCTAssertEqualObjects(expected, result);
}

- (void)testPartitionWithEarlyTermination
{
    NSArray *array = @[@1, @2, @3, @4, @5];
    NSArray *expected = @[@[@1, @2], @[@3, @4]];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGCompose(MOGPartition(2), MOGTake(2)));

    XCTAssertEqualObjects(expected, result);
}

- (void)testWindowedTransformationWithOneValue
{
    NSArray *array = @[@1];
    NSArray *expected = @[@[@1, @1, @1]];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGWindow(3));

    XCTAssertEqualObjects(expected, result);
}

- (void)testWindowedTransformationWithTwoValues
{
    NSArray *array = @[@1, @2];
    NSArray *expected = @[@[@1, @1, @1], @[@1, @1, @2]];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGWindow(3));

    XCTAssertEqualObjects(expected, result);
}

- (void)testWindowedTransformationWithMoreValuesThanWindowSize
{
    NSArray *array = @[@1, @2, @3, @4, @5];
    NSArray *expected = @[@[@1, @1, @1], @[@1, @1, @2], @[@1, @2, @3], @[@2, @3, @4], @[@3, @4, @5]];

    NSArray *result = MOGTransform(array, MOGArrayReducer(), MOGWindow(3));

    XCTAssertEqualObjects(expected, result);
}


#pragma mark - Transformation composition
- (void)testComposeTwoTransformations
{
    NSArray *array = @[@1, @10, @100];
    NSArray *expected = @[@"10", @"100"];

    MOGTransformation xform = MOGCompose(
            MOGMap(^id(NSNumber *number) {
                return [NSString stringWithFormat:@"%@", number];
            }),
            MOGFilter(^BOOL(NSString *str) {
                return str.length >= 2;
            })
    );

    NSArray *result = MOGTransform(array, MOGArrayReducer(), xform);

    XCTAssertEqualObjects(expected, result);
}

- (void)testComposeArrayOfTransformations
{
    NSArray *array = @[@50, @500, @5000, @50000];
    NSArray *expected = @[@50, @500];
    NSArray *transformations = @[
            MOGMap(^id(NSNumber *number) {
                return [NSString stringWithFormat:@"%@", number];
            }),
            MOGFilter(^BOOL(NSString *str) {
                return str.length < 4;
            }),
            MOGMap(^id(NSString *str) {
                return @(str.intValue);
            })
    ];

    MOGTransformation xform = MOGComposeArray(transformations);
    NSArray *result = MOGTransform(array, MOGArrayReducer(), xform);

    XCTAssertEqualObjects(expected, result);
}

- (void)testTransformer
{
    MOGMapFunc add10 = MOGValueTransformer(MOGMap(^id(NSNumber *number) {
        return @(number.intValue + 10);
    }));

    XCTAssertEqualObjects(@10, add10(@0));
    XCTAssertEqualObjects(@11, add10(@1));
}

- (void)testTransformerWithTerminatedTransformation
{
    MOGMapFunc add10TerminateAfter2 = MOGValueTransformer(MOGCompose(MOGTake(2), MOGMap(^id(NSNumber *number) {
        return @(number.intValue + 10);
    })));

    XCTAssertEqualObjects(@10, add10TerminateAfter2(@0));
    XCTAssertEqualObjects(@11, add10TerminateAfter2(@1));
    XCTAssertNil(add10TerminateAfter2(@2));
    XCTAssertNil(add10TerminateAfter2(@3));
}

@end
