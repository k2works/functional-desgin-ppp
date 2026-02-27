-- |
-- Module      : GossipingBusDriversSpec
-- Description : Tests for Gossiping Bus Drivers

module GossipingBusDriversSpec (spec) where

import Test.Hspec
import qualified Data.Set as Set
import GossipingBusDrivers

spec :: Spec
spec = do
  describe "Driver Construction" $ do
    describe "makeDriver" $ do
      it "creates driver with single gossip" $ do
        let driver = makeDriver 0 [1, 2, 3]
        driverGossip driver `shouldBe` Set.singleton 0
      
      it "creates driver with cyclic route" $ do
        let driver = makeDriver 0 [1, 2]
        take 5 (driverRoute driver) `shouldBe` [1, 2, 1, 2, 1]
    
    describe "makeDrivers" $ do
      it "creates multiple drivers with unique gossip" $ do
        let drivers = makeDrivers [[1, 2], [3, 4], [5, 6]]
        length drivers `shouldBe` 3
        map driverId drivers `shouldBe` [0, 1, 2]
        all (\d -> Set.size (driverGossip d) == 1) drivers `shouldBe` True

  describe "Simulation" $ do
    describe "currentStop" $ do
      it "returns the first stop in route" $ do
        let driver = makeDriver 0 [5, 10, 15]
        currentStop driver `shouldBe` 5
    
    describe "moveDriver" $ do
      it "advances to next stop" $ do
        let driver = makeDriver 0 [1, 2, 3]
            moved = moveDriver driver
        currentStop moved `shouldBe` 2
      
      it "cycles back to first stop after completing route" $ do
        let driver = makeDriver 0 [1, 2]
            moved = moveDriver (moveDriver driver)
        currentStop moved `shouldBe` 1
    
    describe "moveDrivers" $ do
      it "moves all drivers" $ do
        let drivers = makeDrivers [[1, 2], [3, 4]]
            moved = moveDrivers drivers
        map currentStop moved `shouldBe` [2, 4]
    
    describe "driversAtStops" $ do
      it "groups drivers by current stop" $ do
        let d1 = makeDriver 0 [1, 2]
            d2 = makeDriver 1 [1, 3]
            d3 = makeDriver 2 [2, 4]
            stops = driversAtStops [d1, d2, d3]
        length (stops) `shouldBe` 2  -- stops 1 and 2
    
    describe "mergeGossip" $ do
      it "shares gossip among drivers" $ do
        let d1 = makeDriver 0 [1]
            d2 = makeDriver 1 [1]
            merged = mergeGossip [d1, d2]
        all (\d -> driverGossip d == Set.fromList [0, 1]) merged `shouldBe` True
      
      it "preserves gossip when single driver" $ do
        let d = makeDriver 5 [1]
            [merged] = mergeGossip [d]
        driverGossip merged `shouldBe` Set.singleton 5
    
    describe "spreadGossip" $ do
      it "spreads gossip at same stops" $ do
        let d1 = makeDriver 0 [1]
            d2 = makeDriver 1 [1]
            d3 = makeDriver 2 [2]
            spread = spreadGossip [d1, d2, d3]
            gossipSizes = map (Set.size . driverGossip) spread
            sortList = foldr insertSorted []
            insertSorted x [] = [x]
            insertSorted x (y:ys) = if x <= y then x:y:ys else y : insertSorted x ys
        -- d1 and d2 at stop 1 share, d3 at stop 2 alone
        sortList gossipSizes `shouldBe` [1, 2, 2]
    
    describe "drive" $ do
      it "moves and spreads gossip" $ do
        let drivers = makeDrivers [[1, 2], [2, 1]]
            -- Initially: d0 at 1, d1 at 2
            -- After move: d0 at 2, d1 at 1
            -- After spread: they are at different stops so no sharing
            after1 = drive drivers
        -- The order after spreadGossip may change due to Map operations
        length after1 `shouldBe` 2

  describe "Completion Check" $ do
    describe "allGossipShared" $ do
      it "returns true when all drivers have same gossip" $ do
        let d1 = makeDriver 0 [1]
            d2 = makeDriver 1 [1]
            [d1', d2'] = mergeGossip [d1, d2]
        allGossipShared [d1', d2'] `shouldBe` True
      
      it "returns false when drivers have different gossip" $ do
        let d1 = makeDriver 0 [1]
            d2 = makeDriver 1 [2]
        allGossipShared [d1, d2] `shouldBe` False
      
      it "returns true for empty list" $ do
        allGossipShared [] `shouldBe` True
      
      it "returns true for single driver" $ do
        allGossipShared [makeDriver 0 [1]] `shouldBe` True
    
    describe "totalGossip" $ do
      it "returns union of all gossip" $ do
        let d1 = makeDriver 0 [1]
            d2 = makeDriver 1 [2]
        totalGossip [d1, d2] `shouldBe` Set.fromList [0, 1]

  describe "Solver" $ do
    describe "solve" $ do
      it "solves simple case with shared route" $ do
        -- Two drivers meeting immediately after first move (both at stop 1)
        -- Initial: both at 1 -> move to next
        -- Actually with drive = spreadGossip . moveDrivers, 
        -- drivers at same stop BEFORE move share, then move
        -- Let's test differently
        let routes = [[1], [1]]
        -- After 1 step: both moved (still at 1 because cycle), then share
        solve routes `shouldBe` Just 1
      
      it "solves case where drivers meet after one step" $ do
        -- d0: 1 -> 2, d1: 2 -> 1
        -- After step 1: d0 at 2, d1 at 1 (no meet)
        -- After step 2: d0 at 1, d1 at 2 (no meet)  
        -- This won't converge...let's try different routes
        let routes = [[1, 2], [2, 1]]
        -- Initial: d0 at 1, d1 at 2
        -- After 1: d0 at 2, d1 at 1 
        -- After 2: d0 at 1, d1 at 2
        -- They never meet!
        solve routes `shouldBe` Nothing
      
      it "solves case with single driver" $ do
        solve [[1, 2, 3]] `shouldBe` Just 0
      
      it "solves case with meeting point" $ do
        -- Drivers that eventually meet
        let routes = [[1, 2, 3], [1, 3, 2]]
        -- Initial: both at 1 - already share (allGossipShared returns true at start)
        -- With only 1 driver's gossip each, they need to share
        -- Let's check - 2 drivers with different gossip
        -- After move: d0 at 2, d1 at 3
        -- After 2: d0 at 3, d1 at 2
        -- After 3: d0 at 1, d1 at 1 - share!
        solve routes `shouldBe` Just 3
      
      it "solves case requiring multiple steps" $ do
        -- d0: 1 -> 2 -> 3
        -- d1: 3 -> 2 -> 1
        -- Initial: d0 at 1, d1 at 3
        -- After 1: d0 at 2, d1 at 2 - they meet!
        let routes = [[1, 2, 3], [3, 2, 1]]
        solve routes `shouldBe` Just 1
    
    describe "solveWithLimit" $ do
      it "returns Nothing when limit exceeded" $ do
        solveWithLimit 5 [[1, 2], [3, 4]] `shouldBe` Nothing
      
      it "respects custom limit" $ do
        solveWithLimit 0 [[1], [2]] `shouldBe` Nothing
