-- |
-- Module      : PatternInteractions
-- Description : Pattern Interactions - Combining Multiple Patterns
-- 
-- This module demonstrates how multiple functional design patterns
-- can be combined to solve complex problems.

{-# LANGUAGE TypeFamilies #-}

module PatternInteractions
  ( -- * E-Commerce Example: Combined Patterns
    -- ** Product Types
    Product(..)
  , makeProduct
  
  -- ** Pricing Strategy (Strategy Pattern)
  , PricingStrategy(..)
  , regularPricing
  , discountPricing
  , bulkPricing
  
  -- ** Discount Decorators (Decorator Pattern)
  , DiscountDecorator
  , percentageDiscount
  , fixedDiscount
  , seasonalDiscount
  , applyDiscounts
  
  -- ** Order Commands (Command Pattern)
  , OrderCommand(..)
  , AddItem(..)
  , RemoveItem(..)
  , ApplyDiscount(..)
  , executeCommand
  
  -- ** Shopping Cart (Composite Pattern)
  , CartItem(..)
  , ShoppingCart(..)
  , emptyCart
  , cartTotal
  , cartItems
  
  -- ** Order Processing Pipeline
  , OrderResult(..)
  , OrderPipeline
  , processingStep
  , validationStep
  , pricingStep
  , discountStep
  , runPipeline
  
  -- ** Visitor for Cart Analysis
  , CartVisitor(..)
  , itemCountVisitor
  , totalValueVisitor
  , averageItemPriceVisitor
  , visitCart
  ) where

-- ============================================================
-- Product Types
-- ============================================================

-- | Product in the catalog
data Product = Product
  { productId :: String
  , productName :: String
  , productBasePrice :: Double
  , productCategory :: String
  } deriving (Show, Eq)

-- | Create a product
makeProduct :: String -> String -> Double -> String -> Product
makeProduct = Product

-- ============================================================
-- Pricing Strategy (Strategy Pattern)
-- ============================================================

-- | Pricing strategy function
newtype PricingStrategy = PricingStrategy
  { applyPricing :: Product -> Int -> Double
  }

-- | Regular pricing
regularPricing :: PricingStrategy
regularPricing = PricingStrategy $ \product qty ->
  productBasePrice product * fromIntegral qty

-- | Discount pricing (percentage off)
discountPricing :: Double -> PricingStrategy
discountPricing percent = PricingStrategy $ \product qty ->
  productBasePrice product * fromIntegral qty * (1 - percent / 100)

-- | Bulk pricing (discount for quantity)
bulkPricing :: Int -> Double -> PricingStrategy
bulkPricing threshold percent = PricingStrategy $ \product qty ->
  let basePrice = productBasePrice product * fromIntegral qty
  in if qty >= threshold
     then basePrice * (1 - percent / 100)
     else basePrice

-- ============================================================
-- Discount Decorators (Decorator Pattern)
-- ============================================================

-- | Discount decorator function
type DiscountDecorator = Double -> Double

-- | Percentage discount
percentageDiscount :: Double -> DiscountDecorator
percentageDiscount percent price = price * (1 - percent / 100)

-- | Fixed amount discount
fixedDiscount :: Double -> DiscountDecorator
fixedDiscount amount price = max 0 (price - amount)

-- | Seasonal discount (multiplier)
seasonalDiscount :: Double -> DiscountDecorator
seasonalDiscount multiplier price = price * multiplier

-- | Apply multiple discounts in sequence
applyDiscounts :: [DiscountDecorator] -> Double -> Double
applyDiscounts decorators price = foldl' (\p d -> d p) price decorators

-- ============================================================
-- Order Commands (Command Pattern)
-- ============================================================

-- | Order command typeclass
class OrderCommand cmd where
  execute :: cmd -> ShoppingCart -> ShoppingCart

-- | Add item command
data AddItem = AddItem Product Int
  deriving (Show, Eq)

instance OrderCommand AddItem where
  execute (AddItem product qty) cart =
    let item = CartItem product qty (productBasePrice product)
        newItems = item : scItems cart
    in cart { scItems = newItems }

-- | Remove item command
data RemoveItem = RemoveItem String
  deriving (Show, Eq)

instance OrderCommand RemoveItem where
  execute (RemoveItem prodId) cart =
    let newItems = filter (\item -> productId (ciProduct item) /= prodId) (scItems cart)
    in cart { scItems = newItems }

-- | Apply discount command
data ApplyDiscount = ApplyDiscount DiscountDecorator

instance OrderCommand ApplyDiscount where
  execute (ApplyDiscount discount) cart =
    cart { scDiscount = Just discount }

-- | Execute any command
executeCommand :: OrderCommand cmd => cmd -> ShoppingCart -> ShoppingCart
executeCommand = execute

-- ============================================================
-- Shopping Cart (Composite Pattern)
-- ============================================================

-- | Cart item
data CartItem = CartItem
  { ciProduct :: Product
  , ciQuantity :: Int
  , ciUnitPrice :: Double
  } deriving (Show, Eq)

-- | Shopping cart
data ShoppingCart = ShoppingCart
  { scItems :: [CartItem]
  , scDiscount :: Maybe DiscountDecorator
  }

instance Show ShoppingCart where
  show cart = "ShoppingCart { items = " ++ show (scItems cart) ++ 
              ", hasDiscount = " ++ show (hasDiscount cart) ++ " }"
    where hasDiscount c = case scDiscount c of { Nothing -> False; Just _ -> True }

-- | Create empty cart
emptyCart :: ShoppingCart
emptyCart = ShoppingCart [] Nothing

-- | Calculate cart total
cartTotal :: ShoppingCart -> Double
cartTotal cart =
  let subtotal = sum [ciUnitPrice item * fromIntegral (ciQuantity item) | item <- scItems cart]
  in case scDiscount cart of
       Nothing -> subtotal
       Just discount -> discount subtotal

-- | Get cart items
cartItems :: ShoppingCart -> [CartItem]
cartItems = scItems

-- ============================================================
-- Order Processing Pipeline
-- ============================================================

-- | Order processing result
data OrderResult
  = OrderSuccess ShoppingCart
  | OrderFailure String
  deriving (Show)

-- | Pipeline step
type OrderPipeline = ShoppingCart -> OrderResult

-- | Processing step (identity)
processingStep :: OrderPipeline
processingStep cart = OrderSuccess cart

-- | Validation step
validationStep :: OrderPipeline
validationStep cart =
  if null (scItems cart)
  then OrderFailure "Cart is empty"
  else OrderSuccess cart

-- | Pricing step (apply strategy to all items)
pricingStep :: PricingStrategy -> OrderPipeline
pricingStep strategy cart =
  let updatePrice item = item
        { ciUnitPrice = applyPricing strategy (ciProduct item) 1
        }
      updatedItems = map updatePrice (scItems cart)
  in OrderSuccess cart { scItems = updatedItems }

-- | Discount step
discountStep :: Double -> OrderPipeline
discountStep percent cart =
  OrderSuccess cart { scDiscount = Just (percentageDiscount percent) }

-- | Run pipeline
runPipeline :: [OrderPipeline] -> ShoppingCart -> OrderResult
runPipeline [] cart = OrderSuccess cart
runPipeline (step:steps) cart =
  case step cart of
    OrderFailure msg -> OrderFailure msg
    OrderSuccess cart' -> runPipeline steps cart'

-- ============================================================
-- Visitor for Cart Analysis
-- ============================================================

-- | Cart visitor for analysis
newtype CartVisitor a = CartVisitor
  { runVisitor :: ShoppingCart -> a
  }

-- | Count total items
itemCountVisitor :: CartVisitor Int
itemCountVisitor = CartVisitor $ \cart ->
  sum [ciQuantity item | item <- scItems cart]

-- | Calculate total value
totalValueVisitor :: CartVisitor Double
totalValueVisitor = CartVisitor cartTotal

-- | Calculate average item price
averageItemPriceVisitor :: CartVisitor Double
averageItemPriceVisitor = CartVisitor $ \cart ->
  let items = scItems cart
      count = length items
  in if count == 0
     then 0
     else sum [ciUnitPrice item | item <- items] / fromIntegral count

-- | Visit cart with a visitor
visitCart :: CartVisitor a -> ShoppingCart -> a
visitCart visitor cart = runVisitor visitor cart
