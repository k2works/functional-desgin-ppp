(ns best-practices.pure-functions
  "純粋関数と副作用の分離のベストプラクティス")

;; ============================================
;; 1. 純粋関数の例
;; ============================================

(defn add
  "純粋関数: 同じ入力に対して常に同じ出力"
  [a b]
  (+ a b))

(defn multiply
  "純粋関数: 副作用なし"
  [a b]
  (* a b))

(defn square
  "純粋関数: 参照透過性を持つ"
  [x]
  (* x x))

;; ============================================
;; 2. 副作用を含む関数を分離
;; ============================================

;; 悪い例: 副作用と計算が混在
;; (defn calculate-and-log [x y]
;;   (println "Calculating...")  ; 副作用
;;   (+ x y))

;; 良い例: 純粋関数と副作用を分離
(defn calculate
  "純粋関数: 計算のみ"
  [x y]
  (+ x y))

(defn with-logging
  "高階関数: ロギングを追加"
  [f logger]
  (fn [& args]
    (logger (str "Calling with args: " args))
    (let [result (apply f args)]
      (logger (str "Result: " result))
      result)))

;; ============================================
;; 3. 副作用を端に押し出す
;; ============================================

;; ビジネスロジック（純粋）
(defn validate-amount
  "金額の検証（純粋）"
  [amount]
  (cond
    (nil? amount) {:valid false :error "Amount is required"}
    (<= amount 0) {:valid false :error "Amount must be positive"}
    :else {:valid true :amount amount}))

(defn calculate-fee
  "手数料計算（純粋）"
  [amount fee-rate]
  (* amount fee-rate))

(defn calculate-total
  "合計計算（純粋）"
  [amount fee]
  (+ amount fee))

;; 副作用を含む処理（境界）
(defn process-payment!
  "支払い処理（副作用あり）
   純粋関数を組み合わせて使用し、副作用は最後に実行"
  [amount fee-rate side-effect-fn]
  (let [validation (validate-amount amount)]
    (if (:valid validation)
      (let [fee (calculate-fee amount fee-rate)
            total (calculate-total amount fee)
            result {:amount amount :fee fee :total total :status :success}]
        ;; 副作用は最後に実行
        (side-effect-fn result)
        result)
      {:status :error :error (:error validation)})))

;; ============================================
;; 4. 関数合成
;; ============================================

(defn compose
  "関数合成ユーティリティ"
  [& fns]
  (reduce (fn [f g]
            (fn [& args]
              (f (apply g args))))
          fns))

;; パイプライン形式での合成
(defn pipeline
  "パイプライン形式の関数合成"
  [& fns]
  (fn [x]
    (reduce (fn [acc f] (f acc)) x fns)))

;; 使用例
(def process-number
  "数値処理パイプライン"
  (pipeline
   #(+ % 1)      ; 1を加算
   #(* % 2)      ; 2倍
   #(- % 3)))    ; 3を減算

;; ============================================
;; 5. 参照透過性の活用
;; ============================================

(defn memoize-fn
  "メモ化: 参照透過性を活用したキャッシング"
  [f]
  (let [cache (atom {})]
    (fn [& args]
      (if-let [cached (get @cache args)]
        cached
        (let [result (apply f args)]
          (swap! cache assoc args result)
          result)))))

;; フィボナッチ（メモ化の例）
(defn fib-naive
  "フィボナッチ（単純な再帰）"
  [n]
  (if (<= n 1)
    n
    (+ (fib-naive (- n 1))
       (fib-naive (- n 2)))))

(def fib-memo
  "フィボナッチ（メモ化版）"
  (memoize-fn
   (fn [n]
     (if (<= n 1)
       n
       (+ (fib-memo (- n 1))
          (fib-memo (- n 2)))))))
