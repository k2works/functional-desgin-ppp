import Test.Hspec

import qualified GossipingBusDriversSpec
import qualified PayrollSystemSpec
import qualified VideoRentalSystemSpec

main :: IO ()
main = hspec $ do
  describe "GossipingBusDrivers" GossipingBusDriversSpec.spec
  describe "PayrollSystem" PayrollSystemSpec.spec
  describe "VideoRentalSystem" VideoRentalSystemSpec.spec
