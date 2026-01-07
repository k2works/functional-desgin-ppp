{-# LANGUAGE GADTs #-}

-- |
-- Module      : StrategyPattern
-- Description : Strategy pattern implementation in Haskell
-- 
-- This module demonstrates the Strategy pattern using various examples:
-- - Pricing strategies: Regular, Discount, Member pricing
-- - Shipping strategies: Standard, Express, Free shipping
-- - Sorting strategies: Different sorting algorithms

module StrategyPattern
  ( -- * Pricing Strategies
    PricingStrategy(..)
  , regularPricing
  , discountPricing
  , memberPricing
  , bulkPricing
  , calculatePrice
  
  -- * Member Levels
  , MemberLevel(..)
  
  -- * Shipping Strategies
  , ShippingStrategy(..)
  , standardShipping
  , expressShipping
  , freeShipping
  , calculateShipping
  
  -- * Shopping Cart
  , CartItem(..)
  , ShoppingCart(..)
  , makeCart
  , addItem
  , cartSubtotal
  , cartTotal
  , changeStrategy
  
  -- * Strategy Composition
  , composeStrategies
  , conditionalStrategy
  , taxStrategy
  
  -- * Sorting Strategies
  , SortStrategy
  , bubbleSort
  , quickSort
  , mergeSort
  , sortWith
  ) where



-- ============================================================
-- Member Levels
-- ============================================================

-- | Member levels for member pricing
data MemberLevel = Bronze | Silver | Gold
  deriving (Show, Eq)

-- | Get discount rate for member level
memberDiscountRate :: MemberLevel -> Double
memberDiscountRate Bronze = 0.10
memberDiscountRate Silver = 0.15
memberDiscountRate Gold   = 0.20

-- ============================================================
-- Pricing Strategies
-- ============================================================

-- | Pricing strategy as a function
newtype PricingStrategy = PricingStrategy { runPricing :: Double -> Double }

-- | Regular pricing (no discount)
regularPricing :: PricingStrategy
regularPricing = PricingStrategy id

-- | Discount pricing with a rate
discountPricing :: Double -> PricingStrategy
discountPricing rate = PricingStrategy $ \amount -> amount * (1 - rate)

-- | Member pricing based on member level
memberPricing :: MemberLevel -> PricingStrategy
memberPricing level = discountPricing (memberDiscountRate level)

-- | Bulk pricing: discount for orders over threshold
bulkPricing :: Double -> Double -> PricingStrategy
bulkPricing threshold rate = PricingStrategy $ \amount ->
  if amount >= threshold
    then amount * (1 - rate)
    else amount

-- | Calculate price using a strategy
calculatePrice :: PricingStrategy -> Double -> Double
calculatePrice = runPricing

-- ============================================================
-- Shipping Strategies
-- ============================================================

-- | Shipping strategy as a function
newtype ShippingStrategy = ShippingStrategy 
  { runShipping :: Double -> Double -> Double  -- ^ weight -> distance -> cost
  }

-- | Standard shipping
standardShipping :: ShippingStrategy
standardShipping = ShippingStrategy $ \weight distance ->
  weight * 10 + distance * 5

-- | Express shipping
expressShipping :: ShippingStrategy
expressShipping = ShippingStrategy $ \weight distance ->
  weight * 20 + distance * 15

-- | Free shipping (always returns 0)
freeShipping :: ShippingStrategy
freeShipping = ShippingStrategy $ \_ _ -> 0

-- | Calculate shipping cost
calculateShipping :: ShippingStrategy -> Double -> Double -> Double
calculateShipping strategy weight distance = runShipping strategy weight distance

-- ============================================================
-- Shopping Cart
-- ============================================================

-- | Cart item
data CartItem = CartItem
  { itemName :: String
  , itemPrice :: Double
  } deriving (Show, Eq)

-- | Shopping cart with pricing strategy
data ShoppingCart = ShoppingCart
  { cartItems :: [CartItem]
  , cartStrategy :: PricingStrategy
  }

-- | Create a new cart with a pricing strategy
makeCart :: PricingStrategy -> ShoppingCart
makeCart strategy = ShoppingCart
  { cartItems = []
  , cartStrategy = strategy
  }

-- | Add an item to the cart
addItem :: CartItem -> ShoppingCart -> ShoppingCart
addItem item cart = cart { cartItems = cartItems cart ++ [item] }

-- | Calculate cart subtotal (without discount)
cartSubtotal :: ShoppingCart -> Double
cartSubtotal = sum . map itemPrice . cartItems

-- | Calculate cart total (with pricing strategy applied)
cartTotal :: ShoppingCart -> Double
cartTotal cart = calculatePrice (cartStrategy cart) (cartSubtotal cart)

-- | Change the pricing strategy
changeStrategy :: PricingStrategy -> ShoppingCart -> ShoppingCart
changeStrategy strategy cart = cart { cartStrategy = strategy }

-- ============================================================
-- Strategy Composition
-- ============================================================

-- | Compose multiple strategies (apply in sequence)
composeStrategies :: [PricingStrategy] -> PricingStrategy
composeStrategies strategies = PricingStrategy $ \amount ->
  foldr (\s acc -> runPricing s acc) amount (reverse strategies)

-- | Conditional strategy: choose strategy based on predicate
conditionalStrategy :: (Double -> Bool) -> PricingStrategy -> PricingStrategy -> PricingStrategy
conditionalStrategy predicate thenStrategy elseStrategy = PricingStrategy $ \amount ->
  if predicate amount
    then runPricing thenStrategy amount
    else runPricing elseStrategy amount

-- | Tax strategy: add tax to amount
taxStrategy :: Double -> PricingStrategy
taxStrategy rate = PricingStrategy $ \amount -> amount * (1 + rate)

-- ============================================================
-- Sorting Strategies
-- ============================================================

-- | Sorting strategy as a function
type SortStrategy a = [a] -> [a]

-- | Bubble sort (simple but O(n²))
bubbleSort :: Ord a => SortStrategy a
bubbleSort [] = []
bubbleSort xs = bubblePass (length xs) xs
  where
    bubblePass 0 ys = ys
    bubblePass n ys = bubblePass (n - 1) (bubble ys)
    
    bubble [] = []
    bubble [x] = [x]
    bubble (x:y:rest)
      | x > y     = y : bubble (x:rest)
      | otherwise = x : bubble (y:rest)

-- | Quick sort (average O(n log n))
quickSort :: Ord a => SortStrategy a
quickSort [] = []
quickSort (x:xs) = 
  let smaller = quickSort [y | y <- xs, y <= x]
      larger = quickSort [y | y <- xs, y > x]
  in smaller ++ [x] ++ larger

-- | Merge sort (guaranteed O(n log n))
mergeSort :: Ord a => SortStrategy a
mergeSort [] = []
mergeSort [x] = [x]
mergeSort xs = merge (mergeSort left) (mergeSort right)
  where
    (left, right) = splitAt (length xs `div` 2) xs
    
    merge [] ys = ys
    merge xs' [] = xs'
    merge (x:xs') (y:ys)
      | x <= y    = x : merge xs' (y:ys)
      | otherwise = y : merge (x:xs') ys

-- | Sort a list using a strategy
sortWith :: SortStrategy a -> [a] -> [a]
sortWith strategy = strategy
