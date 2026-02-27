-- |
-- Module      : VideoRentalSystem
-- Description : Video Rental System case study implementation
-- 
-- This module implements Martin Fowler's classic video rental example
-- using functional programming patterns.
--
-- Movie categories:
-- - Regular: $2 for first 2 days, then $1.5/day
-- - New Release: $3/day
-- - Children's: $1.5 for first 3 days, then $1.5/day

module VideoRentalSystem
  ( -- * Movie Types
    Category(..)
  , Movie(..)
  , makeMovie
  , makeRegular
  , makeNewRelease
  , makeChildrens
  
  -- * Rental Types
  , Rental(..)
  , makeRental
  
  -- * Pricing
  , calculateAmount
  , calculatePoints
  
  -- * Customer Types
  , Customer(..)
  , makeCustomer
  , addRental
  
  -- * Statement Generation
  , StatementFormat(..)
  , generateStatement
  , generateTextStatement
  , generateHtmlStatement
  
  -- * Summary Functions
  , totalAmount
  , totalPoints
  ) where

-- ============================================================
-- Movie Types
-- ============================================================

-- | Movie category determines pricing rules
data Category
  = Regular       -- ^ 2 days for $2, then $1.5/day
  | NewRelease    -- ^ $3/day
  | Childrens     -- ^ 3 days for $1.5, then $1.5/day
  deriving (Show, Eq)

-- | A movie with title and category
data Movie = Movie
  { movieTitle :: String
  , movieCategory :: Category
  } deriving (Show, Eq)

-- | Create a movie
makeMovie :: String -> Category -> Movie
makeMovie = Movie

-- | Create a regular movie
makeRegular :: String -> Movie
makeRegular title = makeMovie title Regular

-- | Create a new release movie
makeNewRelease :: String -> Movie
makeNewRelease title = makeMovie title NewRelease

-- | Create a children's movie
makeChildrens :: String -> Movie
makeChildrens title = makeMovie title Childrens

-- ============================================================
-- Rental Types
-- ============================================================

-- | A rental of a movie for a number of days
data Rental = Rental
  { rentalMovie :: Movie
  , rentalDays :: Int
  } deriving (Show, Eq)

-- | Create a rental
makeRental :: Movie -> Int -> Rental
makeRental = Rental

-- ============================================================
-- Pricing
-- ============================================================

-- | Calculate the rental amount based on movie category and days
calculateAmount :: Rental -> Double
calculateAmount rental = case movieCategory (rentalMovie rental) of
  Regular ->
    if days > 2
    then 2.0 + fromIntegral (days - 2) * 1.5
    else 2.0
  
  NewRelease ->
    fromIntegral days * 3.0
  
  Childrens ->
    if days > 3
    then 1.5 + fromIntegral (days - 3) * 1.5
    else 1.5
  where
    days = rentalDays rental

-- | Calculate frequent renter points
calculatePoints :: Rental -> Int
calculatePoints rental = case movieCategory (rentalMovie rental) of
  NewRelease -> if rentalDays rental > 1 then 2 else 1
  _ -> 1

-- ============================================================
-- Customer Types
-- ============================================================

-- | A customer with name and rentals
data Customer = Customer
  { customerName :: String
  , customerRentals :: [Rental]
  } deriving (Show, Eq)

-- | Create a customer with no rentals
makeCustomer :: String -> Customer
makeCustomer name = Customer name []

-- | Add a rental to a customer
addRental :: Rental -> Customer -> Customer
addRental rental customer = customer
  { customerRentals = rental : customerRentals customer
  }

-- ============================================================
-- Summary Functions
-- ============================================================

-- | Calculate total amount for all rentals
totalAmount :: Customer -> Double
totalAmount = sum . map calculateAmount . customerRentals

-- | Calculate total points for all rentals
totalPoints :: Customer -> Int
totalPoints = sum . map calculatePoints . customerRentals

-- ============================================================
-- Statement Generation
-- ============================================================

-- | Statement format
data StatementFormat = TextFormat | HtmlFormat
  deriving (Show, Eq)

-- | Generate a rental statement in the specified format
generateStatement :: StatementFormat -> Customer -> String
generateStatement format = case format of
  TextFormat -> generateTextStatement
  HtmlFormat -> generateHtmlStatement

-- | Generate a plain text statement
generateTextStatement :: Customer -> String
generateTextStatement customer = unlines
  [ "Rental Record for " ++ customerName customer
  , ""
  ] ++ rentalLines ++ unlines
  [ ""
  , "Amount owed is " ++ show (totalAmount customer)
  , "You earned " ++ show (totalPoints customer) ++ " frequent renter points"
  ]
  where
    rentalLines = unlines $ map formatRentalLine (customerRentals customer)
    formatRentalLine rental = 
      "\t" ++ movieTitle (rentalMovie rental) ++ "\t" ++ show (calculateAmount rental)

-- | Generate an HTML statement
generateHtmlStatement :: Customer -> String
generateHtmlStatement customer = unlines
  [ "<html>"
  , "<head><title>Rental Statement</title></head>"
  , "<body>"
  , "<h1>Rental Record for " ++ customerName customer ++ "</h1>"
  , "<table>"
  , "<tr><th>Movie</th><th>Amount</th></tr>"
  ] ++ rentalRows ++ unlines
  [ "</table>"
  , "<p>Amount owed is <strong>" ++ show (totalAmount customer) ++ "</strong></p>"
  , "<p>You earned <strong>" ++ show (totalPoints customer) ++ "</strong> frequent renter points</p>"
  , "</body>"
  , "</html>"
  ]
  where
    rentalRows = unlines $ map formatRentalRow (customerRentals customer)
    formatRentalRow rental =
      "<tr><td>" ++ movieTitle (rentalMovie rental) ++ "</td><td>" ++ show (calculateAmount rental) ++ "</td></tr>"
