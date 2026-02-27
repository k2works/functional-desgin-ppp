-- |
-- Module      : GossipingBusDrivers
-- Description : Gossiping Bus Drivers problem implementation
-- 
-- This module implements the "Gossiping Bus Drivers" problem:
-- Multiple bus drivers travel their routes. When they meet at a stop,
-- they share all their gossip. The goal is to find how many minutes
-- it takes for all drivers to know all the gossip.

module GossipingBusDrivers
  ( -- * Types
    Driver(..)
  , World
  , Stop
  , Gossip
  
  -- * Driver Construction
  , makeDriver
  , makeDrivers
  
  -- * Simulation
  , currentStop
  , moveDriver
  , moveDrivers
  , driversAtStops
  , mergeGossip
  , spreadGossip
  , drive
  
  -- * Completion Check
  , allGossipShared
  , totalGossip
  
  -- * Main Solver
  , solve
  , solveWithLimit
  ) where

import qualified Data.Set as Set
import Data.Set (Set)
import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)

-- ============================================================
-- Types
-- ============================================================

-- | A stop identifier
type Stop = Int

-- | A gossip piece (unique per driver)
type Gossip = Int

-- | A bus driver with their route and known gossip
data Driver = Driver
  { driverId :: Int
  , driverRoute :: [Stop]     -- ^ Infinite cyclic route
  , driverGossip :: Set Gossip
  } deriving (Show, Eq)

-- | The world state is a list of drivers
type World = [Driver]

-- ============================================================
-- Driver Construction
-- ============================================================

-- | Create a driver with a route (cycles infinitely) and initial gossip
makeDriver :: Int -> [Stop] -> Driver
makeDriver dId route = Driver
  { driverId = dId
  , driverRoute = cycle route
  , driverGossip = Set.singleton dId
  }

-- | Create multiple drivers from routes
makeDrivers :: [[Stop]] -> [Driver]
makeDrivers routes = zipWith makeDriver [0..] routes

-- ============================================================
-- Simulation
-- ============================================================

-- | Get the current stop of a driver
currentStop :: Driver -> Stop
currentStop driver = head (driverRoute driver)

-- | Move a driver to their next stop
moveDriver :: Driver -> Driver
moveDriver driver = driver { driverRoute = tail (driverRoute driver) }

-- | Move all drivers to their next stops
moveDrivers :: World -> World
moveDrivers = map moveDriver

-- | Group drivers by their current stop
driversAtStops :: World -> Map Stop [Driver]
driversAtStops = foldr addDriver Map.empty
  where
    addDriver driver acc = 
      let stop = currentStop driver
      in Map.insertWith (++) stop [driver] acc

-- | Merge gossip among a group of drivers
mergeGossip :: [Driver] -> [Driver]
mergeGossip drivers =
  let allGossips = Set.unions (map driverGossip drivers)
  in map (\d -> d { driverGossip = allGossips }) drivers

-- | Spread gossip at all stops
spreadGossip :: World -> World
spreadGossip world =
  let byStop = driversAtStops world
      merged = Map.map mergeGossip byStop
  in concatMap snd (Map.toList merged)

-- | One step of simulation: move then spread gossip
drive :: World -> World
drive = spreadGossip . moveDrivers

-- ============================================================
-- Completion Check
-- ============================================================

-- | Check if all drivers know all gossip
allGossipShared :: World -> Bool
allGossipShared [] = True
allGossipShared (d:ds) = all (\driver -> driverGossip driver == driverGossip d) ds

-- | Get the total set of all gossip in the world
totalGossip :: World -> Set Gossip
totalGossip = Set.unions . map driverGossip

-- ============================================================
-- Main Solver
-- ============================================================

-- | Solve the problem: find minutes until all gossip is shared
-- Returns Nothing if it takes more than 480 minutes (8 hours)
solve :: [[Stop]] -> Maybe Int
solve = solveWithLimit 480

-- | Solve with a custom time limit
solveWithLimit :: Int -> [[Stop]] -> Maybe Int
solveWithLimit limit routes = go 0 (makeDrivers routes)
  where
    go minutes world
      | minutes > limit = Nothing
      | allGossipShared world = Just minutes
      | otherwise = go (minutes + 1) (drive world)
