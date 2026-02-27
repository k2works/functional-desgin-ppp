module WatorSimulationSpec (spec) where

import Test.Hspec
import System.Random (mkStdGen)
import qualified Data.Map.Strict as Map

import WatorSimulation

spec :: Spec
spec = do
  describe "Cell Types" $ do
    describe "Cell identification" $ do
      it "identifies water cells" $ do
        isWater makeWater `shouldBe` True
        isWater (makeFish 3) `shouldBe` False
        isWater (makeShark 5 10) `shouldBe` False

      it "identifies fish cells" $ do
        isFish (makeFish 3) `shouldBe` True
        isFish makeWater `shouldBe` False
        isFish (makeShark 5 10) `shouldBe` False

      it "identifies shark cells" $ do
        isShark (makeShark 5 10) `shouldBe` True
        isShark makeWater `shouldBe` False
        isShark (makeFish 3) `shouldBe` False

    describe "Cell creation" $ do
      it "creates water cell" $ do
        displayCell makeWater `shouldBe` '.'

      it "creates fish cell with reproduction age" $ do
        let fish = makeFish 3
        isFish fish `shouldBe` True
        displayCell fish `shouldBe` 'f'

      it "creates shark cell with reproduction age and energy" $ do
        let shark = makeShark 5 10
        isShark shark `shouldBe` True
        displayCell shark `shouldBe` 'S'

  describe "World Construction" $ do
    describe "makeWorld" $ do
      it "creates world with correct dimensions" $ do
        let world = makeWorld 10 8 3 5 10 3
        worldWidth world `shouldBe` 10
        worldHeight world `shouldBe` 8

      it "initializes all cells as water" $ do
        let world = makeWorld 5 5 3 5 10 3
            stats = getStats world
        statsWater stats `shouldBe` 25
        statsFish stats `shouldBe` 0
        statsSharks stats `shouldBe` 0

      it "stores fish reproduction age" $ do
        let world = makeWorld 5 5 3 5 10 3
        worldFishReproAge world `shouldBe` 3

      it "stores shark parameters" $ do
        let world = makeWorld 5 5 3 5 10 3
        worldSharkReproAge world `shouldBe` 5
        worldSharkInitialEnergy world `shouldBe` 10
        worldSharkEnergyFromFish world `shouldBe` 3

    describe "makeWorldWithCells" $ do
      it "creates world with specified cells" $ do
        let cells = [((2, 2), makeFish 3), ((3, 3), makeShark 5 10)]
            world = makeWorldWithCells 5 5 3 5 10 3 cells
            stats = getStats world
        statsFish stats `shouldBe` 1
        statsSharks stats `shouldBe` 1
        statsWater stats `shouldBe` 23

    describe "getCell and setCell" $ do
      it "gets cell at location" $ do
        let world = makeWorld 5 5 3 5 10 3
        isWater (getCell world (0, 0)) `shouldBe` True

      it "sets cell at location" $ do
        let world = makeWorld 5 5 3 5 10 3
            world' = setCell world (2, 2) (makeFish 3)
        isFish (getCell world' (2, 2)) `shouldBe` True

  describe "Coordinate Operations" $ do
    describe "wrapCoord" $ do
      it "wraps positive overflow x coordinate" $ do
        let world = makeWorld 5 5 3 5 10 3
        wrapCoord world (5, 2) `shouldBe` (0, 2)
        wrapCoord world (6, 2) `shouldBe` (1, 2)

      it "wraps positive overflow y coordinate" $ do
        let world = makeWorld 5 5 3 5 10 3
        wrapCoord world (2, 5) `shouldBe` (2, 0)
        wrapCoord world (2, 7) `shouldBe` (2, 2)

      it "wraps negative coordinates" $ do
        let world = makeWorld 5 5 3 5 10 3
        wrapCoord world (-1, 2) `shouldBe` (4, 2)
        wrapCoord world (2, -1) `shouldBe` (2, 4)

      it "handles corner cases" $ do
        let world = makeWorld 5 5 3 5 10 3
        wrapCoord world (-1, -1) `shouldBe` (4, 4)
        wrapCoord world (5, 5) `shouldBe` (0, 0)

    describe "neighbors" $ do
      it "returns 8 neighbors" $ do
        let world = makeWorld 10 10 3 5 10 3
        length (neighbors world (5, 5)) `shouldBe` 8

      it "wraps around edges" $ do
        let world = makeWorld 5 5 3 5 10 3
            ns = neighbors world (0, 0)
        (4, 4) `elem` ns `shouldBe` True  -- Top-left wraps to bottom-right
        (4, 0) `elem` ns `shouldBe` True  -- Left wraps to right
        (0, 4) `elem` ns `shouldBe` True  -- Top wraps to bottom

    describe "neighborsOf" $ do
      it "finds water neighbors" $ do
        let world = makeWorld 5 5 3 5 10 3
            waterNeighbors = neighborsOf world (2, 2) isWater
        length waterNeighbors `shouldBe` 8

      it "finds fish neighbors" $ do
        let cells = [((1, 2), makeFish 3), ((3, 2), makeFish 3)]
            world = makeWorldWithCells 5 5 3 5 10 3 cells
            fishNeighbors = neighborsOf world (2, 2) isFish
        length fishNeighbors `shouldBe` 2

      it "finds no neighbors of wrong type" $ do
        let world = makeWorld 5 5 3 5 10 3
            sharkNeighbors = neighborsOf world (2, 2) isShark
        length sharkNeighbors `shouldBe` 0

  describe "Cell Ticking" $ do
    describe "Water cells" $ do
      it "water stays water" $ do
        let world = makeWorld 5 5 3 5 10 3
            gen = mkStdGen 42
            (result, _) = tickCell world (2, 2) gen
        result `shouldBe` Stay makeWater

    describe "Fish cells" $ do
      it "fish stays if no empty neighbors" $ do
        let cells = [((x, y), makeFish 3) | x <- [0..4], y <- [0..4]]
            world = makeWorldWithCells 5 5 3 5 10 3 cells
            gen = mkStdGen 42
            (result, _) = tickCell world (2, 2) gen
        case result of
          Stay fish -> isFish fish `shouldBe` True
          _ -> expectationFailure "Expected Stay"

      it "fish moves to empty neighbor" $ do
        let cells = [((2, 2), makeFish 3)]
            world = makeWorldWithCells 5 5 3 5 10 3 cells
            gen = mkStdGen 42
            (result, _) = tickCell world (2, 2) gen
        case result of
          Move loc cell leftBehind -> do
            isFish cell `shouldBe` True
            loc `elem` neighbors world (2, 2) `shouldBe` True
          _ -> expectationFailure "Expected Move"

    describe "Shark cells" $ do
      it "shark dies when energy reaches 0" $ do
        let shark = SharkCell 0 5 1  -- Energy will become 0 after tick
            cells = [((2, 2), shark)]
            world = makeWorldWithCells 5 5 3 5 10 3 cells
            gen = mkStdGen 42
            (result, _) = tickCell world (2, 2) gen
        result `shouldBe` Die

      it "shark eats fish when adjacent" $ do
        let cells = [((2, 2), makeShark 5 10), ((2, 3), makeFish 3)]
            world = makeWorldWithCells 5 5 3 5 10 3 cells
            gen = mkStdGen 42
            (result, _) = tickCell world (2, 2) gen
        case result of
          Move loc cell _ -> do
            isShark cell `shouldBe` True
            -- Should move to where the fish was or another fish location
            isFish (getCell world loc) `shouldBe` True
          _ -> expectationFailure "Expected Move (eat fish)"

      it "shark moves to empty if no fish" $ do
        let cells = [((2, 2), makeShark 5 10)]
            world = makeWorldWithCells 5 5 3 5 10 3 cells
            gen = mkStdGen 42
            (result, _) = tickCell world (2, 2) gen
        case result of
          Move loc cell _ -> do
            isShark cell `shouldBe` True
            loc `elem` neighbors world (2, 2) `shouldBe` True
          _ -> expectationFailure "Expected Move"

  describe "World Ticking" $ do
    it "ticks all cells" $ do
      let cells = [((2, 2), makeFish 3)]
          world = makeWorldWithCells 5 5 3 5 10 3 cells
          gen = mkStdGen 42
          (world', _) = tickWorld world gen
          stats = getStats world'
      -- Fish should still exist (moved or stayed)
      statsFish stats `shouldBe` 1

    it "handles fish reproduction" $ do
      let fish = FishCell 2 3  -- Age 2, will reproduce at age 3
          cells = [((2, 2), fish)]
          world = makeWorldWithCells 5 5 3 5 10 3 cells
          gen = mkStdGen 42
          (world', _) = tickWorld world gen
          stats = getStats world'
      -- After reproduction, there should be 2 fish
      statsFish stats `shouldBe` 2

    it "handles shark starvation" $ do
      let shark = SharkCell 0 5 1  -- Low energy
          cells = [((2, 2), shark)]
          world = makeWorldWithCells 5 5 3 5 10 3 cells
          gen = mkStdGen 42
          (world', _) = tickWorld world gen
          stats = getStats world'
      -- Shark should have died
      statsSharks stats `shouldBe` 0

  describe "Simulation" $ do
    describe "runSimulation" $ do
      it "runs for specified steps" $ do
        let cells = [((2, 2), makeFish 3)]
            world = makeWorldWithCells 5 5 3 5 10 3 cells
            gen = mkStdGen 42
            results = runSimulation 5 world gen
        length results `shouldBe` 5

      it "returns world and stats for each step" $ do
        let cells = [((2, 2), makeFish 3)]
            world = makeWorldWithCells 5 5 3 5 10 3 cells
            gen = mkStdGen 42
            results = runSimulation 3 world gen
        all (\(_, stats) -> statsFish stats >= 0) results `shouldBe` True

      it "returns empty for 0 steps" $ do
        let world = makeWorld 5 5 3 5 10 3
            gen = mkStdGen 42
        runSimulation 0 world gen `shouldBe` []

  describe "Display" $ do
    describe "displayCell" $ do
      it "displays water as '.'" $ do
        displayCell makeWater `shouldBe` '.'

      it "displays fish as 'f'" $ do
        displayCell (makeFish 3) `shouldBe` 'f'

      it "displays shark as 'S'" $ do
        displayCell (makeShark 5 10) `shouldBe` 'S'

    describe "displayWorld" $ do
      it "displays empty world as dots" $ do
        let world = makeWorld 3 3 3 5 10 3
            display = displayWorld world
        display `shouldBe` "...\n...\n...\n"

      it "displays cells at correct positions" $ do
        let cells = [((1, 1), makeFish 3)]
            world = makeWorldWithCells 3 3 3 5 10 3 cells
            display = displayWorld world
        display `shouldBe` "...\n.f.\n...\n"

      it "displays multiple cell types" $ do
        let cells = [((0, 0), makeFish 3), ((2, 2), makeShark 5 10)]
            world = makeWorldWithCells 3 3 3 5 10 3 cells
            display = displayWorld world
        display `shouldBe` "f..\n...\n..S\n"

  describe "Statistics" $ do
    describe "getStats" $ do
      it "counts all water in empty world" $ do
        let world = makeWorld 5 5 3 5 10 3
            stats = getStats world
        statsWater stats `shouldBe` 25
        statsFish stats `shouldBe` 0
        statsSharks stats `shouldBe` 0

      it "counts fish and sharks" $ do
        let cells = [ ((0, 0), makeFish 3)
                    , ((1, 1), makeFish 3)
                    , ((2, 2), makeShark 5 10)
                    ]
            world = makeWorldWithCells 5 5 3 5 10 3 cells
            stats = getStats world
        statsFish stats `shouldBe` 2
        statsSharks stats `shouldBe` 1
        statsWater stats `shouldBe` 22

      it "total equals world size" $ do
        let cells = [ ((0, 0), makeFish 3)
                    , ((1, 1), makeShark 5 10)
                    ]
            world = makeWorldWithCells 5 5 3 5 10 3 cells
            stats = getStats world
            total = statsWater stats + statsFish stats + statsSharks stats
        total `shouldBe` 25

  describe "Integration Scenarios" $ do
    it "predator-prey dynamics work" $ do
      let cells = [ ((2, 2), makeShark 5 10)
                  , ((2, 3), makeFish 3)
                  , ((3, 3), makeFish 3)
                  ]
          world = makeWorldWithCells 10 10 3 5 10 3 cells
          gen = mkStdGen 42
          (world', _) = tickWorld world gen
          stats = getStats world'
      -- Shark should eat one fish; shark count may increase if reproduced
      statsSharks stats `shouldSatisfy` (>= 1)
      statsFish stats `shouldSatisfy` (<= 2)  -- At least one fish eaten or stayed

    it "ecosystem can sustain over time" $ do
      -- Create a small ecosystem
      let cells = [ ((2, 2), makeFish 3)
                  , ((2, 3), makeFish 3)
                  , ((3, 2), makeFish 3)
                  , ((7, 7), makeShark 5 10)
                  ]
          world = makeWorldWithCells 10 10 3 5 10 3 cells
          gen = mkStdGen 42
          results = runSimulation 10 world gen
          finalStats = snd (last results)
      -- Should have some organisms remaining
      (statsFish finalStats + statsSharks finalStats) `shouldSatisfy` (> 0)
