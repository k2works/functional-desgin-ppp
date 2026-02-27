module Main where

import Test.Hspec

import qualified PatternInteractionsSpec
import qualified BestPracticesSpec
import qualified OOtoFPMigrationSpec

main :: IO ()
main = hspec $ do
  describe "PatternInteractions" PatternInteractionsSpec.spec
  describe "BestPractices" BestPracticesSpec.spec
  describe "OOtoFPMigration" OOtoFPMigrationSpec.spec
