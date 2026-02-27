module DecoratorPatternSpec (spec) where

import Test.Hspec
import Test.QuickCheck
import qualified Data.Map.Strict as Map

import CompositePattern (Shape(..), Point(..), translateShape, scaleShape)
import DecoratorPattern

spec :: Spec
spec = do
  journaledShapeSpec
  functionDecoratorsSpec
  composingDecoratorsSpec
  countedOperationsSpec

-- ============================================================
-- Journaled Shape Tests
-- ============================================================

journaledShapeSpec :: Spec
journaledShapeSpec = describe "JournaledShape" $ do
  describe "journalShape" $ do
    it "should wrap a shape with empty journal" $ do
      let circle = Circle (Point 0 0) 5
          journaled = journalShape circle
      getJournal journaled `shouldBe` []
      getShape journaled `shouldBe` circle

  describe "translateJournaled" $ do
    it "should translate shape and record in journal" $ do
      let circle = Circle (Point 0 0) 5
          journaled = journalShape circle
          translated = translateJournaled 3 4 journaled
      getJournal translated `shouldBe` [TranslateEntry 3 4]
      getShape translated `shouldBe` Circle (Point 3 4) 5

    it "should accumulate multiple translations" $ do
      let circle = Circle (Point 0 0) 5
          journaled = journalShape circle
          step1 = translateJournaled 3 4 journaled
          step2 = translateJournaled 1 1 step1
      getJournal step2 `shouldBe` [TranslateEntry 3 4, TranslateEntry 1 1]
      getShape step2 `shouldBe` Circle (Point 4 5) 5

  describe "scaleJournaled" $ do
    it "should scale shape and record in journal" $ do
      let square = Square (Point 0 0) 10
          journaled = journalShape square
          scaled = scaleJournaled 2 journaled
      getJournal scaled `shouldBe` [ScaleEntry 2]
      getShape scaled `shouldBe` Square (Point 0 0) 20

    it "should accumulate multiple scales" $ do
      let square = Square (Point 0 0) 10
          journaled = journalShape square
          step1 = scaleJournaled 2 journaled
          step2 = scaleJournaled 3 step1
      getJournal step2 `shouldBe` [ScaleEntry 2, ScaleEntry 3]
      getShape step2 `shouldBe` Square (Point 0 0) 60

  describe "mixed operations" $ do
    it "should record translate and scale in order" $ do
      let circle = Circle (Point 0 0) 5
          result = scaleJournaled 2 
                 $ translateJournaled 3 4 
                 $ journalShape circle
      getJournal result `shouldBe` [TranslateEntry 3 4, ScaleEntry 2]
      getShape result `shouldBe` Circle (Point 3 4) 10

    it "should work with composite shapes" $ do
      let circle = Circle (Point 0 0) 5
          square = Square (Point 10 10) 10
          composite = CompositeShape [circle, square]
          journaled = journalShape composite
          result = translateJournaled 1 1 journaled
      getJournal result `shouldBe` [TranslateEntry 1 1]
      case getShape result of
        CompositeShape [Circle p1 _, Square p2 _] -> do
          p1 `shouldBe` Point 1 1
          p2 `shouldBe` Point 11 11
        _ -> expectationFailure "Unexpected shape structure"

-- ============================================================
-- Function Decorators Tests
-- ============================================================

functionDecoratorsSpec :: Spec
functionDecoratorsSpec = describe "Function Decorators" $ do
  describe "withLogging" $ do
    it "should return result and log entries" $ do
      let f = (* 2) :: Int -> Int
          decorated = withLogging "double" f
          (result, logs) = decorated 5
      result `shouldBe` 10
      length logs `shouldBe` 2
      head logs `shouldContain` "[LOG]"
      head logs `shouldContain` "double"

  describe "withRetry" $ do
    it "should return success on first try" $ do
      let f _ = Right "success" :: Either String String
          decorated = withRetry 3 f
      decorated () `shouldBe` Right "success"

    it "should return error after max retries" $ do
      let f _ = Left "error" :: Either String String
          decorated = withRetry 3 f
      decorated () `shouldBe` Left "Max retries exceeded"

  describe "withCache" $ do
    it "should compute result on cache miss" $ do
      let f = (* 2) :: Int -> Int
          decorated = withCache f
          (result, cache) = decorated Map.empty 5
      result `shouldBe` 10
      Map.lookup 5 cache `shouldBe` Just 10

    it "should return cached result on cache hit" $ do
      let f = (* 2) :: Int -> Int
          decorated = withCache f
          initialCache = Map.singleton 5 20  -- wrong value to prove cache hit
          (result, cache) = decorated initialCache 5
      result `shouldBe` 20  -- returns cached value
      cache `shouldBe` initialCache

    it "should accumulate cache entries" $ do
      let f = (* 2) :: Int -> Int
          decorated = withCache f
          (_, cache1) = decorated Map.empty 5
          (_, cache2) = decorated cache1 10
      Map.size cache2 `shouldBe` 2

  describe "withValidation" $ do
    it "should call function when validation passes" $ do
      let f x = Right (x * 2) :: Either String Int
          validator x = x > 0
          decorated = withValidation validator "Must be positive" f
      decorated 5 `shouldBe` Right 10

    it "should return error when validation fails" $ do
      let f x = Right (x * 2) :: Either String Int
          validator x = x > 0
          decorated = withValidation validator "Must be positive" f
      decorated (-5) `shouldBe` Left "Must be positive"

-- ============================================================
-- Composing Decorators Tests
-- ============================================================

composingDecoratorsSpec :: Spec
composingDecoratorsSpec = describe "Composing Decorators" $ do
  describe "composeDecorators" $ do
    it "should apply multiple transformations" $ do
      let add1 = (+ 1) :: Int -> Int
          mul2 = (* 2)
          decorators = [add1, mul2]  -- (x * 2) + 1
          composed = composeDecorators decorators
      composed 5 `shouldBe` 11  -- (5 * 2) + 1

    it "should return identity for empty list" $ do
      let composed = composeDecorators [] :: Int -> Int
      composed 5 `shouldBe` 5

  describe "timedExecution" $ do
    it "should return result and success flag" $ do
      let f = (* 2) :: Int -> Int
          (result, completed) = timedExecution f 5
      result `shouldBe` 10
      completed `shouldBe` True

-- ============================================================
-- Counted Operations Tests
-- ============================================================

countedOperationsSpec :: Spec
countedOperationsSpec = describe "Counted Operations" $ do
  describe "withCounter" $ do
    it "should count calls" $ do
      let f = (* 2) :: Int -> Int
          decorated = withCounter f
          results = decorated [1, 2, 3]
      map crResult results `shouldBe` [2, 4, 6]
      map crCount results `shouldBe` [1, 2, 3]

    it "should handle empty list" $ do
      let f = (* 2) :: Int -> Int
          decorated = withCounter f
          results = decorated []
      results `shouldBe` []
