import Test.Hspec

import qualified StrategyPatternSpec
import qualified CommandPatternSpec
import qualified VisitorPatternSpec
import qualified AbstractFactoryPatternSpec
import qualified AbstractServerPatternSpec

main :: IO ()
main = hspec $ do
  describe "StrategyPattern" StrategyPatternSpec.spec
  describe "CommandPattern" CommandPatternSpec.spec
  describe "VisitorPattern" VisitorPatternSpec.spec
  describe "AbstractFactoryPattern" AbstractFactoryPatternSpec.spec
  describe "AbstractServerPattern" AbstractServerPatternSpec.spec
