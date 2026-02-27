{-|
Module      : FunctionCompositionSpec
Description : Tests for Chapter 2 - Function Composition and Higher-Order Functions
-}
module FunctionCompositionSpec (spec) where

import Test.Hspec
import Test.QuickCheck
import FunctionComposition hiding (Success, Failure)
import qualified FunctionComposition as FC

spec :: Spec
spec = do
    describe "Basic Composition" $ do
        it "addTax adds correct tax" $ do
            addTax 0.1 1000 `shouldBe` 1100.0

        it "applyDiscountRate applies correct discount" $ do
            applyDiscountRate 0.2 1000 `shouldBe` 800.0

        it "roundToYen rounds to nearest integer" $ do
            roundToYen 880.4 `shouldBe` 880
            roundToYen 880.5 `shouldBe` 880
            roundToYen 880.6 `shouldBe` 881

        it "calculateFinalPrice composes functions left to right" $ do
            -- 1000 -> 20% off (800) -> 10% tax (880) -> round (880)
            calculateFinalPrice 1000 `shouldBe` 880

        it "calculateFinalPriceCompose gives same result as calculateFinalPrice" $ do
            calculateFinalPriceCompose 1000 `shouldBe` calculateFinalPrice 1000

    describe "Partial Application (Currying)" $ do
        it "greet combines greeting and name" $ do
            greet "Hello" "田中" `shouldBe` "Hello, 田中!"

        it "sayHello is partial application of greet" $ do
            sayHello "田中" `shouldBe` "Hello, 田中!"

        it "sayGoodbye is partial application of greet" $ do
            sayGoodbye "鈴木" `shouldBe` "Goodbye, 鈴木!"

        it "sendEmail creates email record" $ do
            let email = sendEmail "from@example.com" "to@example.com" "Subject" "Body"
            emailFrom email `shouldBe` "from@example.com"
            emailTo email `shouldBe` "to@example.com"
            emailSubject email `shouldBe` "Subject"
            emailBody email `shouldBe` "Body"

        it "sendFromSystem is partial application" $ do
            let email = sendFromSystem "to@example.com" "Subject" "Body"
            emailFrom email `shouldBe` "system@example.com"

        it "sendNotification is deeply partial applied" $ do
            let email = sendNotification "メッセージ本文"
            emailFrom email `shouldBe` "system@example.com"
            emailTo email `shouldBe` "user@example.com"
            emailSubject email `shouldBe` "通知"
            emailBody email `shouldBe` "メッセージ本文"

    describe "Parallel Function Application (juxt)" $ do
        it "juxt2 applies two functions" $ do
            juxt2 (*2) (+10) 5 `shouldBe` (10, 15)

        it "juxt3 applies three functions" $ do
            juxt3 head last length [1, 2, 3] `shouldBe` (1, 3, 3)

        it "getStats returns list statistics" $ do
            getStats [3, 1, 4, 1, 5, 9, 2, 6] `shouldBe` (3, 6, 8, 1, 9)

        it "analyzePerson returns analysis for adult" $ do
            let analysis = analyzePerson "田中" 25
            analysisName analysis `shouldBe` "田中"
            analysisAge analysis `shouldBe` 25
            analysisCategory analysis `shouldBe` Adult

        it "analyzePerson returns analysis for minor" $ do
            let analysis = analyzePerson "鈴木" 15
            analysisCategory analysis `shouldBe` Minor

    describe "Higher-Order Functions" $ do
        it "processWithLogging returns result with log" $ do
            let (result, logEntry) = processWithLogging (*2) 5
            result `shouldBe` 10
            logInput logEntry `shouldBe` 5
            logOutput logEntry `shouldBe` 10

        it "withRetry succeeds on first try" $ do
            let f x = Right (x * 2)
            withRetry 3 f 5 `shouldBe` FC.Success 10

        it "withRetry fails after max retries" $ do
            let f _ = Left "error" :: Either String Int
            withRetry 3 f 5 `shouldBe` FC.Failure "Max retries exceeded" 3

    describe "Validators" $ do
        it "validateNonEmpty accepts non-empty string" $ do
            validateNonEmpty "test" `shouldBe` Valid

        it "validateNonEmpty rejects empty string" $ do
            validateNonEmpty "" `shouldBe` Invalid "Value cannot be empty"

        it "validateMinLength checks minimum length" $ do
            validateMinLength 5 "hello" `shouldBe` Valid
            validateMinLength 5 "hi" `shouldBe` Invalid "Must be at least 5 characters"

        it "validateMaxLength checks maximum length" $ do
            validateMaxLength 5 "hi" `shouldBe` Valid
            validateMaxLength 5 "hello world" `shouldBe` Invalid "Must be at most 5 characters"

        it "validateEmail checks email format" $ do
            validateEmail "test@example.com" `shouldBe` Valid
            validateEmail "invalid" `shouldBe` Invalid "Invalid email format"

        it "validateAge checks age range" $ do
            validateAge 25 `shouldBe` Valid
            validateAge (-1) `shouldBe` Invalid "Age cannot be negative"
            validateAge 200 `shouldBe` Invalid "Age seems unrealistic"

        it "combineValidators combines two validators" $ do
            let combined = combineValidators validateNonEmpty (validateMinLength 3)
            combined "hello" `shouldBe` Valid
            combined "" `shouldBe` Invalid "Value cannot be empty"
            combined "hi" `shouldBe` Invalid "Must be at least 3 characters"

        it "validateAll collects all failures" $ do
            let validators = [validateNonEmpty, validateMinLength 5, validateEmail]
            let failures = validateAll validators "hi"
            length failures `shouldBe` 2  -- minLength and email fail

    describe "QuickCheck Properties" $ do
        it "composition order matters" $ property $
            \(Positive x) ->
                calculateFinalPrice x == calculateFinalPriceCompose x

        it "juxt2 applies both functions to same input" $ property $
            \x ->
                let (a, b) = juxt2 (+1) (*2) (x :: Int)
                in a == x + 1 && b == x * 2
