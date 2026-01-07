module PatternInteractionsSpec (spec) where

import Test.Hspec
import PatternInteractions

spec :: Spec
spec = do
  describe "Product" $ do
    it "creates product with properties" $ do
      let product = makeProduct "P001" "Widget" 29.99 "Electronics"
      productId product `shouldBe` "P001"
      productName product `shouldBe` "Widget"
      productBasePrice product `shouldBe` 29.99
      productCategory product `shouldBe` "Electronics"

  describe "PricingStrategy" $ do
    describe "regularPricing" $ do
      it "calculates regular price" $ do
        let product = makeProduct "P001" "Widget" 10.0 "Electronics"
        applyPricing regularPricing product 3 `shouldBe` 30.0

    describe "discountPricing" $ do
      it "applies percentage discount" $ do
        let product = makeProduct "P001" "Widget" 100.0 "Electronics"
            strategy = discountPricing 20
        applyPricing strategy product 1 `shouldBe` 80.0

    describe "bulkPricing" $ do
      it "applies discount when quantity meets threshold" $ do
        let product = makeProduct "P001" "Widget" 10.0 "Electronics"
            strategy = bulkPricing 5 10
        applyPricing strategy product 5 `shouldBe` 45.0  -- 50 * 0.9

      it "uses regular price below threshold" $ do
        let product = makeProduct "P001" "Widget" 10.0 "Electronics"
            strategy = bulkPricing 5 10
        applyPricing strategy product 4 `shouldBe` 40.0

  describe "DiscountDecorators" $ do
    describe "percentageDiscount" $ do
      it "applies percentage off" $ do
        percentageDiscount 10 100.0 `shouldBe` 90.0

    describe "fixedDiscount" $ do
      it "applies fixed amount off" $ do
        fixedDiscount 15 100.0 `shouldBe` 85.0

      it "doesn't go below zero" $ do
        fixedDiscount 150 100.0 `shouldBe` 0.0

    describe "seasonalDiscount" $ do
      it "applies multiplier" $ do
        seasonalDiscount 0.8 100.0 `shouldBe` 80.0

    describe "applyDiscounts" $ do
      it "chains multiple discounts" $ do
        let discounts = [percentageDiscount 10, fixedDiscount 5]
        applyDiscounts discounts 100.0 `shouldBe` 85.0  -- 90 - 5

  describe "OrderCommands" $ do
    let product1 = makeProduct "P001" "Widget" 10.0 "Electronics"
    let product2 = makeProduct "P002" "Gadget" 20.0 "Electronics"

    describe "AddItem" $ do
      it "adds item to cart" $ do
        let cmd = AddItem product1 2
            cart = executeCommand cmd emptyCart
        length (cartItems cart) `shouldBe` 1

    describe "RemoveItem" $ do
      it "removes item from cart" $ do
        let cart1 = executeCommand (AddItem product1 1) emptyCart
            cart2 = executeCommand (AddItem product2 1) cart1
            cart3 = executeCommand (RemoveItem "P001") cart2
        length (cartItems cart3) `shouldBe` 1

    describe "ApplyDiscount" $ do
      it "applies discount to cart" $ do
        let cart1 = executeCommand (AddItem product1 1) emptyCart
            cart2 = executeCommand (ApplyDiscount (percentageDiscount 10)) cart1
        cartTotal cart2 `shouldBe` 9.0

  describe "ShoppingCart" $ do
    let product = makeProduct "P001" "Widget" 25.0 "Electronics"

    it "starts empty" $ do
      cartItems emptyCart `shouldBe` []
      cartTotal emptyCart `shouldBe` 0.0

    it "calculates total" $ do
      let cart = executeCommand (AddItem product 2) emptyCart
      cartTotal cart `shouldBe` 50.0

    it "applies discount to total" $ do
      let cart1 = executeCommand (AddItem product 2) emptyCart
          cart2 = executeCommand (ApplyDiscount (fixedDiscount 10)) cart1
      cartTotal cart2 `shouldBe` 40.0

  describe "OrderPipeline" $ do
    let product = makeProduct "P001" "Widget" 100.0 "Electronics"

    describe "validationStep" $ do
      it "fails on empty cart" $ do
        case validationStep emptyCart of
          OrderFailure msg -> msg `shouldBe` "Cart is empty"
          OrderSuccess _ -> expectationFailure "Should have failed"

      it "succeeds on non-empty cart" $ do
        let cart = executeCommand (AddItem product 1) emptyCart
        case validationStep cart of
          OrderSuccess _ -> return ()
          OrderFailure _ -> expectationFailure "Should have succeeded"

    describe "runPipeline" $ do
      it "runs through all steps" $ do
        let cart = executeCommand (AddItem product 1) emptyCart
            pipeline' = [validationStep, discountStep 10]
        case runPipeline pipeline' cart of
          OrderSuccess cart' -> cartTotal cart' `shouldBe` 90.0
          OrderFailure _ -> expectationFailure "Should have succeeded"

      it "stops on first failure" $ do
        let pipeline' = [validationStep]
        case runPipeline pipeline' emptyCart of
          OrderFailure msg -> msg `shouldBe` "Cart is empty"
          OrderSuccess _ -> expectationFailure "Should have failed"

  describe "CartVisitors" $ do
    let product1 = makeProduct "P001" "Widget" 10.0 "Electronics"
    let product2 = makeProduct "P002" "Gadget" 20.0 "Electronics"
    let cart = executeCommand (AddItem product2 1) 
             $ executeCommand (AddItem product1 2) emptyCart

    describe "itemCountVisitor" $ do
      it "counts total items" $ do
        visitCart itemCountVisitor cart `shouldBe` 3  -- 2 + 1

    describe "totalValueVisitor" $ do
      it "calculates total value" $ do
        visitCart totalValueVisitor cart `shouldBe` 40.0  -- 20 + 20

    describe "averageItemPriceVisitor" $ do
      it "calculates average unit price" $ do
        visitCart averageItemPriceVisitor cart `shouldBe` 15.0  -- (10 + 20) / 2

      it "returns 0 for empty cart" $ do
        visitCart averageItemPriceVisitor emptyCart `shouldBe` 0.0

  describe "Integration: Full Order Flow" $ do
    it "processes complete order with multiple patterns" $ do
      let product1 = makeProduct "P001" "Laptop" 1000.0 "Electronics"
          product2 = makeProduct "P002" "Mouse" 50.0 "Electronics"
          
          -- Build cart using commands
          cart1 = executeCommand (AddItem product1 1) emptyCart
          cart2 = executeCommand (AddItem product2 2) cart1
          cart3 = executeCommand (ApplyDiscount (percentageDiscount 5)) cart2
          
          -- Run through pipeline
          pipeline' = [validationStep]
      
      case runPipeline pipeline' cart3 of
        OrderSuccess cart' -> do
          -- Verify items
          visitCart itemCountVisitor cart' `shouldBe` 3
          -- Total: (1000 + 100) * 0.95 = 1045
          cartTotal cart' `shouldBe` 1045.0
        OrderFailure _ -> expectationFailure "Order should succeed"
