(ns oo-to-fp.oo-style
  "オブジェクト指向スタイルのコード例
   これらは移行前の状態を示すための参考コード")

;; ============================================
;; OOスタイル: クラスとメソッドをシミュレート
;; ============================================

;; オブジェクト指向での銀行口座
(defn make-account-oo
  "OOスタイル: 口座オブジェクトを作成
   内部状態を持ち、メソッドを通じてアクセス"
  [id initial-balance]
  (let [state (atom {:id id
                     :balance initial-balance
                     :transactions []})]
    ;; メソッドをマップとして返す
    {:get-id (fn [] (:id @state))
     :get-balance (fn [] (:balance @state))
     :get-transactions (fn [] (:transactions @state))
     :deposit (fn [amount]
                (when (pos? amount)
                  (swap! state
                         (fn [s]
                           (-> s
                               (update :balance + amount)
                               (update :transactions conj
                                       {:type :deposit
                                        :amount amount
                                        :timestamp (System/currentTimeMillis)}))))
                  (:balance @state)))
     :withdraw (fn [amount]
                 (when (and (pos? amount)
                            (>= (:balance @state) amount))
                   (swap! state
                          (fn [s]
                            (-> s
                                (update :balance - amount)
                                (update :transactions conj
                                        {:type :withdrawal
                                         :amount amount
                                         :timestamp (System/currentTimeMillis)}))))
                   (:balance @state)))}))

;; OOスタイルの使用例
;; (def acc (make-account-oo "A001" 1000))
;; ((:deposit acc) 500)   ;; => 1500
;; ((:withdraw acc) 200)  ;; => 1300
;; ((:get-balance acc))   ;; => 1300

;; ============================================
;; OOスタイル: 継承をシミュレート
;; ============================================

(defn make-shape-oo
  "OOスタイル: 基底図形クラス"
  [x y]
  (let [state (atom {:x x :y y})]
    {:get-x (fn [] (:x @state))
     :get-y (fn [] (:y @state))
     :move (fn [dx dy]
             (swap! state update :x + dx)
             (swap! state update :y + dy))}))

(defn make-circle-oo
  "OOスタイル: 円クラス（継承をシミュレート）"
  [x y radius]
  (let [base (make-shape-oo x y)
        radius-state (atom radius)]
    (merge base
           {:get-radius (fn [] @radius-state)
            :area (fn [] (* Math/PI @radius-state @radius-state))
            :scale (fn [factor]
                     (swap! radius-state * factor))})))

;; ============================================
;; OOスタイル: Observer パターン
;; ============================================

(defn make-observable-oo
  "OOスタイル: Observable クラス"
  []
  (let [observers (atom [])]
    {:add-observer (fn [observer]
                     (swap! observers conj observer))
     :remove-observer (fn [observer]
                        (swap! observers
                               (fn [obs] (remove #(= % observer) obs))))
     :notify (fn [event]
               (doseq [obs @observers]
                 (obs event)))}))
