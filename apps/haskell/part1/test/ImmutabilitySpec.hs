{-|
Module      : ImmutabilitySpec
Description : Tests for Chapter 1 - Immutability and Data Transformation
-}
module ImmutabilitySpec (spec) where

import Test.Hspec
import Test.QuickCheck
import Immutability

spec :: Spec
spec = do
    describe "Person - Basic Immutability" $ do
        it "creates a person with name and age" $ do
            let person = Person "田中" 30
            personName person `shouldBe` "田中"
            personAge person `shouldBe` 30

        it "updateAge returns a new person with updated age" $ do
            let original = Person "田中" 30
            let updated = updateAge original 31
            personAge updated `shouldBe` 31

        it "updateAge does not modify the original person" $ do
            let original = Person "田中" 30
            let _ = updateAge original 31
            personAge original `shouldBe` 30

    describe "Team - Structural Sharing" $ do
        it "creates a team with members" $ do
            let team = Team "開発チーム" [Member "田中" Developer]
            teamName team `shouldBe` "開発チーム"
            length (teamMembers team) `shouldBe` 1

        it "addMember returns a new team with additional member" $ do
            let team = Team "開発チーム" [Member "田中" Developer]
            let newTeam = addMember team (Member "鈴木" Designer)
            length (teamMembers newTeam) `shouldBe` 2

        it "addMember does not modify the original team" $ do
            let team = Team "開発チーム" [Member "田中" Developer]
            let _ = addMember team (Member "鈴木" Designer)
            length (teamMembers team) `shouldBe` 1

    describe "Order Processing - Data Pipeline" $ do
        it "calculates subtotal for an item" $ do
            let item = Item "商品A" 1000 2
            calculateSubtotal item `shouldBe` 2000

        it "returns correct membership discount" $ do
            membershipDiscount Gold `shouldBe` 0.1
            membershipDiscount Silver `shouldBe` 0.05
            membershipDiscount Bronze `shouldBe` 0.02
            membershipDiscount Regular `shouldBe` 0.0

        it "calculates total for an order" $ do
            let items = [ Item "商品A" 1000 2
                       , Item "商品B" 500 3
                       , Item "商品C" 2000 1
                       ]
            let customer = Customer "山田" Gold
            let order = Order items customer
            calculateTotal order `shouldBe` 5500

        it "applies membership discount" $ do
            let items = [ Item "商品A" 1000 2
                       , Item "商品B" 500 3
                       , Item "商品C" 2000 1
                       ]
            let customer = Customer "山田" Gold
            let order = Order items customer
            applyDiscount order 5500 `shouldBe` 4950.0

        it "processes order with full pipeline" $ do
            let items = [ Item "商品A" 1000 2
                       , Item "商品B" 500 3
                       , Item "商品C" 2000 1
                       ]
            let customer = Customer "山田" Gold
            let order = Order items customer
            processOrder order `shouldBe` 4950.0

    describe "Invoice - Pure Function" $ do
        it "calculates invoice with tax" $ do
            let items = [Item "商品A" 1000 1]
            let invoice = calculateInvoice items 0.1
            invoiceSubtotal invoice `shouldBe` 1000
            invoiceTax invoice `shouldBe` 100.0
            invoiceTotal invoice `shouldBe` 1100.0

    describe "History - Undo/Redo" $ do
        it "creates empty history" $ do
            let history = createHistory :: History Int
            currentState history `shouldBe` Nothing
            canUndo history `shouldBe` False
            canRedo history `shouldBe` False

        it "pushes state onto history" $ do
            let h1 = createHistory :: History Int
            let h2 = pushState h1 1
            currentState h2 `shouldBe` Just 1

        it "supports undo operation" $ do
            let h1 = createHistory :: History Int
            let h2 = pushState h1 1
            let h3 = pushState h2 2
            let h4 = undo h3
            currentState h4 `shouldBe` Just 1
            canRedo h4 `shouldBe` True

        it "supports redo operation" $ do
            let h1 = createHistory :: History Int
            let h2 = pushState h1 1
            let h3 = pushState h2 2
            let h4 = undo h3
            let h5 = redo h4
            currentState h5 `shouldBe` Just 2

        it "clears future when pushing new state after undo" $ do
            let h1 = createHistory :: History Int
            let h2 = pushState h1 1
            let h3 = pushState h2 2
            let h4 = undo h3
            let h5 = pushState h4 3
            currentState h5 `shouldBe` Just 3
            canRedo h5 `shouldBe` False

        it "undo on empty history returns same history" $ do
            let history = createHistory :: History Int
            let undone = undo history
            currentState undone `shouldBe` Nothing

        it "redo on empty future returns same history" $ do
            let h1 = createHistory :: History Int
            let h2 = pushState h1 1
            let h3 = redo h2
            currentState h3 `shouldBe` Just 1

    describe "QuickCheck Properties" $ do
        it "updateAge preserves name" $ property $
            \name (NonNegative age) (NonNegative newAge) ->
                let person = Person name age
                    updated = updateAge person newAge
                in personName updated == name

        it "calculateSubtotal is price * quantity" $ property $
            \(Positive price) (Positive qty) ->
                let item = Item "Test" price qty
                in calculateSubtotal item == price * qty
