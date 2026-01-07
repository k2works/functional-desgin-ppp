module ConcurrencySystemSpec (spec) where

import Test.Hspec
import Control.Concurrent.STM

import ConcurrencySystem

spec :: Spec
spec = do
  describe "CallState" $ do
    it "has distinct state values" $ do
      Idle `shouldNotBe` Calling
      Calling `shouldNotBe` Dialing
      Dialing `shouldNotBe` WaitingForConnection
      WaitingForConnection `shouldNotBe` Talking

    it "shows state values" $ do
      show Idle `shouldBe` "Idle"
      show Calling `shouldBe` "Calling"
      show Talking `shouldBe` "Talking"

  describe "Event" $ do
    it "has distinct event values" $ do
      Call `shouldNotBe` Ring
      Dialtone `shouldNotBe` Ringback
      Connected `shouldNotBe` Disconnect

    it "shows event values" $ do
      show Call `shouldBe` "Call"
      show Ring `shouldBe` "Ring"
      show Connected `shouldBe` "Connected"

  describe "Action" $ do
    it "has action values" $ do
      show CallerOffHook `shouldBe` "CallerOffHook"
      show CalleeOffHook `shouldBe` "CalleeOffHook"
      show Dial `shouldBe` "Dial"
      show Talk `shouldBe` "Talk"
      show NoAction `shouldBe` "NoAction"

  describe "Pure State Machine" $ do
    describe "transition" $ do
      it "transitions from Idle to Calling on Call event" $ do
        transition phoneStateMachine Idle Call `shouldBe` Just Calling

      it "transitions from Idle to WaitingForConnection on Ring event" $ do
        transition phoneStateMachine Idle Ring `shouldBe` Just WaitingForConnection

      it "stays Idle on Disconnect when already Idle" $ do
        transition phoneStateMachine Idle Disconnect `shouldBe` Just Idle

      it "transitions from Calling to Dialing on Dialtone" $ do
        transition phoneStateMachine Calling Dialtone `shouldBe` Just Dialing

      it "transitions from Dialing to WaitingForConnection on Ringback" $ do
        transition phoneStateMachine Dialing Ringback `shouldBe` Just WaitingForConnection

      it "transitions from WaitingForConnection to Talking on Connected" $ do
        transition phoneStateMachine WaitingForConnection Connected `shouldBe` Just Talking

      it "transitions from Talking to Idle on Disconnect" $ do
        transition phoneStateMachine Talking Disconnect `shouldBe` Just Idle

      it "returns Nothing for invalid transitions" $ do
        transition phoneStateMachine Idle Dialtone `shouldBe` Nothing
        transition phoneStateMachine Calling Call `shouldBe` Nothing
        transition phoneStateMachine Dialing Connected `shouldBe` Nothing

    describe "getTransition" $ do
      it "returns transition with action for Idle -> Call" $ do
        let trans = getTransition phoneStateMachine Idle Call
        fmap transNextState trans `shouldBe` Just Calling
        fmap transAction trans `shouldBe` Just CallerOffHook

      it "returns transition with action for Idle -> Ring" $ do
        let trans = getTransition phoneStateMachine Idle Ring
        fmap transNextState trans `shouldBe` Just WaitingForConnection
        fmap transAction trans `shouldBe` Just CalleeOffHook

      it "returns transition with action for Calling -> Dialtone" $ do
        let trans = getTransition phoneStateMachine Calling Dialtone
        fmap transNextState trans `shouldBe` Just Dialing
        fmap transAction trans `shouldBe` Just Dial

      it "returns transition with action for WaitingForConnection -> Connected" $ do
        let trans = getTransition phoneStateMachine WaitingForConnection Connected
        fmap transNextState trans `shouldBe` Just Talking
        fmap transAction trans `shouldBe` Just Talk

      it "returns transition with NoAction for Talking -> Disconnect" $ do
        let trans = getTransition phoneStateMachine Talking Disconnect
        fmap transNextState trans `shouldBe` Just Idle
        fmap transAction trans `shouldBe` Just NoAction

  describe "UserAgent (STM)" $ do
    describe "makeUserAgent" $ do
      it "creates agent in Idle state" $ do
        state <- atomically $ do
          ua <- makeUserAgent "alice"
          getUserState ua
        state `shouldBe` Idle

      it "stores user ID" $ do
        userId <- atomically $ do
          ua <- makeUserAgent "bob"
          getUserId ua
        userId `shouldBe` "bob"

      it "starts with no peer" $ do
        peer <- atomically $ do
          ua <- makeUserAgent "charlie"
          getPeer ua
        peer `shouldBe` Nothing

    describe "sendEvent" $ do
      it "transitions from Idle to Calling" $ do
        (action, state) <- atomically $ do
          ua <- makeUserAgent "alice"
          action <- sendEvent ua Call
          state <- getUserState ua
          return (action, state)
        action `shouldBe` Just CallerOffHook
        state `shouldBe` Calling

      it "transitions through full caller flow" $ do
        (states, actions) <- atomically $ do
          ua <- makeUserAgent "alice"
          
          a1 <- sendEvent ua Call
          s1 <- getUserState ua
          
          a2 <- sendEvent ua Dialtone
          s2 <- getUserState ua
          
          a3 <- sendEvent ua Ringback
          s3 <- getUserState ua
          
          a4 <- sendEvent ua Connected
          s4 <- getUserState ua
          
          a5 <- sendEvent ua Disconnect
          s5 <- getUserState ua
          
          return ([s1, s2, s3, s4, s5], [a1, a2, a3, a4, a5])
        
        states `shouldBe` [Calling, Dialing, WaitingForConnection, Talking, Idle]
        actions `shouldBe` [Just CallerOffHook, Just Dial, Just NoAction, Just Talk, Just NoAction]

      it "transitions through callee flow" $ do
        (states, actions) <- atomically $ do
          ua <- makeUserAgent "bob"
          
          a1 <- sendEvent ua Ring
          s1 <- getUserState ua
          
          a2 <- sendEvent ua Connected
          s2 <- getUserState ua
          
          a3 <- sendEvent ua Disconnect
          s3 <- getUserState ua
          
          return ([s1, s2, s3], [a1, a2, a3])
        
        states `shouldBe` [WaitingForConnection, Talking, Idle]
        actions `shouldBe` [Just CalleeOffHook, Just Talk, Just NoAction]

      it "returns Nothing for invalid transition" $ do
        action <- atomically $ do
          ua <- makeUserAgent "alice"
          sendEvent ua Dialtone  -- Invalid: should be in Calling state first
        action `shouldBe` Nothing

    describe "sendEventWithPeer" $ do
      it "stores peer information" $ do
        (peer, state) <- atomically $ do
          ua <- makeUserAgent "alice"
          _ <- sendEventWithPeer ua Call "bob"
          peer <- getPeer ua
          state <- getUserState ua
          return (peer, state)
        peer `shouldBe` Just "bob"
        state `shouldBe` Calling

      it "preserves peer through transitions" $ do
        peer <- atomically $ do
          ua <- makeUserAgent "alice"
          _ <- sendEventWithPeer ua Call "bob"
          _ <- sendEvent ua Dialtone
          _ <- sendEvent ua Ringback
          _ <- sendEvent ua Connected
          getPeer ua
        peer `shouldBe` Just "bob"

  describe "executeAction" $ do
    it "describes CallerOffHook action" $ do
      let msg = executeAction CallerOffHook "alice" (Just "bob")
      msg `shouldBe` "alice picked up the phone to call bob"

    it "describes CalleeOffHook action" $ do
      let msg = executeAction CalleeOffHook "bob" (Just "alice")
      msg `shouldBe` "bob answered the phone from alice"

    it "describes Dial action" $ do
      let msg = executeAction Dial "alice" (Just "bob")
      msg `shouldBe` "alice is dialing bob"

    it "describes Talk action" $ do
      let msg = executeAction Talk "alice" (Just "bob")
      msg `shouldBe` "alice is talking to bob"

    it "returns empty string for NoAction" $ do
      let msg = executeAction NoAction "alice" Nothing
      msg `shouldBe` ""

    it "handles missing peer" $ do
      let msg = executeAction CallerOffHook "alice" Nothing
      msg `shouldBe` "alice picked up the phone to call unknown"

  describe "Concurrent State Updates" $ do
    it "handles multiple agents independently" $ do
      (aliceState, bobState) <- atomically $ do
        alice <- makeUserAgent "alice"
        bob <- makeUserAgent "bob"
        
        _ <- sendEvent alice Call
        _ <- sendEvent bob Ring
        
        as <- getUserState alice
        bs <- getUserState bob
        return (as, bs)
      
      aliceState `shouldBe` Calling
      bobState `shouldBe` WaitingForConnection

    it "maintains consistency across transactions" $ do
      finalState <- atomically $ do
        ua <- makeUserAgent "test"
        _ <- sendEvent ua Call
        _ <- sendEvent ua Dialtone
        _ <- sendEvent ua Ringback
        _ <- sendEvent ua Connected
        getUserState ua
      finalState `shouldBe` Talking
