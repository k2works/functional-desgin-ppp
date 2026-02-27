-- |
-- Module      : PayrollSystemSpec
-- Description : Tests for Payroll System

module PayrollSystemSpec (spec) where

import Test.Hspec
import qualified Data.Map.Strict as Map
import Data.Time.Calendar (fromGregorian)
import PayrollSystem

spec :: Spec
spec = do
  describe "Employee Construction" $ do
    describe "makeSalariedEmployee" $ do
      it "creates salaried employee" $ do
        let emp = makeSalariedEmployee "E001" "John Doe" 5000
        employeeName emp `shouldBe` "John Doe"
        employeePayClass emp `shouldBe` Salaried 5000
        employeeSchedule emp `shouldBe` Monthly
    
    describe "makeHourlyEmployee" $ do
      it "creates hourly employee" $ do
        let emp = makeHourlyEmployee "E002" "Jane Smith" 25.0
        employeeName emp `shouldBe` "Jane Smith"
        employeePayClass emp `shouldBe` Hourly 25.0
        employeeSchedule emp `shouldBe` Weekly
    
    describe "makeCommissionedEmployee" $ do
      it "creates commissioned employee" $ do
        let emp = makeCommissionedEmployee "E003" "Bob Wilson" 1500 0.10
        employeeName emp `shouldBe` "Bob Wilson"
        employeePayClass emp `shouldBe` Commissioned 1500 0.10
        employeeSchedule emp `shouldBe` BiWeekly

  describe "Time Cards and Sales" $ do
    describe "emptyContext" $ do
      it "creates context with no time cards or sales" $ do
        let ctx = emptyContext (fromGregorian 2026 1 7)
        Map.null (ctxTimeCards ctx) `shouldBe` True
        Map.null (ctxSalesReceipts ctx) `shouldBe` True
    
    describe "addTimeCard" $ do
      it "adds time card to context" $ do
        let ctx = emptyContext (fromGregorian 2026 1 7)
            tc = TimeCard (fromGregorian 2026 1 6) 8.0
            ctx' = addTimeCard "E001" tc ctx
        Map.lookup "E001" (ctxTimeCards ctx') `shouldBe` Just [tc]
      
      it "accumulates time cards" $ do
        let ctx = emptyContext (fromGregorian 2026 1 7)
            tc1 = TimeCard (fromGregorian 2026 1 5) 8.0
            tc2 = TimeCard (fromGregorian 2026 1 6) 9.0
            ctx' = addTimeCard "E001" tc2 (addTimeCard "E001" tc1 ctx)
        length <$> Map.lookup "E001" (ctxTimeCards ctx') `shouldBe` Just 2
    
    describe "addSalesReceipt" $ do
      it "adds sales receipt to context" $ do
        let ctx = emptyContext (fromGregorian 2026 1 7)
            sr = SalesReceipt (fromGregorian 2026 1 6) 1000.0
            ctx' = addSalesReceipt "E001" sr ctx
        Map.lookup "E001" (ctxSalesReceipts ctx') `shouldBe` Just [sr]

  describe "Pay Calculation" $ do
    describe "calculatePay" $ do
      describe "Salaried Employee" $ do
        it "returns fixed salary" $ do
          let emp = makeSalariedEmployee "E001" "John" 5000
              ctx = emptyContext (fromGregorian 2026 1 31)
          calculatePay emp ctx `shouldBe` 5000
      
      describe "Hourly Employee" $ do
        it "calculates regular pay" $ do
          let emp = makeHourlyEmployee "E001" "Jane" 20.0
              ctx = emptyContext (fromGregorian 2026 1 7)
              tc1 = TimeCard (fromGregorian 2026 1 5) 8.0
              tc2 = TimeCard (fromGregorian 2026 1 6) 8.0
              ctx' = addTimeCard "E001" tc2 (addTimeCard "E001" tc1 ctx)
          calculatePay emp ctx' `shouldBe` 320.0  -- 16 hours * $20
        
        it "calculates overtime pay" $ do
          let emp = makeHourlyEmployee "E001" "Jane" 20.0
              ctx = emptyContext (fromGregorian 2026 1 7)
              -- 50 hours total: 40 regular + 10 overtime
              cards = [TimeCard (fromGregorian 2026 1 d) 10.0 | d <- [1..5]]
              ctx' = foldr (addTimeCard "E001") ctx cards
          -- 40 * 20 + 10 * 20 * 1.5 = 800 + 300 = 1100
          calculatePay emp ctx' `shouldBe` 1100.0
        
        it "returns 0 with no time cards" $ do
          let emp = makeHourlyEmployee "E001" "Jane" 20.0
              ctx = emptyContext (fromGregorian 2026 1 7)
          calculatePay emp ctx `shouldBe` 0.0
      
      describe "Commissioned Employee" $ do
        it "calculates base pay with no sales" $ do
          let emp = makeCommissionedEmployee "E001" "Bob" 1500 0.10
              ctx = emptyContext (fromGregorian 2026 1 14)
          calculatePay emp ctx `shouldBe` 1500.0
        
        it "calculates pay with sales commission" $ do
          let emp = makeCommissionedEmployee "E001" "Bob" 1500 0.10
              ctx = emptyContext (fromGregorian 2026 1 14)
              sr1 = SalesReceipt (fromGregorian 2026 1 10) 5000.0
              sr2 = SalesReceipt (fromGregorian 2026 1 12) 3000.0
              ctx' = addSalesReceipt "E001" sr2 (addSalesReceipt "E001" sr1 ctx)
          -- 1500 + (5000 + 3000) * 0.10 = 1500 + 800 = 2300
          calculatePay emp ctx' `shouldBe` 2300.0
    
    describe "calculateHourlyPay" $ do
      it "calculates regular hours only" $ do
        let cards = [TimeCard (fromGregorian 2026 1 1) 30.0]
        calculateHourlyPay 10.0 cards `shouldBe` 300.0
      
      it "calculates with overtime" $ do
        let cards = [TimeCard (fromGregorian 2026 1 1) 45.0]
        -- 40 * 10 + 5 * 10 * 1.5 = 400 + 75 = 475
        calculateHourlyPay 10.0 cards `shouldBe` 475.0
      
      it "handles empty cards" $ do
        calculateHourlyPay 10.0 [] `shouldBe` 0.0
    
    describe "calculateCommissionedPay" $ do
      it "calculates base plus commission" $ do
        let receipts = [SalesReceipt (fromGregorian 2026 1 1) 10000.0]
        -- 2000 + 10000 * 0.05 = 2000 + 500 = 2500
        calculateCommissionedPay 2000.0 0.05 receipts `shouldBe` 2500.0
      
      it "returns base with no receipts" $ do
        calculateCommissionedPay 2000.0 0.05 [] `shouldBe` 2000.0

  describe "Payroll Processing" $ do
    describe "processEmployee" $ do
      it "creates pay check" $ do
        let emp = makeSalariedEmployee "E001" "John Doe" 5000
            ctx = emptyContext (fromGregorian 2026 1 31)
            check = processEmployee emp ctx
        checkEmployeeId check `shouldBe` "E001"
        checkEmployeeName check `shouldBe` "John Doe"
        checkAmount check `shouldBe` 5000
        checkMethod check `shouldBe` Hold
    
    describe "runPayroll" $ do
      it "processes all employees" $ do
        let emp1 = makeSalariedEmployee "E001" "John" 5000
            emp2 = makeSalariedEmployee "E002" "Jane" 6000
            ctx = emptyContext (fromGregorian 2026 1 31)
            checks = runPayroll [emp1, emp2] ctx
        length checks `shouldBe` 2
        sum (map checkAmount checks) `shouldBe` 11000
