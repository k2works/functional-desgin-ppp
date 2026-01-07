-- |
-- Module      : WatorSimulation
-- Description : Wa-Tor predator-prey simulation
-- 
-- This module implements the Wa-Tor (Water Torus) cellular automaton
-- simulation with fish (prey) and sharks (predators).

module WatorSimulation
  ( -- * Cell Types
    Cell(..)
  , CellType(..)
  , isWater
  , isFish
  , isShark
  , cellType
  
  -- * World Types
  , World(..)
  , Location
  , Width
  , Height
  
  -- * World Construction
  , makeWorld
  , makeWorldWithCells
  , getCell
  , setCell
  
  -- * Coordinate Operations
  , wrapCoord
  , neighbors
  , neighborsOf
  
  -- * Cell Creation
  , makeWater
  , makeFish
  , makeShark
  
  -- * Simulation Rules
  , TickResult(..)
  , tickCell
  , tickWorld
  , runSimulation
  
  -- * Display
  , displayCell
  , displayWorld
  
  -- * Statistics
  , WorldStats(..)
  , getStats
  ) where

import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)
import System.Random (StdGen, randomR)

-- ============================================================
-- Cell Types
-- ============================================================

-- | Cell type discriminator
data CellType = Water | Fish | Shark
  deriving (Show, Eq, Ord)

-- | Cell in the world
data Cell
  = WaterCell
  | FishCell
    { fishAge :: Int
    , fishReproductionAge :: Int
    }
  | SharkCell
    { sharkAge :: Int
    , sharkReproductionAge :: Int
    , sharkEnergy :: Int
    }
  deriving (Show, Eq)

-- | Check if cell is water
isWater :: Cell -> Bool
isWater WaterCell = True
isWater _ = False

-- | Check if cell is fish
isFish :: Cell -> Bool
isFish (FishCell _ _) = True
isFish _ = False

-- | Check if cell is shark
isShark :: Cell -> Bool
isShark (SharkCell _ _ _) = True
isShark _ = False

-- | Get cell type
cellType :: Cell -> CellType
cellType WaterCell = Water
cellType (FishCell _ _) = Fish
cellType (SharkCell _ _ _) = Shark

-- ============================================================
-- World Types
-- ============================================================

-- | Location in the world
type Location = (Int, Int)

-- | World dimensions
type Width = Int
type Height = Int

-- | The simulation world
data World = World
  { worldWidth :: Width
  , worldHeight :: Height
  , worldCells :: Map Location Cell
  , worldFishReproAge :: Int
  , worldSharkReproAge :: Int
  , worldSharkInitialEnergy :: Int
  , worldSharkEnergyFromFish :: Int
  } deriving (Show, Eq)

-- ============================================================
-- World Construction
-- ============================================================

-- | Create an empty world (all water)
makeWorld :: Width -> Height -> Int -> Int -> Int -> Int -> World
makeWorld w h fishRepro sharkRepro sharkEnergy sharkEnergyGain = World
  { worldWidth = w
  , worldHeight = h
  , worldCells = Map.fromList [((x, y), WaterCell) | x <- [0..w-1], y <- [0..h-1]]
  , worldFishReproAge = fishRepro
  , worldSharkReproAge = sharkRepro
  , worldSharkInitialEnergy = sharkEnergy
  , worldSharkEnergyFromFish = sharkEnergyGain
  }

-- | Create world with specific cells
makeWorldWithCells :: Width -> Height -> Int -> Int -> Int -> Int -> [(Location, Cell)] -> World
makeWorldWithCells w h fishRepro sharkRepro sharkEnergy sharkEnergyGain cells =
  let baseWorld = makeWorld w h fishRepro sharkRepro sharkEnergy sharkEnergyGain
  in baseWorld { worldCells = Map.union (Map.fromList cells) (worldCells baseWorld) }

-- | Get cell at location
getCell :: World -> Location -> Cell
getCell world loc = Map.findWithDefault WaterCell (wrapCoord world loc) (worldCells world)

-- | Set cell at location
setCell :: World -> Location -> Cell -> World
setCell world loc cell = world
  { worldCells = Map.insert (wrapCoord world loc) cell (worldCells world)
  }

-- ============================================================
-- Coordinate Operations
-- ============================================================

-- | Wrap coordinates for torus topology
wrapCoord :: World -> Location -> Location
wrapCoord world (x, y) = (x `mod` worldWidth world, y `mod` worldHeight world)

-- | Get neighbor offsets
neighborOffsets :: [Location]
neighborOffsets = 
  [ (-1, -1), (0, -1), (1, -1)
  , (-1, 0),          (1, 0)
  , (-1, 1),  (0, 1),  (1, 1)
  ]

-- | Get neighbor locations
neighbors :: World -> Location -> [Location]
neighbors world (x, y) = 
  map (\(dx, dy) -> wrapCoord world (x + dx, y + dy)) neighborOffsets

-- | Get neighbors of a specific type
neighborsOf :: World -> Location -> (Cell -> Bool) -> [Location]
neighborsOf world loc predicate =
  filter (\l -> predicate (getCell world l)) (neighbors world loc)

-- ============================================================
-- Cell Creation
-- ============================================================

-- | Create water cell
makeWater :: Cell
makeWater = WaterCell

-- | Create fish cell
makeFish :: Int -> Cell
makeFish reproAge = FishCell 0 reproAge

-- | Create shark cell
makeShark :: Int -> Int -> Cell
makeShark reproAge energy = SharkCell 0 reproAge energy

-- ============================================================
-- Simulation Rules
-- ============================================================

-- | Result of ticking a cell
data TickResult
  = Stay Cell                    -- ^ Cell stays in place
  | Move Location Cell Cell      -- ^ Cell moves to location, leaving something behind
  | Die                          -- ^ Cell dies
  deriving (Show, Eq)

-- | Tick a single cell
tickCell :: World -> Location -> StdGen -> (TickResult, StdGen)
tickCell world loc gen = case getCell world loc of
  WaterCell -> (Stay WaterCell, gen)
  
  FishCell age reproAge ->
    let emptyNeighbors = neighborsOf world loc isWater
        newAge = age + 1
        canReproduce = newAge >= reproAge
    in if null emptyNeighbors
       then (Stay (FishCell newAge reproAge), gen)
       else
         let (idx, gen') = randomR (0, length emptyNeighbors - 1) gen
             moveTo = emptyNeighbors !! idx
         in if canReproduce
            then (Move moveTo (FishCell 0 reproAge) (FishCell 0 reproAge), gen')
            else (Move moveTo (FishCell newAge reproAge) WaterCell, gen')
  
  SharkCell age reproAge energy ->
    let newEnergy = energy - 1
    in if newEnergy <= 0
       then (Die, gen)
       else
         let fishNeighbors = neighborsOf world loc isFish
             emptyNeighbors = neighborsOf world loc isWater
             newAge = age + 1
             canReproduce = newAge >= reproAge
         in if not (null fishNeighbors)
            then -- Eat fish
              let (idx, gen') = randomR (0, length fishNeighbors - 1) gen
                  moveTo = fishNeighbors !! idx
                  gainedEnergy = worldSharkEnergyFromFish world
              in if canReproduce
                 then (Move moveTo (SharkCell 0 reproAge (newEnergy + gainedEnergy)) 
                                  (SharkCell 0 reproAge (worldSharkInitialEnergy world)), gen')
                 else (Move moveTo (SharkCell newAge reproAge (newEnergy + gainedEnergy)) WaterCell, gen')
            else if not (null emptyNeighbors)
            then -- Move to empty cell
              let (idx, gen') = randomR (0, length emptyNeighbors - 1) gen
                  moveTo = emptyNeighbors !! idx
              in if canReproduce
                 then (Move moveTo (SharkCell 0 reproAge newEnergy) 
                                  (SharkCell 0 reproAge (worldSharkInitialEnergy world)), gen')
                 else (Move moveTo (SharkCell newAge reproAge newEnergy) WaterCell, gen')
            else (Stay (SharkCell newAge reproAge newEnergy), gen)

-- | Apply tick result to world
applyTickResult :: World -> Location -> TickResult -> World
applyTickResult world loc result = case result of
  Stay cell -> setCell world loc cell
  Move newLoc newCell leftBehind ->
    setCell (setCell world loc leftBehind) newLoc newCell
  Die -> setCell world loc WaterCell

-- | Tick the entire world
tickWorld :: World -> StdGen -> (World, StdGen)
tickWorld world gen =
  let allLocs = [(x, y) | x <- [0..worldWidth world - 1], y <- [0..worldHeight world - 1]]
  in foldl' tickLoc (world, gen) allLocs
  where
    tickLoc (w, g) loc =
      let (result, g') = tickCell w loc g
      in (applyTickResult w loc result, g')

-- | Run simulation for n steps
runSimulation :: Int -> World -> StdGen -> [(World, WorldStats)]
runSimulation 0 _ _ = []
runSimulation n world gen =
  let (world', gen') = tickWorld world gen
      stats = getStats world'
  in (world', stats) : runSimulation (n - 1) world' gen'

-- ============================================================
-- Display
-- ============================================================

-- | Display character for a cell
displayCell :: Cell -> Char
displayCell WaterCell = '.'
displayCell (FishCell _ _) = 'f'
displayCell (SharkCell _ _ _) = 'S'

-- | Display the world as a string
displayWorld :: World -> String
displayWorld world = unlines
  [ [displayCell (getCell world (x, y)) | x <- [0..worldWidth world - 1]]
  | y <- [0..worldHeight world - 1]
  ]

-- ============================================================
-- Statistics
-- ============================================================

-- | World statistics
data WorldStats = WorldStats
  { statsWater :: Int
  , statsFish :: Int
  , statsSharks :: Int
  } deriving (Show, Eq)

-- | Get statistics for the world
getStats :: World -> WorldStats
getStats world =
  let cells = Map.elems (worldCells world)
  in WorldStats
    { statsWater = length (filter isWater cells)
    , statsFish = length (filter isFish cells)
    , statsSharks = length (filter isShark cells)
    }
