-- |
-- Module      : AbstractServerPatternSpec
-- Description : Tests for Abstract Server pattern

module AbstractServerPatternSpec (spec) where

import Test.Hspec
import AbstractServerPattern

spec :: Spec
spec = do
  describe "Switchable Interface" $ do
    describe "Light" $ do
      it "starts in off state" $ do
        let light = makeLight "Living Room"
        isOn light `shouldBe` False
        lightName light `shouldBe` "Living Room"
      
      it "can be turned on" $ do
        let light = turnOn (makeLight "Kitchen")
        isOn light `shouldBe` True
      
      it "can be turned off" $ do
        let light = turnOff (makeLightOn "Bedroom")
        isOn light `shouldBe` False
      
      it "creates light that is on" $ do
        let light = makeLightOn "Hall"
        isOn light `shouldBe` True
    
    describe "Fan" $ do
      it "starts in off state with low speed" $ do
        let fan = makeFan "Ceiling Fan"
        isOn fan `shouldBe` False
        fanSpeed fan `shouldBe` Low
        fanName fan `shouldBe` "Ceiling Fan"
      
      it "can be turned on" $ do
        let fan = turnOn (makeFan "Desk Fan")
        isOn fan `shouldBe` True
      
      it "can change speed when on" $ do
        let fan = setFanSpeed High (turnOn (makeFan "Fan"))
        fanSpeed fan `shouldBe` High
      
      it "ignores speed change when off" $ do
        let fan = setFanSpeed High (makeFan "Fan")
        fanSpeed fan `shouldBe` Low
    
    describe "Motor" $ do
      it "starts in off state with forward direction" $ do
        let motor = makeMotor "Pump Motor"
        isOn motor `shouldBe` False
        motorDirection motor `shouldBe` Forward
        motorName motor `shouldBe` "Pump Motor"
      
      it "can be turned on" $ do
        let motor = turnOn (makeMotor "Motor")
        isOn motor `shouldBe` True
      
      it "can reverse direction when on" $ do
        let motor = reverseMotor (turnOn (makeMotor "Motor"))
        motorDirection motor `shouldBe` Reverse
      
      it "ignores reverse when off" $ do
        let motor = reverseMotor (makeMotor "Motor")
        motorDirection motor `shouldBe` Forward
      
      it "toggles direction on multiple reverses" $ do
        let motor = reverseMotor (reverseMotor (turnOn (makeMotor "Motor")))
        motorDirection motor `shouldBe` Forward

  describe "Switch Client" $ do
    describe "engage" $ do
      it "turns on a light" $ do
        let light = engage (makeLight "Test")
        isOn light `shouldBe` True
      
      it "turns on a fan" $ do
        let fan = engage (makeFan "Test")
        isOn fan `shouldBe` True
    
    describe "disengage" $ do
      it "turns off a light" $ do
        let light = disengage (makeLightOn "Test")
        isOn light `shouldBe` False
      
      it "turns off a motor" $ do
        let motor = disengage (turnOn (makeMotor "Test"))
        isOn motor `shouldBe` False
    
    describe "toggle" $ do
      it "toggles light from off to on" $ do
        let light = toggle (makeLight "Test")
        isOn light `shouldBe` True
      
      it "toggles light from on to off" $ do
        let light = toggle (makeLightOn "Test")
        isOn light `shouldBe` False
      
      it "toggles multiple times" $ do
        let light = toggle (toggle (toggle (makeLight "Test")))
        isOn light `shouldBe` True
    
    describe "switchStatus" $ do
      it "returns On for on device" $ do
        switchStatus (makeLightOn "Test") `shouldBe` On
      
      it "returns Off for off device" $ do
        switchStatus (makeLight "Test") `shouldBe` Off

  describe "Repository Interface" $ do
    describe "MemoryRepository" $ do
      it "starts empty" $ do
        let repo = makeMemoryRepo :: MemoryRepository User
        findAll repo `shouldBe` []
      
      it "saves and retrieves user" $ do
        let repo = makeMemoryRepo :: MemoryRepository User
            user = User "" "John" "john@example.com"
            (repo', savedUser) = save repo user
        entityId savedUser `shouldBe` "1"
        findById repo' "1" `shouldBe` Just savedUser
      
      it "auto-increments IDs" $ do
        let repo = makeMemoryRepo :: MemoryRepository User
            (repo', _) = save repo (User "" "John" "john@test.com")
            (repo'', user2) = save repo' (User "" "Jane" "jane@test.com")
        entityId user2 `shouldBe` "2"
        length (findAll repo'') `shouldBe` 2
      
      it "preserves existing ID" $ do
        let repo = makeMemoryRepo :: MemoryRepository User
            user = User "custom-id" "John" "john@test.com"
            (repo', savedUser) = save repo user
        entityId savedUser `shouldBe` "custom-id"
        findById repo' "custom-id" `shouldBe` Just savedUser
      
      it "deletes user" $ do
        let repo = makeMemoryRepo :: MemoryRepository User
            (repo', user) = save repo (User "" "John" "john@test.com")
            (repo'', deleted) = delete repo' (entityId user)
        deleted `shouldBe` Just user
        findAll repo'' `shouldBe` []
      
      it "returns Nothing when deleting non-existent user" $ do
        let repo = makeMemoryRepo :: MemoryRepository User
            (repo', _) = delete repo "non-existent"
        findAll repo' `shouldBe` []
    
    describe "MockRepository" $ do
      let user1 = User "1" "Alice" "alice@test.com"
          user2 = User "2" "Bob" "bob@test.com"
      
      it "returns predefined data" $ do
        let repo = makeMockRepo [user1, user2]
        findAll repo `shouldBe` [user1, user2]
      
      it "finds by ID" $ do
        let repo = makeMockRepo [user1, user2]
        findById repo "1" `shouldBe` Just user1
        findById repo "2" `shouldBe` Just user2
        findById repo "3" `shouldBe` Nothing
      
      it "adds to existing data" $ do
        let repo = makeMockRepo [user1]
            (repo', newUser) = save repo (User "" "Charlie" "charlie@test.com")
        entityId newUser `shouldBe` "2"
        length (findAll repo') `shouldBe` 2
      
      it "deletes from data" $ do
        let repo = makeMockRepo [user1, user2]
            (repo', deleted) = delete repo "1"
        deleted `shouldBe` Just user1
        findAll repo' `shouldBe` [user2]

  describe "User Service" $ do
    it "creates user with repository" $ do
      let repo = makeMemoryRepo :: MemoryRepository User
          (repo', user) = createUser repo "John" "john@test.com"
      userName user `shouldBe` "John"
      userEmail user `shouldBe` "john@test.com"
      length (getAllUsers repo') `shouldBe` 1
    
    it "gets user by ID" $ do
      let repo = makeMemoryRepo :: MemoryRepository User
          (repo', user) = createUser repo "John" "john@test.com"
      getUser repo' (entityId user) `shouldBe` Just user
    
    it "gets all users" $ do
      let repo = makeMemoryRepo :: MemoryRepository User
          (repo', _) = createUser repo "John" "john@test.com"
          (repo'', _) = createUser repo' "Jane" "jane@test.com"
      length (getAllUsers repo'') `shouldBe` 2
    
    it "deletes user" $ do
      let repo = makeMemoryRepo :: MemoryRepository User
          (repo', user) = createUser repo "John" "john@test.com"
          (repo'', deleted) = deleteUser repo' (entityId user)
      deleted `shouldBe` Just user
      getAllUsers repo'' `shouldBe` []

  describe "Logger Interface" $ do
    describe "ConsoleLogger" $ do
      it "logs message at or above minimum level" $ do
        let logger = ConsoleLogger Info
            (_, output) = logMessage logger Info "Test message"
        output `shouldBe` "[Info] Test message"
      
      it "logs at higher levels" $ do
        let logger = ConsoleLogger Info
            (_, output) = logMessage logger Error "Error occurred"
        output `shouldBe` "[Error] Error occurred"
      
      it "ignores messages below minimum level" $ do
        let logger = ConsoleLogger Warning
            (_, output) = logMessage logger Info "Info message"
        output `shouldBe` ""
      
      it "logs debug when minimum is debug" $ do
        let logger = ConsoleLogger Debug
            (_, output) = logMessage logger Debug "Debug info"
        output `shouldBe` "[Debug] Debug info"
    
    describe "NullLogger" $ do
      it "discards all messages" $ do
        let (_, output1) = logMessage NullLogger Debug "Debug"
            (_, output2) = logMessage NullLogger Error "Error"
        output1 `shouldBe` ""
        output2 `shouldBe` ""
    
    describe "FileLogger" $ do
      it "stores messages" $ do
        let logger = makeFileLogger "/var/log/app.log"
            (logger', _) = logMessage logger Info "First message"
            (logger'', _) = logMessage logger' Warning "Second message"
        flMessages logger'' `shouldBe` 
          ["[Info] First message", "[Warning] Second message"]
      
      it "preserves path" $ do
        let logger = makeFileLogger "/var/log/test.log"
        flPath logger `shouldBe` "/var/log/test.log"
      
      it "returns formatted message" $ do
        let logger = makeFileLogger "test.log"
            (_, output) = logMessage logger Error "Something failed"
        output `shouldBe` "[Error] Something failed"
