(ns payroll.employee
  "給与計算システム - 従業員モデル

   従業員の基本情報と給与計算のための
   データ構造を定義します。"
  (:require [clojure.spec.alpha :as s]))

;; =============================================================================
;; 仕様定義
;; =============================================================================

(s/def ::id string?)
(s/def ::name string?)
(s/def ::address string?)

;; 給与分類
(s/def ::salary number?)
(s/def ::hourly-rate number?)
(s/def ::base-pay number?)
(s/def ::commission-rate number?)

(s/def ::pay-class
  (s/or :salaried (s/tuple #{:salaried} ::salary)
        :hourly (s/tuple #{:hourly} ::hourly-rate)
        :commissioned (s/tuple #{:commissioned} ::base-pay ::commission-rate)))

;; 支払いスケジュール
(s/def ::schedule #{:monthly :weekly :biweekly})

;; 支払い方法
(s/def ::payment-method #{:hold :direct-deposit :mail})

;; 従業員
(s/def ::employee
  (s/keys :req [::id ::name ::pay-class ::schedule ::payment-method]
          :opt [::address]))

;; =============================================================================
;; コンストラクタ
;; =============================================================================

(defn make-salaried-employee
  "月給制従業員を作成"
  [id name salary]
  {::id id
   ::name name
   ::pay-class [:salaried salary]
   ::schedule :monthly
   ::payment-method :hold})

(defn make-hourly-employee
  "時給制従業員を作成"
  [id name hourly-rate]
  {::id id
   ::name name
   ::pay-class [:hourly hourly-rate]
   ::schedule :weekly
   ::payment-method :hold})

(defn make-commissioned-employee
  "歩合制従業員を作成"
  [id name base-pay commission-rate]
  {::id id
   ::name name
   ::pay-class [:commissioned base-pay commission-rate]
   ::schedule :biweekly
   ::payment-method :hold})

;; =============================================================================
;; アクセサ
;; =============================================================================

(defn get-id [employee]
  (::id employee))

(defn get-name [employee]
  (::name employee))

(defn get-pay-class [employee]
  (::pay-class employee))

(defn get-pay-type [employee]
  (first (::pay-class employee)))

(defn get-schedule [employee]
  (::schedule employee))

(defn get-payment-method [employee]
  (::payment-method employee))

;; =============================================================================
;; 更新
;; =============================================================================

(defn set-address [employee address]
  (assoc employee ::address address))

(defn set-payment-method [employee method]
  (assoc employee ::payment-method method))
