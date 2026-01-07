{-|
Module      : TddFunctionalSpec
Description : Tests for Chapter 6 - TDD and Functional Programming
-}
module TddFunctionalSpec (spec) where

import Test.Hspec
import Test.QuickCheck
import TddFunctional
import qualified Data.Map as Map

spec :: Spec
spec = do
    describe "FizzBuzz (Basic TDD)" $ do
        it "1 returns \"1\"" $
            fizzBuzz 1 `shouldBe` "1"
        
        it "2 returns \"2\"" $
            fizzBuzz 2 `shouldBe` "2"
        
        it "3 returns \"Fizz\"" $
            fizzBuzz 3 `shouldBe` "Fizz"
        
        it "5 returns \"Buzz\"" $
            fizzBuzz 5 `shouldBe` "Buzz"
        
        it "15 returns \"FizzBuzz\"" $
            fizzBuzz 15 `shouldBe` "FizzBuzz"
        
        it "fizz detects multiples of 3" $ do
            fizz 3 `shouldBe` True
            fizz 6 `shouldBe` True
            fizz 4 `shouldBe` False
        
        it "buzz detects multiples of 5" $ do
            buzz 5 `shouldBe` True
            buzz 10 `shouldBe` True
            buzz 7 `shouldBe` False

    describe "Roman Numerals" $ do
        describe "toRoman" $ do
            it "converts 1 to I" $
                toRoman 1 `shouldBe` "I"
            
            it "converts 4 to IV" $
                toRoman 4 `shouldBe` "IV"
            
            it "converts 5 to V" $
                toRoman 5 `shouldBe` "V"
            
            it "converts 9 to IX" $
                toRoman 9 `shouldBe` "IX"
            
            it "converts 10 to X" $
                toRoman 10 `shouldBe` "X"
            
            it "converts 40 to XL" $
                toRoman 40 `shouldBe` "XL"
            
            it "converts 50 to L" $
                toRoman 50 `shouldBe` "L"
            
            it "converts 90 to XC" $
                toRoman 90 `shouldBe` "XC"
            
            it "converts 100 to C" $
                toRoman 100 `shouldBe` "C"
            
            it "converts 400 to CD" $
                toRoman 400 `shouldBe` "CD"
            
            it "converts 500 to D" $
                toRoman 500 `shouldBe` "D"
            
            it "converts 900 to CM" $
                toRoman 900 `shouldBe` "CM"
            
            it "converts 1000 to M" $
                toRoman 1000 `shouldBe` "M"
            
            it "converts 1994 to MCMXCIV" $
                toRoman 1994 `shouldBe` "MCMXCIV"
            
            it "converts 3999 to MMMCMXCIX" $
                toRoman 3999 `shouldBe` "MMMCMXCIX"

        describe "fromRoman" $ do
            it "converts I to 1" $
                fromRoman "I" `shouldBe` 1
            
            it "converts IV to 4" $
                fromRoman "IV" `shouldBe` 4
            
            it "converts IX to 9" $
                fromRoman "IX" `shouldBe` 9
            
            it "converts MCMXCIV to 1994" $
                fromRoman "MCMXCIV" `shouldBe` 1994

        describe "roundtrip" $ do
            it "toRoman then fromRoman returns original" $ property $
                \(Positive n) ->
                    let num = (n `mod` 3999) + 1  -- Valid range 1-3999
                    in fromRoman (toRoman num) == num

    describe "Word Count" $ do
        describe "wordCount" $ do
            it "counts words in simple text" $
                wordCount "hello world" `shouldBe` 2
            
            it "counts zero for empty string" $
                wordCount "" `shouldBe` 0
            
            it "handles punctuation" $
                wordCount "hello, world!" `shouldBe` 2

        describe "wordFrequency" $ do
            it "counts word occurrences" $ do
                let freq = wordFrequency "hello world hello"
                Map.lookup "hello" freq `shouldBe` Just 2
                Map.lookup "world" freq `shouldBe` Just 1
            
            it "is case insensitive" $ do
                let freq = wordFrequency "Hello HELLO hello"
                Map.lookup "hello" freq `shouldBe` Just 3

        describe "topWords" $ do
            it "returns top N words" $ do
                let result = topWords 2 "a a a b b c"
                result `shouldBe` [("a", 3), ("b", 2)]

    describe "Bowling Game" $ do
        describe "newGame" $ do
            it "starts with score 0" $
                score newGame `shouldBe` 0

        describe "gutter game" $ do
            it "scores 0 for all zeros" $ do
                let game = foldr roll newGame (replicate 20 0)
                score game `shouldBe` 0

        describe "all ones" $ do
            it "scores 20 for all ones" $ do
                let game = foldr roll newGame (replicate 20 1)
                score game `shouldBe` 20

        describe "spare" $ do
            it "adds next roll bonus" $ do
                -- Spare in first frame (5+5), then 3, then all zeros
                let rolls = [5, 5, 3] ++ replicate 17 0
                let game = foldr roll newGame (reverse rolls)
                score game `shouldBe` 16  -- (5+5+3) + 3 = 16

        describe "strike" $ do
            it "adds next two rolls bonus" $ do
                -- Strike in first frame, then 3, 4, then all zeros
                let rolls = [10, 3, 4] ++ replicate 16 0
                let game = foldr roll newGame (reverse rolls)
                score game `shouldBe` 24  -- (10+3+4) + 3 + 4 = 24

    describe "String Calculator" $ do
        describe "add" $ do
            it "returns 0 for empty string" $
                add "" `shouldBe` 0
            
            it "returns number for single number" $
                add "1" `shouldBe` 1
            
            it "returns sum for two numbers" $
                add "1,2" `shouldBe` 3
            
            it "handles multiple numbers" $
                add "1,2,3,4" `shouldBe` 10
            
            it "handles newlines as delimiters" $
                add "1\n2,3" `shouldBe` 6

        describe "parseNumbers" $ do
            it "parses comma separated" $
                parseNumbers "1,2,3" `shouldBe` [1, 2, 3]

    describe "Prime Factors" $ do
        it "returns empty for 1" $
            primeFactors 1 `shouldBe` []
        
        it "returns [2] for 2" $
            primeFactors 2 `shouldBe` [2]
        
        it "returns [3] for 3" $
            primeFactors 3 `shouldBe` [3]
        
        it "returns [2,2] for 4" $
            primeFactors 4 `shouldBe` [2, 2]
        
        it "returns [2,3] for 6" $
            primeFactors 6 `shouldBe` [2, 3]
        
        it "returns [2,2,2] for 8" $
            primeFactors 8 `shouldBe` [2, 2, 2]
        
        it "returns [3,3] for 9" $
            primeFactors 9 `shouldBe` [3, 3]
        
        it "returns correct factors for large number" $
            primeFactors 100 `shouldBe` [2, 2, 5, 5]
        
        it "product of factors equals original" $ property $
            \(Positive n) ->
                let n' = max 2 (n `mod` 1000)  -- Valid range 2-1000
                in product (primeFactors n') == n'
