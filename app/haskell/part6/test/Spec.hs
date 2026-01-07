module Main where

import Test.Hspec

import qualified ConcurrencySystemSpec
import qualified WatorSimulationSpec

main :: IO ()
main = hspec $ do
  describe "ConcurrencySystem" ConcurrencySystemSpec.spec
  describe "WatorSimulation" WatorSimulationSpec.spec
