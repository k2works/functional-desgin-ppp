module BestPracticesSpec (spec) where

import Test.Hspec
import Test.QuickCheck
import BestPractices hiding (Success, Failure)
import qualified BestPractices as BP

spec :: Spec
spec = do
  describe "Immutability Practices" $ do
    let user = User "Alice" "alice@example.com" 30

    describe "updateUserName" $ do
      it "creates new user with updated name" $ do
        let user' = updateUserName "Bob" user
        userName user' `shouldBe` "Bob"
        userName user `shouldBe` "Alice"  -- Original unchanged

    describe "updateUserEmail" $ do
      it "creates new user with updated email" $ do
        let user' = updateUserEmail "bob@example.com" user
        userEmail user' `shouldBe` "bob@example.com"

    describe "updateUserAge" $ do
      it "creates new user with updated age" $ do
        let user' = updateUserAge 31 user
        userAge user' `shouldBe` 31

    describe "updateUser" $ do
      it "applies update function" $ do
        let user' = updateUser (updateUserName "Charlie") user
        userName user' `shouldBe` "Charlie"

  describe "Function Composition" $ do
    describe "pipeline" $ do
      it "composes functions in order" $ do
        let p = pipeline [(+1), (*2), (+3)]
        p 5 `shouldBe` 15  -- ((5+1)*2)+3 = 15

    describe "(|>)" $ do
      it "pipes value through function" $ do
        (5 |> (+1)) `shouldBe` 6
        (5 |> (+1) |> (*2)) `shouldBe` 12

    describe "(<|)" $ do
      it "applies function to value" $ do
        ((+1) <| 5) `shouldBe` 6

    describe "trim" $ do
      it "removes leading and trailing whitespace" $ do
        trim "  hello  " `shouldBe` "hello"
        trim "hello" `shouldBe` "hello"
        trim "  " `shouldBe` ""

    describe "toLowerCase" $ do
      it "converts to lowercase" $ do
        toLowerCase "HELLO" `shouldBe` "hello"
        toLowerCase "Hello World" `shouldBe` "hello world"

    describe "removeSpaces" $ do
      it "removes all spaces" $ do
        removeSpaces "hello world" `shouldBe` "helloworld"

    describe "sanitizeInput" $ do
      it "trims and lowercases" $ do
        sanitizeInput "  HELLO  " `shouldBe` "hello"

  describe "Pure Functions" $ do
    describe "pureAdd" $ do
      it "adds two numbers" $ do
        pureAdd 3 5 `shouldBe` 8

      it "is commutative" $ property $
        \(x :: Int) y -> pureAdd x y == pureAdd y x

    describe "pureMultiply" $ do
      it "multiplies two numbers" $ do
        pureMultiply 3 5 `shouldBe` 15

    describe "pureCompute" $ do
      it "computes (x + y) * z" $ do
        pureCompute 2 3 4 `shouldBe` 20

  describe "Error Handling" $ do
    describe "Result" $ do
      it "maps over success" $ do
        mapResult (+1) (BP.Success 5 :: BP.Result String Int) `shouldBe` BP.Success 6

      it "preserves failure on map" $ do
        mapResult (+1) (BP.Failure "error" :: BP.Result String Int) `shouldBe` BP.Failure "error"

      it "flat maps success" $ do
        let f x = if x > 0 then BP.Success (x * 2) else BP.Failure "negative"
        flatMapResult f (BP.Success 5) `shouldBe` BP.Success 10
        flatMapResult f (BP.Success (-1)) `shouldBe` BP.Failure "negative"

    describe "fromMaybe'" $ do
      it "converts Just to Success" $ do
        fromMaybe' "error" (Just 5) `shouldBe` BP.Success 5

      it "converts Nothing to Failure" $ do
        fromMaybe' "error" (Nothing :: Maybe Int) `shouldBe` BP.Failure "error"

    describe "Validation" $ do
      it "validates with single rule" $ do
        validate (> 0) "must be positive" 5 `shouldBe` Valid 5
        validate (> 0) "must be positive" (-1) `shouldBe` Invalid ["must be positive"]

      it "validates with multiple rules" $ do
        let rules = [((> 0), "must be positive"), ((< 100), "must be less than 100")]
        validateAll rules 50 `shouldBe` Valid 50
        validateAll rules 150 `shouldBe` Invalid ["must be less than 100"]
        validateAll rules (-5) `shouldBe` Invalid ["must be positive"]

      it "combines validations" $ do
        let v1 = Valid 1 :: Validation String Int
            v2 = Valid 2 :: Validation String Int
            v3 = Invalid ["error"] :: Validation String Int
        combineValidations [v1, v2] `shouldBe` Valid [1, 2]
        combineValidations [v1, v3] `shouldBe` Invalid ["error"]

  describe "Data Transformation" $ do
    describe "mapOver" $ do
      it "maps function over list" $ do
        mapOver (+1) [1, 2, 3] `shouldBe` [2, 3, 4]

    describe "filterBy" $ do
      it "filters list by predicate" $ do
        filterBy (> 2) [1, 2, 3, 4] `shouldBe` [3, 4]

    describe "reduceWith" $ do
      it "reduces list with accumulator" $ do
        reduceWith (+) 0 [1, 2, 3] `shouldBe` 6

    describe "transformPipeline" $ do
      it "combines map, filter, reduce" $ do
        let result = transformPipeline (*2) (> 5) (+) 0 [1, 2, 3, 4, 5]
        result `shouldBe` 24  -- 6 + 8 + 10 = 24

  describe "Lazy Evaluation" $ do
    describe "lazyRange" $ do
      it "creates lazy range" $ do
        lazyRange 1 5 `shouldBe` [1, 2, 3, 4, 5]

    describe "takeWhile'" $ do
      it "takes while predicate holds" $ do
        takeWhile' (< 5) [1..10] `shouldBe` [1, 2, 3, 4]

    describe "infiniteSequence" $ do
      it "generates infinite sequence" $ do
        take 5 (infiniteSequence 1 (+1)) `shouldBe` [1, 2, 3, 4, 5]
        take 5 (infiniteSequence 2 (*2)) `shouldBe` [2, 4, 8, 16, 32]

  describe "Type Safety" $ do
    describe "Email" $ do
      it "creates valid email" $ do
        mkEmail "test@example.com" `shouldBe` Just (Email "test@example.com")

      it "rejects invalid email" $ do
        mkEmail "invalid" `shouldBe` Nothing
        mkEmail "no-at-sign.com" `shouldBe` Nothing

    describe "Username" $ do
      it "creates valid username" $ do
        mkUsername "alice" `shouldBe` Just (Username "alice")

      it "rejects too short username" $ do
        mkUsername "ab" `shouldBe` Nothing

      it "rejects too long username" $ do
        mkUsername (replicate 25 'a') `shouldBe` Nothing

    describe "Age" $ do
      it "creates valid age" $ do
        mkAge 25 `shouldBe` Just (Age 25)

      it "rejects negative age" $ do
        mkAge (-1) `shouldBe` Nothing

      it "rejects unreasonable age" $ do
        mkAge 200 `shouldBe` Nothing

    describe "PositiveInt" $ do
      it "creates positive int" $ do
        mkPositiveInt 5 `shouldBe` Just (PositiveInt 5)

      it "rejects zero" $ do
        mkPositiveInt 0 `shouldBe` Nothing

      it "rejects negative" $ do
        mkPositiveInt (-1) `shouldBe` Nothing

    describe "NonEmptyString" $ do
      it "creates non-empty string" $ do
        mkNonEmptyString "hello" `shouldBe` Just (NonEmptyString "hello")

      it "rejects empty string" $ do
        mkNonEmptyString "" `shouldBe` Nothing

  describe "Testing Best Practices" $ do
    describe "associative" $ do
      it "tests associativity" $ do
        associative (+) 1 2 3 `shouldBe` True
        associative (-) 1 2 3 `shouldBe` False

    describe "commutative" $ do
      it "tests commutativity" $ do
        commutative (+) 3 5 `shouldBe` True
        commutative (-) 3 5 `shouldBe` False

    describe "identity'" $ do
      it "tests identity element" $ do
        identity' (+) 0 5 `shouldBe` True
        identity' (*) 1 5 `shouldBe` True

    describe "inverse" $ do
      it "tests inverse property" $ do
        inverse (+) negate 0 5 `shouldBe` True

  describe "Property-Based Tests" $ do
    it "addition is associative" $ property $
      \(x :: Int) y z -> associative (+) x y z

    it "addition is commutative" $ property $
      \(x :: Int) y -> commutative (+) x y

    it "0 is identity for addition" $ property $
      \(x :: Int) -> identity' (+) 0 x
