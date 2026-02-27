-- |
-- Module      : VideoRentalSystemSpec
-- Description : Tests for Video Rental System

module VideoRentalSystemSpec (spec) where

import Test.Hspec
import Data.List (isInfixOf)
import VideoRentalSystem

spec :: Spec
spec = do
  describe "Movie Construction" $ do
    describe "makeMovie" $ do
      it "creates movie with title and category" $ do
        let movie = makeMovie "The Matrix" Regular
        movieTitle movie `shouldBe` "The Matrix"
        movieCategory movie `shouldBe` Regular
    
    describe "makeRegular" $ do
      it "creates regular movie" $ do
        let movie = makeRegular "Casablanca"
        movieCategory movie `shouldBe` Regular
    
    describe "makeNewRelease" $ do
      it "creates new release movie" $ do
        let movie = makeNewRelease "Avatar 3"
        movieCategory movie `shouldBe` NewRelease
    
    describe "makeChildrens" $ do
      it "creates children's movie" $ do
        let movie = makeChildrens "Finding Nemo"
        movieCategory movie `shouldBe` Childrens

  describe "Rental Construction" $ do
    describe "makeRental" $ do
      it "creates rental with movie and days" $ do
        let movie = makeRegular "Test Movie"
            rental = makeRental movie 5
        rentalMovie rental `shouldBe` movie
        rentalDays rental `shouldBe` 5

  describe "Pricing" $ do
    describe "calculateAmount" $ do
      describe "Regular Movie" $ do
        it "charges $2 for 1 day" $ do
          let rental = makeRental (makeRegular "Test") 1
          calculateAmount rental `shouldBe` 2.0
        
        it "charges $2 for 2 days" $ do
          let rental = makeRental (makeRegular "Test") 2
          calculateAmount rental `shouldBe` 2.0
        
        it "charges $2 + $1.5/day after 2 days" $ do
          let rental = makeRental (makeRegular "Test") 5
          -- 2 + 3 * 1.5 = 2 + 4.5 = 6.5
          calculateAmount rental `shouldBe` 6.5
      
      describe "New Release Movie" $ do
        it "charges $3 per day" $ do
          let rental = makeRental (makeNewRelease "Test") 1
          calculateAmount rental `shouldBe` 3.0
        
        it "charges $3 per day for multiple days" $ do
          let rental = makeRental (makeNewRelease "Test") 5
          calculateAmount rental `shouldBe` 15.0
      
      describe "Children's Movie" $ do
        it "charges $1.5 for 1 day" $ do
          let rental = makeRental (makeChildrens "Test") 1
          calculateAmount rental `shouldBe` 1.5
        
        it "charges $1.5 for 3 days" $ do
          let rental = makeRental (makeChildrens "Test") 3
          calculateAmount rental `shouldBe` 1.5
        
        it "charges $1.5 + $1.5/day after 3 days" $ do
          let rental = makeRental (makeChildrens "Test") 5
          -- 1.5 + 2 * 1.5 = 1.5 + 3.0 = 4.5
          calculateAmount rental `shouldBe` 4.5
    
    describe "calculatePoints" $ do
      describe "Regular Movie" $ do
        it "earns 1 point" $ do
          let rental = makeRental (makeRegular "Test") 5
          calculatePoints rental `shouldBe` 1
      
      describe "New Release Movie" $ do
        it "earns 1 point for 1 day" $ do
          let rental = makeRental (makeNewRelease "Test") 1
          calculatePoints rental `shouldBe` 1
        
        it "earns 2 points for 2+ days" $ do
          let rental = makeRental (makeNewRelease "Test") 2
          calculatePoints rental `shouldBe` 2
        
        it "earns 2 points for many days" $ do
          let rental = makeRental (makeNewRelease "Test") 10
          calculatePoints rental `shouldBe` 2
      
      describe "Children's Movie" $ do
        it "earns 1 point" $ do
          let rental = makeRental (makeChildrens "Test") 5
          calculatePoints rental `shouldBe` 1

  describe "Customer" $ do
    describe "makeCustomer" $ do
      it "creates customer with no rentals" $ do
        let customer = makeCustomer "John Doe"
        customerName customer `shouldBe` "John Doe"
        customerRentals customer `shouldBe` []
    
    describe "addRental" $ do
      it "adds rental to customer" $ do
        let customer = makeCustomer "John"
            rental = makeRental (makeRegular "Movie 1") 3
            customer' = addRental rental customer
        length (customerRentals customer') `shouldBe` 1
      
      it "accumulates rentals" $ do
        let customer = makeCustomer "John"
            r1 = makeRental (makeRegular "Movie 1") 3
            r2 = makeRental (makeNewRelease "Movie 2") 2
            customer' = addRental r2 (addRental r1 customer)
        length (customerRentals customer') `shouldBe` 2

  describe "Summary Functions" $ do
    describe "totalAmount" $ do
      it "calculates total for all rentals" $ do
        let customer = makeCustomer "John"
            r1 = makeRental (makeRegular "Movie 1") 3     -- 2 + 1.5 = 3.5
            r2 = makeRental (makeNewRelease "Movie 2") 2  -- 6.0
            customer' = addRental r2 (addRental r1 customer)
        totalAmount customer' `shouldBe` 9.5
      
      it "returns 0 for no rentals" $ do
        totalAmount (makeCustomer "John") `shouldBe` 0
    
    describe "totalPoints" $ do
      it "calculates total points" $ do
        let customer = makeCustomer "John"
            r1 = makeRental (makeRegular "Movie 1") 3     -- 1 point
            r2 = makeRental (makeNewRelease "Movie 2") 2  -- 2 points
            customer' = addRental r2 (addRental r1 customer)
        totalPoints customer' `shouldBe` 3
      
      it "returns 0 for no rentals" $ do
        totalPoints (makeCustomer "John") `shouldBe` 0

  describe "Statement Generation" $ do
    describe "generateTextStatement" $ do
      it "generates text statement" $ do
        let customer = makeCustomer "John"
            r1 = makeRental (makeRegular "The Matrix") 3
            customer' = addRental r1 customer
            statement = generateTextStatement customer'
        "Rental Record for John" `shouldSatisfy` (`isInfixOf` statement)
        "The Matrix" `shouldSatisfy` (`isInfixOf` statement)
        "Amount owed" `shouldSatisfy` (`isInfixOf` statement)
        "frequent renter points" `shouldSatisfy` (`isInfixOf` statement)
    
    describe "generateHtmlStatement" $ do
      it "generates HTML statement" $ do
        let customer = makeCustomer "Jane"
            r1 = makeRental (makeNewRelease "Avatar") 2
            customer' = addRental r1 customer
            statement = generateHtmlStatement customer'
        "<html>" `shouldSatisfy` (`isInfixOf` statement)
        "Rental Record for Jane" `shouldSatisfy` (`isInfixOf` statement)
        "<table>" `shouldSatisfy` (`isInfixOf` statement)
        "Avatar" `shouldSatisfy` (`isInfixOf` statement)
        "</html>" `shouldSatisfy` (`isInfixOf` statement)
    
    describe "generateStatement" $ do
      it "uses text format" $ do
        let customer = makeCustomer "Test"
            statement = generateStatement TextFormat customer
        "Rental Record" `shouldSatisfy` (`isInfixOf` statement)
        "<html>" `shouldSatisfy` (not . (`isInfixOf` statement))
      
      it "uses HTML format" $ do
        let customer = makeCustomer "Test"
            statement = generateStatement HtmlFormat customer
        "<html>" `shouldSatisfy` (`isInfixOf` statement)
