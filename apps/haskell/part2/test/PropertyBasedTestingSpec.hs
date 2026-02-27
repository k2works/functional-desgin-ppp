{-|
Module      : PropertyBasedTestingSpec
Description : Tests for Chapter 5 - Property-Based Testing
-}
module PropertyBasedTestingSpec (spec) where

import Test.Hspec
import Test.QuickCheck
import PropertyBasedTesting
import Data.List (sort)

spec :: Spec
spec = do
    describe "String Functions" $ do
        describe "reverseString" $ do
            it "reversing twice returns original" $ property $
                \s -> reverseString (reverseString s) == (s :: String)
            
            it "reverse of empty is empty" $
                reverseString "" `shouldBe` ""
            
            it "reverse preserves length" $ property $
                \s -> length (reverseString s) == length (s :: String)

        describe "capitalize" $ do
            it "capitalizes first letter" $
                capitalize "hello" `shouldBe` "Hello"
            
            it "handles empty string" $
                capitalize "" `shouldBe` ""
            
            it "preserves length" $ property $
                \s -> length (capitalize s) == length (s :: String)

        describe "isPalindrome" $ do
            it "recognizes palindromes" $ do
                isPalindrome "radar" `shouldBe` True
                isPalindrome "level" `shouldBe` True
                isPalindrome "A man a plan a canal Panama" `shouldBe` True
            
            it "rejects non-palindromes" $
                isPalindrome "hello" `shouldBe` False

    describe "List Functions" $ do
        describe "mySort" $ do
            it "sorted list is sorted" $ property $
                \xs -> isSorted (mySort (xs :: [Int]))
            
            it "sorted list has same length" $ property $
                \xs -> length (mySort xs) == length (xs :: [Int])
            
            it "sorted list has same elements" $ property $
                \xs -> sort (mySort xs) == sort (xs :: [Int])
            
            it "sorting is idempotent" $ property $
                \xs -> mySort (mySort xs) == mySort (xs :: [Int])

        describe "myReverse" $ do
            it "reverse of reverse is identity" $ property $
                \xs -> myReverse (myReverse xs) == (xs :: [Int])
            
            it "reverse preserves length" $ property $
                \xs -> length (myReverse xs) == length (xs :: [Int])

        describe "myFilter" $ do
            it "all elements satisfy predicate" $ property $
                \xs -> all even (myFilter even (xs :: [Int]))
            
            it "filter with True keeps all" $ property $
                \xs -> myFilter (const True) xs == (xs :: [Int])
            
            it "filter with False removes all" $ property $
                \xs -> null (myFilter (const False) (xs :: [Int]))

    describe "Math Functions" $ do
        describe "absolute" $ do
            it "absolute is non-negative" $ property $
                \n -> absolute n >= (0 :: Int)
            
            it "absolute of negative is positive" $ property $
                \(Positive n) -> absolute (-n) == (n :: Int)
            
            it "absolute is idempotent" $ property $
                \n -> absolute (absolute n) == absolute (n :: Int)

        describe "factorial" $ do
            it "factorial of 0 is 1" $
                factorial 0 `shouldBe` 1
            
            it "factorial of 1 is 1" $
                factorial 1 `shouldBe` 1
            
            it "factorial of 5 is 120" $
                factorial 5 `shouldBe` 120
            
            it "factorial is always positive for non-negative input" $ property $
                \(NonNegative n) -> 
                    let n' = min n 20  -- Limit to avoid huge numbers
                    in factorial n' > 0

        describe "fibonacci" $ do
            it "fib(0) = 0" $
                fibonacci 0 `shouldBe` 0
            
            it "fib(1) = 1" $
                fibonacci 1 `shouldBe` 1
            
            it "fib(10) = 55" $
                fibonacci 10 `shouldBe` 55
            
            it "satisfies recurrence relation" $ property $
                \(NonNegative n) ->
                    let n' = min n 20  -- Limit for performance
                    in n' < 2 || fibonacci n' == fibonacci (n' - 1) + fibonacci (n' - 2)

    describe "Money Operations" $ do
        describe "addMoney" $ do
            it "adds same currency" $ do
                let m1 = Money 100 "JPY"
                let m2 = Money 200 "JPY"
                addMoney m1 m2 `shouldBe` Just (Money 300 "JPY")
            
            it "fails for different currencies" $ do
                let m1 = Money 100 "JPY"
                let m2 = Money 200 "USD"
                addMoney m1 m2 `shouldBe` Nothing
            
            it "addition is commutative" $ property $
                \a1 a2 ->
                    let m1 = Money a1 "JPY"
                        m2 = Money a2 "JPY"
                    in addMoney m1 m2 == addMoney m2 m1
            
            it "addition is associative" $ property $
                \a1 a2 a3 ->
                    let m1 = Money a1 "JPY"
                        m2 = Money a2 "JPY"
                        m3 = Money a3 "JPY"
                        left = addMoney m1 m2 >>= \s -> addMoney s m3
                        right = addMoney m2 m3 >>= \s -> addMoney m1 s
                    in left == right

        describe "multiplyMoney" $ do
            it "multiplies correctly" $ do
                let m = Money 100 "JPY"
                multiplyMoney m 3 `shouldBe` Money 300 "JPY"
            
            it "multiply by 1 is identity" $ property $
                \amount ->
                    let m = Money amount "JPY"
                    in multiplyMoney m 1 == m
            
            it "multiply by 0 is zero" $ property $
                \amount ->
                    let m = Money amount "JPY"
                    in multiplyMoney m 0 == Money 0 "JPY"

    describe "Stack Operations" $ do
        it "push then pop returns element" $ property $
            \x -> 
                let s = push (x :: Int) emptyStack
                in pop s == Just (x, emptyStack)
        
        it "push increases size" $ property $
            \x xs ->
                let s = foldr push emptyStack (xs :: [Int])
                    s' = push x s
                in size s' == size s + 1
        
        it "empty stack has size 0" $
            size (emptyStack :: Stack Int) `shouldBe` 0
        
        it "pop from empty returns Nothing" $
            pop (emptyStack :: Stack Int) `shouldBe` Nothing
        
        it "isEmpty is true for empty stack" $
            isEmpty (emptyStack :: Stack Int) `shouldBe` True
        
        it "isEmpty is false after push" $ property $
            \x -> not (isEmpty (push (x :: Int) emptyStack))
        
        it "peek returns top without removing" $ property $
            \x ->
                let s = push (x :: Int) emptyStack
                in peek s == Just x && size s == 1

    describe "FizzBuzz" $ do
        it "returns Fizz for multiples of 3 only" $ property $
            \(Positive n) ->
                let num = n * 3
                in num `mod` 5 /= 0 ==> fizzBuzz num == "Fizz"
        
        it "returns Buzz for multiples of 5 only" $ property $
            \(Positive n) ->
                let num = n * 5
                in num `mod` 3 /= 0 ==> fizzBuzz num == "Buzz"
        
        it "returns FizzBuzz for multiples of 15" $ property $
            \(Positive n) ->
                fizzBuzz (n * 15) == "FizzBuzz"
        
        it "returns number for non-multiples" $ property $
            \(Positive n) ->
                n `mod` 3 /= 0 && n `mod` 5 /= 0 ==> fizzBuzz n == show n

-- Helper function
isSorted :: Ord a => [a] -> Bool
isSorted [] = True
isSorted [_] = True
isSorted (x:y:rest) = x <= y && isSorted (y:rest)
