import Test.Hspec
import qualified ImmutabilitySpec
import qualified FunctionCompositionSpec
import qualified PolymorphismSpec

main :: IO ()
main = hspec $ do
    describe "Immutability" ImmutabilitySpec.spec
    describe "FunctionComposition" FunctionCompositionSpec.spec
    describe "Polymorphism" PolymorphismSpec.spec
