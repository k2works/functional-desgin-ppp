-- |
-- Module      : PayrollSystem
-- Description : Payroll System case study implementation
-- 
-- This module implements a payroll system with different employee types:
-- - Salaried: fixed monthly salary
-- - Hourly: paid by the hour with overtime
-- - Commissioned: base pay plus sales commission

module PayrollSystem
  ( -- * Employee Types
    EmployeeId
  , PayClass(..)
  , PaySchedule(..)
  , PaymentMethod(..)
  , Employee(..)
  
  -- * Employee Construction
  , makeSalariedEmployee
  , makeHourlyEmployee
  , makeCommissionedEmployee
  
  -- * Time Cards and Sales
  , TimeCard(..)
  , SalesReceipt(..)
  , PayContext(..)
  , emptyContext
  , addTimeCard
  , addSalesReceipt
  
  -- * Pay Calculation
  , calculatePay
  , calculateHourlyPay
  , calculateCommissionedPay
  
  -- * Payroll Processing
  , PayCheck(..)
  , runPayroll
  , processEmployee
  ) where

import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)
import Data.Time.Calendar (Day)

-- ============================================================
-- Types
-- ============================================================

-- | Employee identifier
type EmployeeId = String

-- | Pay classification determines how pay is calculated
data PayClass
  = Salaried Double                    -- ^ Fixed salary
  | Hourly Double                      -- ^ Hourly rate
  | Commissioned Double Double         -- ^ Base pay, commission rate
  deriving (Show, Eq)

-- | Payment schedule
data PaySchedule
  = Monthly    -- ^ Paid monthly (last day of month)
  | Weekly     -- ^ Paid weekly (every Friday)
  | BiWeekly   -- ^ Paid every two weeks
  deriving (Show, Eq)

-- | Payment method
data PaymentMethod
  = Hold            -- ^ Hold for pickup
  | DirectDeposit String  -- ^ Direct deposit to account
  | Mail String     -- ^ Mail to address
  deriving (Show, Eq)

-- | Employee record
data Employee = Employee
  { employeeId :: EmployeeId
  , employeeName :: String
  , employeePayClass :: PayClass
  , employeeSchedule :: PaySchedule
  , employeePaymentMethod :: PaymentMethod
  } deriving (Show, Eq)

-- ============================================================
-- Employee Construction
-- ============================================================

-- | Create a salaried employee
makeSalariedEmployee :: EmployeeId -> String -> Double -> Employee
makeSalariedEmployee eid name salary = Employee
  { employeeId = eid
  , employeeName = name
  , employeePayClass = Salaried salary
  , employeeSchedule = Monthly
  , employeePaymentMethod = Hold
  }

-- | Create an hourly employee
makeHourlyEmployee :: EmployeeId -> String -> Double -> Employee
makeHourlyEmployee eid name hourlyRate = Employee
  { employeeId = eid
  , employeeName = name
  , employeePayClass = Hourly hourlyRate
  , employeeSchedule = Weekly
  , employeePaymentMethod = Hold
  }

-- | Create a commissioned employee
makeCommissionedEmployee :: EmployeeId -> String -> Double -> Double -> Employee
makeCommissionedEmployee eid name basePay commissionRate = Employee
  { employeeId = eid
  , employeeName = name
  , employeePayClass = Commissioned basePay commissionRate
  , employeeSchedule = BiWeekly
  , employeePaymentMethod = Hold
  }

-- ============================================================
-- Time Cards and Sales
-- ============================================================

-- | Time card for hourly employees
data TimeCard = TimeCard
  { tcDate :: Day
  , tcHours :: Double
  } deriving (Show, Eq)

-- | Sales receipt for commissioned employees
data SalesReceipt = SalesReceipt
  { srDate :: Day
  , srAmount :: Double
  } deriving (Show, Eq)

-- | Context for pay calculation (time cards, sales receipts)
data PayContext = PayContext
  { ctxTimeCards :: Map EmployeeId [TimeCard]
  , ctxSalesReceipts :: Map EmployeeId [SalesReceipt]
  , ctxPayDate :: Day
  } deriving (Show, Eq)

-- | Create an empty context
emptyContext :: Day -> PayContext
emptyContext payDate = PayContext
  { ctxTimeCards = Map.empty
  , ctxSalesReceipts = Map.empty
  , ctxPayDate = payDate
  }

-- | Add a time card for an employee
addTimeCard :: EmployeeId -> TimeCard -> PayContext -> PayContext
addTimeCard eid tc ctx = ctx
  { ctxTimeCards = Map.insertWith (++) eid [tc] (ctxTimeCards ctx)
  }

-- | Add a sales receipt for an employee
addSalesReceipt :: EmployeeId -> SalesReceipt -> PayContext -> PayContext
addSalesReceipt eid sr ctx = ctx
  { ctxSalesReceipts = Map.insertWith (++) eid [sr] (ctxSalesReceipts ctx)
  }

-- ============================================================
-- Pay Calculation
-- ============================================================

-- | Calculate pay for an employee
calculatePay :: Employee -> PayContext -> Double
calculatePay emp ctx = case employeePayClass emp of
  Salaried salary -> salary
  Hourly rate -> calculateHourlyPay rate (getTimeCards emp ctx)
  Commissioned basePay commRate -> calculateCommissionedPay basePay commRate (getSalesReceipts emp ctx)

-- | Get time cards for an employee
getTimeCards :: Employee -> PayContext -> [TimeCard]
getTimeCards emp ctx = Map.findWithDefault [] (employeeId emp) (ctxTimeCards ctx)

-- | Get sales receipts for an employee
getSalesReceipts :: Employee -> PayContext -> [SalesReceipt]
getSalesReceipts emp ctx = Map.findWithDefault [] (employeeId emp) (ctxSalesReceipts ctx)

-- | Calculate hourly pay with overtime (1.5x for hours over 40)
calculateHourlyPay :: Double -> [TimeCard] -> Double
calculateHourlyPay rate cards =
  let totalHours = sum (map tcHours cards)
      regularHours = min totalHours 40
      overtimeHours = max 0 (totalHours - 40)
  in regularHours * rate + overtimeHours * rate * 1.5

-- | Calculate commissioned pay
calculateCommissionedPay :: Double -> Double -> [SalesReceipt] -> Double
calculateCommissionedPay basePay commRate receipts =
  let totalSales = sum (map srAmount receipts)
  in basePay + totalSales * commRate

-- ============================================================
-- Payroll Processing
-- ============================================================

-- | Pay check issued to an employee
data PayCheck = PayCheck
  { checkEmployeeId :: EmployeeId
  , checkEmployeeName :: String
  , checkAmount :: Double
  , checkMethod :: PaymentMethod
  } deriving (Show, Eq)

-- | Process a single employee
processEmployee :: Employee -> PayContext -> PayCheck
processEmployee emp ctx = PayCheck
  { checkEmployeeId = employeeId emp
  , checkEmployeeName = employeeName emp
  , checkAmount = calculatePay emp ctx
  , checkMethod = employeePaymentMethod emp
  }

-- | Run payroll for all employees
runPayroll :: [Employee] -> PayContext -> [PayCheck]
runPayroll employees ctx = map (`processEmployee` ctx) employees
