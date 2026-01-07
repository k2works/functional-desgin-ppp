-- |
-- Module      : ConcurrencySystem
-- Description : Concurrency System with State Machine pattern
-- 
-- This module implements a phone call state machine using STM
-- (Software Transactional Memory) for concurrent state management.

module ConcurrencySystem
  ( -- * State Types
    CallState(..)
  , Event(..)
  , Action(..)
  
  -- * State Machine
  , Transition(..)
  , StateMachine
  , phoneStateMachine
  
  -- * User Agent
  , UserAgent(..)
  , makeUserAgent
  , getUserState
  , getUserId
  , getPeer
  
  -- * State Transitions
  , sendEvent
  , sendEventWithPeer
  , processTransition
  
  -- * Actions
  , executeAction
  
  -- * Pure State Machine
  , transition
  , getTransition
  ) where

import Control.Concurrent.STM
import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)

-- ============================================================
-- State Types
-- ============================================================

-- | Call states
data CallState
  = Idle
  | Calling
  | Dialing
  | WaitingForConnection
  | Talking
  deriving (Show, Eq, Ord)

-- | Events that trigger transitions
data Event
  = Call
  | Ring
  | Dialtone
  | Ringback
  | Connected
  | Disconnect
  deriving (Show, Eq, Ord)

-- | Actions to execute on transitions
data Action
  = CallerOffHook
  | CalleeOffHook
  | Dial
  | Talk
  | NoAction
  deriving (Show, Eq)

-- ============================================================
-- State Machine
-- ============================================================

-- | A transition in the state machine
data Transition = Transition
  { transNextState :: CallState
  , transAction :: Action
  } deriving (Show, Eq)

-- | State machine: Map from (State, Event) to Transition
type StateMachine = Map (CallState, Event) Transition

-- | Phone call state machine definition
phoneStateMachine :: StateMachine
phoneStateMachine = Map.fromList
  [ ((Idle, Call), Transition Calling CallerOffHook)
  , ((Idle, Ring), Transition WaitingForConnection CalleeOffHook)
  , ((Idle, Disconnect), Transition Idle NoAction)
  , ((Calling, Dialtone), Transition Dialing Dial)
  , ((Dialing, Ringback), Transition WaitingForConnection NoAction)
  , ((WaitingForConnection, Connected), Transition Talking Talk)
  , ((Talking, Disconnect), Transition Idle NoAction)
  ]

-- | Get transition for a state and event
getTransition :: StateMachine -> CallState -> Event -> Maybe Transition
getTransition sm state event = Map.lookup (state, event) sm

-- | Pure transition function
transition :: StateMachine -> CallState -> Event -> Maybe CallState
transition sm state event = transNextState <$> getTransition sm state event

-- ============================================================
-- User Agent
-- ============================================================

-- | User agent state
data UserAgentState = UserAgentState
  { uasUserId :: String
  , uasState :: CallState
  , uasPeer :: Maybe String
  } deriving (Show, Eq)

-- | User agent with STM-based state
data UserAgent = UserAgent
  { uaState :: TVar UserAgentState
  , uaMachine :: StateMachine
  }

-- | Create a new user agent
makeUserAgent :: String -> STM UserAgent
makeUserAgent userId = do
  state <- newTVar UserAgentState
    { uasUserId = userId
    , uasState = Idle
    , uasPeer = Nothing
    }
  return UserAgent
    { uaState = state
    , uaMachine = phoneStateMachine
    }

-- | Get current state
getUserState :: UserAgent -> STM CallState
getUserState ua = uasState <$> readTVar (uaState ua)

-- | Get user ID
getUserId :: UserAgent -> STM String
getUserId ua = uasUserId <$> readTVar (uaState ua)

-- | Get peer
getPeer :: UserAgent -> STM (Maybe String)
getPeer ua = uasPeer <$> readTVar (uaState ua)

-- ============================================================
-- State Transitions
-- ============================================================

-- | Process a transition and return the action
processTransition :: UserAgent -> Event -> Maybe String -> STM (Maybe Action)
processTransition ua event peer = do
  currentState <- readTVar (uaState ua)
  case getTransition (uaMachine ua) (uasState currentState) event of
    Nothing -> return Nothing
    Just trans -> do
      writeTVar (uaState ua) currentState
        { uasState = transNextState trans
        , uasPeer = peer <|> uasPeer currentState
        }
      return (Just (transAction trans))
  where
    Nothing <|> b = b
    a <|> _ = a

-- | Send an event to a user agent
sendEvent :: UserAgent -> Event -> STM (Maybe Action)
sendEvent ua event = processTransition ua event Nothing

-- | Send an event with peer information
sendEventWithPeer :: UserAgent -> Event -> String -> STM (Maybe Action)
sendEventWithPeer ua event peer = processTransition ua event (Just peer)

-- ============================================================
-- Actions
-- ============================================================

-- | Execute an action (returns description of what happened)
executeAction :: Action -> String -> Maybe String -> String
executeAction action userId peer = case action of
  CallerOffHook -> userId ++ " picked up the phone to call " ++ peerStr
  CalleeOffHook -> userId ++ " answered the phone from " ++ peerStr
  Dial -> userId ++ " is dialing " ++ peerStr
  Talk -> userId ++ " is talking to " ++ peerStr
  NoAction -> ""
  where
    peerStr = maybe "unknown" id peer
