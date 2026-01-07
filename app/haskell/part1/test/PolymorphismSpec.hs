{-|
Module      : PolymorphismSpec
Description : Tests for Chapter 3 - Polymorphism and Dispatch
-}
module PolymorphismSpec (spec) where

import Test.Hspec
import Test.QuickCheck hiding (scale)
import Polymorphism

spec :: Spec
spec = do
    describe "Shape - ADT Polymorphism" $ do
        it "calculates rectangle area" $ do
            calculateArea (Rectangle' 4 5) `shouldBe` 20.0

        it "calculates circle area" $ do
            calculateArea (Circle' 3) `shouldSatisfy` (\a -> abs (a - 28.274333882308138) < 0.0001)

        it "calculates triangle area" $ do
            calculateArea (Triangle' 6 5) `shouldBe` 15.0

        it "calculates square area" $ do
            calculateArea (Square' 4) `shouldBe` 16.0

        it "calculates rectangle perimeter" $ do
            calculatePerimeter (Rectangle' 4 5) `shouldBe` 18.0

        it "calculates circle perimeter" $ do
            calculatePerimeter (Circle' 3) `shouldSatisfy` (\p -> abs (p - 18.84955592153876) < 0.0001)

        it "calculates square perimeter" $ do
            calculatePerimeter (Square' 4) `shouldBe` 16.0

    describe "Payment - Composite Dispatch" $ do
        it "processes credit card JPY payment" $ do
            let payment = Payment CreditCard JPY 1000
            let result = processPayment payment
            resultStatus result `shouldBe` "processed"
            resultMessage result `shouldBe` "クレジットカード（円）で処理しました"
            resultConverted result `shouldBe` Nothing

        it "processes credit card USD payment with conversion" $ do
            let payment = Payment CreditCard USD 100
            let result = processPayment payment
            resultStatus result `shouldBe` "processed"
            resultConverted result `shouldBe` Just 15000

        it "processes bank transfer JPY as pending" $ do
            let payment = Payment BankTransfer JPY 5000
            let result = processPayment payment
            resultStatus result `shouldBe` "pending"

        it "processes cash payment" $ do
            let payment = Payment Cash JPY 1000
            let result = processPayment payment
            resultStatus result `shouldBe` "processed"
            resultMessage result `shouldBe` "現金で処理しました"

        it "returns error for unsupported payment" $ do
            let payment = Payment Cryptocurrency USD 1000
            let result = processPayment payment
            resultStatus result `shouldBe` "error"

    describe "Account - Hierarchical Dispatch" $ do
        it "returns correct interest rate for savings" $ do
            getInterestRate Savings `shouldBe` 0.02

        it "returns correct interest rate for premium savings" $ do
            getInterestRate PremiumSavings `shouldBe` 0.05

        it "returns correct interest rate for checking" $ do
            getInterestRate Checking `shouldBe` 0.001

        it "calculates interest for savings account" $ do
            let account = Account Savings 10000
            calculateInterest account `shouldBe` 200.0

        it "calculates interest for premium savings account" $ do
            let account = Account PremiumSavings 10000
            calculateInterest account `shouldBe` 500.0

        it "calculates interest for checking account" $ do
            let account = Account Checking 10000
            calculateInterest account `shouldBe` 10.0

    describe "Type Classes - Drawable and Transformable" $ do
        it "draws a rectangle" $ do
            let rect = Rectangle 0 0 10 20
            draw rect `shouldBe` "Rectangle at (0.0, 0.0) with size 10.0x20.0"

        it "draws a circle" $ do
            let circ = Circle 5 5 3
            draw circ `shouldBe` "Circle at (5.0, 5.0) with radius 3.0"

        it "calculates rectangle bounding box" $ do
            let rect = Rectangle 10 20 30 40
            let (minPt, maxPt) = boundingBox rect
            pointX minPt `shouldBe` 10.0
            pointY minPt `shouldBe` 20.0
            pointX maxPt `shouldBe` 40.0
            pointY maxPt `shouldBe` 60.0

        it "calculates circle bounding box" $ do
            let circ = Circle 10 10 5
            let (minPt, maxPt) = boundingBox circ
            pointX minPt `shouldBe` 5.0
            pointY minPt `shouldBe` 5.0
            pointX maxPt `shouldBe` 15.0
            pointY maxPt `shouldBe` 15.0

        it "translates a rectangle" $ do
            let rect = Rectangle 0 0 10 20
            let moved = translate 5 10 rect
            rectangleX moved `shouldBe` 5.0
            rectangleY moved `shouldBe` 10.0

        it "scales a circle" $ do
            let circ = Circle 0 0 5
            let scaled = scale 2 circ
            circleR scaled `shouldBe` 10.0

        it "supports heterogeneous drawable shapes" $ do
            let shapes = [DrawableRect (Rectangle 0 0 10 10), DrawableCircle (Circle 0 0 5)]
            length shapes `shouldBe` 2
            draw (head shapes) `shouldBe` "Rectangle at (0.0, 0.0) with size 10.0x10.0"

    describe "Expression - Data Type Operations" $ do
        it "evaluates literal" $ do
            eval (Lit 5) `shouldBe` 5

        it "evaluates addition" $ do
            eval (Add (Lit 2) (Lit 3)) `shouldBe` 5

        it "evaluates multiplication" $ do
            eval (Mul (Lit 4) (Lit 5)) `shouldBe` 20

        it "evaluates negation" $ do
            eval (Neg (Lit 7)) `shouldBe` (-7)

        it "evaluates complex expression" $ do
            let expr = Add (Mul (Lit 2) (Lit 3)) (Neg (Lit 1))
            eval expr `shouldBe` 5

        it "pretty prints expression" $ do
            prettyPrint (Add (Lit 1) (Mul (Lit 2) (Lit 3))) `shouldBe` "(1 + (2 * 3))"

    describe "Notification - Complex Dispatch" $ do
        it "sends urgent email immediately" $ do
            let notif = Notification Email Urgent "Test"
            let resp = sendNotification notif
            responseSuccess resp `shouldBe` True
            responseDetails resp `shouldBe` "Sent urgent email immediately"

        it "queues normal email" $ do
            let notif = Notification Email Normal "Test"
            let resp = sendNotification notif
            responseDetails resp `shouldBe` "Email queued for delivery"

        it "sends urgent SMS with high priority" $ do
            let notif = Notification SMS Urgent "Test"
            let resp = sendNotification notif
            responseSuccess resp `shouldBe` True

        it "rejects low priority SMS" $ do
            let notif = Notification SMS Low "Test"
            let resp = sendNotification notif
            responseSuccess resp `shouldBe` False

        it "sends push notification" $ do
            let notif = Notification Push Normal "Test"
            let resp = sendNotification notif
            responseSuccess resp `shouldBe` True

        it "sends urgent Slack with @channel" $ do
            let notif = Notification Slack Urgent "Test"
            let resp = sendNotification notif
            responseDetails resp `shouldBe` "Slack message with @channel"

    describe "Animal - Classic Polymorphism" $ do
        it "dog speaks" $ do
            speak (Dog "Pochi") `shouldBe` "Pochi says: Woof!"

        it "cat speaks" $ do
            speak (Cat "Tama") `shouldBe` "Tama says: Meow!"

        it "bird speaks" $ do
            speak (Bird "Piyo" True) `shouldBe` "Piyo says: Tweet!"

        it "dog moves on four legs" $ do
            move (Dog "Pochi") `shouldBe` "Pochi runs on four legs"

        it "flying bird moves through air" $ do
            move (Bird "Piyo" True) `shouldBe` "Piyo flies through the air"

        it "non-flying bird hops" $ do
            move (Bird "Kiwi" False) `shouldBe` "Kiwi hops on the ground"

    describe "QuickCheck Properties" $ do
        it "square area equals side squared" $ property $
            \(Positive side) ->
                calculateArea (Square' side) == side * side

        it "rectangle area equals width times height" $ property $
            \(Positive w) (Positive h) ->
                calculateArea (Rectangle' w h) == w * h

        it "circle area is positive for positive radius" $ property $
            \(Positive r) ->
                calculateArea (Circle' r) > 0

        it "eval Lit returns the literal value" $ property $
            \n ->
                eval (Lit n) == n
