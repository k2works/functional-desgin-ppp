import Test.Hspec
import qualified DataValidationSpec
import qualified PropertyBasedTestingSpec
import qualified TddFunctionalSpec

main :: IO ()
main = hspec $ do
    describe "DataValidation" DataValidationSpec.spec
    describe "PropertyBasedTesting" PropertyBasedTestingSpec.spec
    describe "TddFunctional" TddFunctionalSpec.spec
