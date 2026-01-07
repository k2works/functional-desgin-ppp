module StrategyPatternSpec (spec) where

import Test.Hspec
import Test.QuickCheck

import StrategyPattern

spec :: Spec
spec = do
  pricingStrategiesSpec
  shippingStrategiesSpec
  shoppingCartSpec
  strategyCompositionSpec
  sortingStrategiesSpec

-- ============================================================
-- Pricing Strategies Tests
-- ============================================================

pricingStrategiesSpec :: Spec
pricingStrategiesSpec = describe "Pricing Strategies" $ do
  describe "regularPricing" $ do
    it "should return the same amount" $ do
      calculatePrice regularPricing 1000 `shouldBe` 1000

    it "should work with any amount" $ property $
      \amount -> calculatePrice regularPricing amount == amount

  describe "discountPricing" $ do
    it "should apply 10% discount" $ do
      calculatePrice (discountPricing 0.10) 1000 `shouldBe` 900

    it "should apply 20% discount" $ do
      calculatePrice (discountPricing 0.20) 1000 `shouldBe` 800

    it "should apply 0% discount (no change)" $ do
      calculatePrice (discountPricing 0.0) 1000 `shouldBe` 1000

  describe "memberPricing" $ do
    it "should apply Bronze discount (10%)" $ do
      calculatePrice (memberPricing Bronze) 1000 `shouldBe` 900

    it "should apply Silver discount (15%)" $ do
      calculatePrice (memberPricing Silver) 1000 `shouldBe` 850

    it "should apply Gold discount (20%)" $ do
      calculatePrice (memberPricing Gold) 1000 `shouldBe` 800

  describe "bulkPricing" $ do
    it "should apply discount when over threshold" $ do
      calculatePrice (bulkPricing 5000 0.15) 6000 `shouldBe` 5100

    it "should not apply discount when under threshold" $ do
      calculatePrice (bulkPricing 5000 0.15) 3000 `shouldBe` 3000

    it "should apply discount at exactly threshold" $ do
      calculatePrice (bulkPricing 5000 0.15) 5000 `shouldBe` 4250

-- ============================================================
-- Shipping Strategies Tests
-- ============================================================

shippingStrategiesSpec :: Spec
shippingStrategiesSpec = describe "Shipping Strategies" $ do
  describe "standardShipping" $ do
    it "should calculate correctly" $ do
      -- weight * 10 + distance * 5
      calculateShipping standardShipping 2 100 `shouldBe` 520

  describe "expressShipping" $ do
    it "should calculate correctly" $ do
      -- weight * 20 + distance * 15
      calculateShipping expressShipping 2 100 `shouldBe` 1540

  describe "freeShipping" $ do
    it "should always return 0" $ do
      calculateShipping freeShipping 10 1000 `shouldBe` 0

    it "should return 0 for any weight and distance" $ property $
      \w d -> calculateShipping freeShipping w d == 0

-- ============================================================
-- Shopping Cart Tests
-- ============================================================

shoppingCartSpec :: Spec
shoppingCartSpec = describe "ShoppingCart" $ do
  describe "makeCart" $ do
    it "should create empty cart" $ do
      let cart = makeCart regularPricing
      cartItems cart `shouldBe` []

  describe "addItem" $ do
    it "should add item to cart" $ do
      let cart = makeCart regularPricing
          item = CartItem "Product A" 500
          updated = addItem item cart
      length (cartItems updated) `shouldBe` 1

    it "should add multiple items" $ do
      let cart = makeCart regularPricing
          item1 = CartItem "Product A" 500
          item2 = CartItem "Product B" 300
          updated = addItem item2 $ addItem item1 cart
      length (cartItems updated) `shouldBe` 2

  describe "cartSubtotal" $ do
    it "should calculate subtotal" $ do
      let cart = addItem (CartItem "B" 300) 
               $ addItem (CartItem "A" 500) 
               $ makeCart regularPricing
      cartSubtotal cart `shouldBe` 800

  describe "cartTotal" $ do
    it "should apply pricing strategy" $ do
      let cart = addItem (CartItem "B" 500) 
               $ addItem (CartItem "A" 500) 
               $ makeCart (discountPricing 0.10)
      cartTotal cart `shouldBe` 900

  describe "changeStrategy" $ do
    it "should change pricing strategy" $ do
      let cart = addItem (CartItem "A" 1000) $ makeCart regularPricing
      cartTotal cart `shouldBe` 1000
      
      let discountedCart = changeStrategy (memberPricing Gold) cart
      cartTotal discountedCart `shouldBe` 800

-- ============================================================
-- Strategy Composition Tests
-- ============================================================

strategyCompositionSpec :: Spec
strategyCompositionSpec = describe "Strategy Composition" $ do
  describe "composeStrategies" $ do
    it "should compose multiple strategies" $ do
      let discount = discountPricing 0.10
          tax = taxStrategy 0.08
          composed = composeStrategies [discount, tax]
      -- 1000 * 0.9 * 1.08 = 972.0 (with floating point tolerance)
      calculatePrice composed 1000 `shouldSatisfy` (\x -> abs (x - 972) < 0.0001)

    it "should return identity for empty list" $ do
      let composed = composeStrategies []
      calculatePrice composed 1000 `shouldBe` 1000

  describe "conditionalStrategy" $ do
    it "should apply then strategy when condition is true" $ do
      let strategy = conditionalStrategy (>= 5000) (discountPricing 0.20) regularPricing
      calculatePrice strategy 6000 `shouldBe` 4800

    it "should apply else strategy when condition is false" $ do
      let strategy = conditionalStrategy (>= 5000) (discountPricing 0.20) regularPricing
      calculatePrice strategy 3000 `shouldBe` 3000

  describe "taxStrategy" $ do
    it "should add tax" $ do
      calculatePrice (taxStrategy 0.08) 1000 `shouldBe` 1080

-- ============================================================
-- Sorting Strategies Tests
-- ============================================================

sortingStrategiesSpec :: Spec
sortingStrategiesSpec = describe "Sorting Strategies" $ do
  describe "bubbleSort" $ do
    it "should sort a list" $ do
      sortWith bubbleSort [3, 1, 4, 1, 5, 9, 2, 6] `shouldBe` [1, 1, 2, 3, 4, 5, 6, 9]

    it "should handle empty list" $ do
      sortWith bubbleSort ([] :: [Int]) `shouldBe` []

    it "should handle single element" $ do
      sortWith bubbleSort [1] `shouldBe` [1]

  describe "quickSort" $ do
    it "should sort a list" $ do
      sortWith quickSort [3, 1, 4, 1, 5, 9, 2, 6] `shouldBe` [1, 1, 2, 3, 4, 5, 6, 9]

    it "should handle already sorted list" $ do
      sortWith quickSort [1, 2, 3, 4, 5] `shouldBe` [1, 2, 3, 4, 5]

    it "should handle reverse sorted list" $ do
      sortWith quickSort [5, 4, 3, 2, 1] `shouldBe` [1, 2, 3, 4, 5]

  describe "mergeSort" $ do
    it "should sort a list" $ do
      sortWith mergeSort [3, 1, 4, 1, 5, 9, 2, 6] `shouldBe` [1, 1, 2, 3, 4, 5, 6, 9]

    it "should handle duplicates" $ do
      sortWith mergeSort [3, 3, 3, 1, 1, 2, 2] `shouldBe` [1, 1, 2, 2, 3, 3, 3]

  describe "all sorting strategies" $ do
    it "should produce the same result" $ property $
      \xs -> let xs' = xs :: [Int]
             in sortWith bubbleSort xs' == sortWith quickSort xs' &&
                sortWith quickSort xs' == sortWith mergeSort xs'
