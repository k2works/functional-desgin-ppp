{-|
Module      : DataValidationSpec
Description : Tests for Chapter 4 - Data Validation
-}
module DataValidationSpec (spec) where

import Test.Hspec
import Test.QuickCheck
import DataValidation

spec :: Spec
spec = do
    describe "Basic Validators" $ do
        describe "validateNonEmpty" $ do
            it "accepts non-empty string" $
                validateNonEmpty "name" "test" `shouldBe` Right "test"
            
            it "rejects empty string" $
                validateNonEmpty "name" "" `shouldBe` Left (EmptyValue "name")

        describe "validateMinLength" $ do
            it "accepts string with sufficient length" $
                validateMinLength "name" 3 "hello" `shouldBe` Right "hello"
            
            it "rejects string that is too short" $
                validateMinLength "name" 5 "hi" `shouldBe` Left (TooShort "name" 2 5)

        describe "validateMaxLength" $ do
            it "accepts string within limit" $
                validateMaxLength "name" 10 "hello" `shouldBe` Right "hello"
            
            it "rejects string that is too long" $
                validateMaxLength "name" 3 "hello" `shouldBe` Left (TooLong "name" 5 3)

        describe "validateRange" $ do
            it "accepts value within range" $
                validateRange "age" 0 150 25 `shouldBe` Right 25
            
            it "rejects value below minimum" $
                validateRange "age" 0 150 (-1) `shouldBe` Left (OutOfRange "age" (-1) 0 150)
            
            it "rejects value above maximum" $
                validateRange "age" 0 150 200 `shouldBe` Left (OutOfRange "age" 200 0 150)

        describe "validateEmail" $ do
            it "accepts valid email" $
                validateEmail "test@example.com" `shouldBe` Right "test@example.com"
            
            it "rejects invalid email" $
                validateEmail "invalid" `shouldBe` Left (InvalidFormat "email" "invalid")

        describe "validatePostalCode" $ do
            it "accepts valid postal code" $
                validatePostalCode "150-0001" `shouldBe` Right "150-0001"
            
            it "rejects invalid postal code" $
                validatePostalCode "12345" `shouldBe` Left (InvalidFormat "postal code" "12345")

    describe "Domain Primitives" $ do
        describe "Name" $ do
            it "creates valid name" $
                mkName "田中太郎" `shouldBe` Right (Name "田中太郎")
            
            it "rejects empty name" $
                mkName "" `shouldBe` Left (EmptyValue "name")

        describe "Age" $ do
            it "creates valid age" $
                mkAge 25 `shouldBe` Right (Age 25)
            
            it "rejects negative age" $
                mkAge (-1) `shouldBe` Left (OutOfRange "age" (-1) 0 150)

        describe "Email" $ do
            it "creates valid email" $
                mkEmail "test@example.com" `shouldBe` Right (Email "test@example.com")

        describe "PostalCode" $ do
            it "creates valid postal code" $
                mkPostalCode "150-0001" `shouldBe` Right (PostalCode "150-0001")

        describe "ProductId" $ do
            it "creates valid product ID" $
                mkProductId "PROD-12345" `shouldBe` Right (ProductId "PROD-12345")
            
            it "rejects invalid product ID" $
                mkProductId "INVALID" `shouldBe` Left (InvalidFormat "product ID" "INVALID")

    describe "Membership" $ do
        it "parses bronze" $
            parseMembership "bronze" `shouldBe` Right Bronze
        
        it "parses GOLD (case insensitive)" $
            parseMembership "GOLD" `shouldBe` Right Gold
        
        it "rejects invalid membership" $
            parseMembership "diamond" `shouldSatisfy` isLeft
        
        it "converts to string" $ do
            membershipToString Bronze `shouldBe` "bronze"
            membershipToString Platinum `shouldBe` "platinum"

    describe "Status" $ do
        it "parses active" $
            parseStatus "active" `shouldBe` Right Active
        
        it "parses INACTIVE (case insensitive)" $
            parseStatus "INACTIVE" `shouldBe` Right Inactive

    describe "Person Validation" $ do
        it "validates valid person" $ do
            let input = PersonInput "田中" 30 Nothing Nothing
            validatePerson input `shouldSatisfy` isRight
        
        it "validates person with optional fields" $ do
            let input = PersonInput "田中" 30 (Just "tanaka@example.com") (Just "gold")
            let result = validatePerson input
            result `shouldSatisfy` isRight
        
        it "fails on invalid age" $ do
            let input = PersonInput "田中" (-5) Nothing Nothing
            validatePerson input `shouldSatisfy` isLeft

    describe "Address Validation" $ do
        it "validates valid address" $ do
            let input = AddressInput "東京都渋谷区1-1-1" "渋谷区" "150-0001"
            validateAddress input `shouldSatisfy` isRight
        
        it "fails on empty street" $ do
            let input = AddressInput "" "渋谷区" "150-0001"
            validateAddress input `shouldSatisfy` isLeft

    describe "Product Validation" $ do
        it "validates valid product" $ do
            let input = ProductInput "PROD-12345" "テスト商品" 1000
            validateProduct input `shouldSatisfy` isRight
        
        it "fails on invalid product ID" $ do
            let input = ProductInput "INVALID" "テスト商品" 1000
            validateProduct input `shouldSatisfy` isLeft
        
        it "fails on zero price" $ do
            let input = ProductInput "PROD-12345" "テスト商品" 0
            validateProduct input `shouldSatisfy` isLeft

    describe "Order Validation" $ do
        it "validates valid order" $ do
            let product = ProductInput "PROD-12345" "商品A" 1000
            let item = OrderItemInput product 2
            let customer = PersonInput "田中" 30 Nothing Nothing
            let order = OrderInput [item] customer
            validateOrder order `shouldSatisfy` isRight
        
        it "fails on empty items" $ do
            let customer = PersonInput "田中" 30 Nothing Nothing
            let order = OrderInput [] customer
            validateOrder order `shouldSatisfy` isLeft

    describe "Validated (Error Accumulation)" $ do
        it "Valid is a Functor" $ do
            let v = Valid 5 :: Validated Int
            fmap (*2) v `shouldBe` Valid 10
        
        it "Invalid preserves errors" $ do
            let v = Invalid [EmptyValue "a", EmptyValue "b"] :: Validated Int
            fmap (*2) v `shouldBe` Invalid [EmptyValue "a", EmptyValue "b"]
        
        it "Applicative accumulates errors" $ do
            let v1 = Invalid [EmptyValue "a"] :: Validated (Int -> Int)
            let v2 = Invalid [EmptyValue "b"] :: Validated Int
            (v1 <*> v2) `shouldBe` Invalid [EmptyValue "a", EmptyValue "b"]
        
        it "fromResult converts Right to Valid" $
            fromResult (Right 5 :: Either ValidationError Int) `shouldBe` Valid 5
        
        it "fromResult converts Left to Invalid" $
            fromResult (Left (EmptyValue "x") :: Either ValidationError Int) 
                `shouldBe` Invalid [EmptyValue "x"]
        
        it "validateAllV collects all valid values" $ do
            let vs = [Valid 1, Valid 2, Valid 3] :: [Validated Int]
            validateAllV vs `shouldBe` Valid [1, 2, 3]
        
        it "validateAllV collects all errors" $ do
            let vs = [Invalid [EmptyValue "a"], Valid 2, Invalid [EmptyValue "b"]]
            validateAllV vs `shouldBe` Invalid [EmptyValue "a", EmptyValue "b"]

    describe "QuickCheck Properties" $ do
        it "Valid age is always in range 0-150" $ property $
            \(NonNegative n) -> 
                let age = n `mod` 151
                in mkAge age == Right (Age age)

-- Helper
isLeft :: Either a b -> Bool
isLeft (Left _) = True
isLeft _ = False

isRight :: Either a b -> Bool
isRight (Right _) = True
isRight _ = False
