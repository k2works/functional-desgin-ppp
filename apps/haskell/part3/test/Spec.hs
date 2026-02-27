import Test.Hspec

import qualified CompositePatternSpec
import qualified DecoratorPatternSpec
import qualified AdapterPatternSpec

main :: IO ()
main = hspec $ do
  describe "CompositePattern" CompositePatternSpec.spec
  describe "DecoratorPattern" DecoratorPatternSpec.spec
  describe "AdapterPattern" AdapterPatternSpec.spec
