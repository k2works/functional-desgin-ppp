(ns composition
  "第2章: 関数合成と高階関数

   小さな関数を組み合わせて複雑な処理を構築する方法を学びます。
   comp、partial、juxt などの関数合成ツールと、
   高階関数を活用したデータ処理パターンを扱います。")

;; =============================================================================
;; 1. 関数合成の基本 (comp)
;; =============================================================================

(defn add-tax
  "税金を追加する"
  [rate amount]
  (* amount (+ 1 rate)))

(defn apply-discount-rate
  "割引を適用する"
  [rate amount]
  (* amount (- 1 rate)))

(defn round-to-yen
  "円単位に丸める"
  [amount]
  (Math/round (double amount)))

;; comp による関数合成
(def calculate-final-price
  "最終価格を計算する合成関数"
  (comp round-to-yen
        (partial add-tax 0.1)
        (partial apply-discount-rate 0.2)))

;; =============================================================================
;; 2. 部分適用 (partial)
;; =============================================================================

(defn greet
  "挨拶する"
  [greeting name]
  (str greeting ", " name "!"))

(def say-hello (partial greet "Hello"))
(def say-goodbye (partial greet "Goodbye"))

;; 複数引数の部分適用
(defn send-email
  "メールを送信する"
  [from to subject body]
  {:from from :to to :subject subject :body body})

(def send-from-system (partial send-email "system@example.com"))
(def send-notification (partial send-from-system "user@example.com" "通知"))

;; =============================================================================
;; 3. juxt - 複数の関数を並列適用
;; =============================================================================

(defn get-stats
  "数値リストの統計情報を取得する"
  [numbers]
  ((juxt first last count #(apply min %) #(apply max %)) numbers))

(defn analyze-person
  "人物情報を分析する"
  [person]
  ((juxt :name :age #(if (>= (:age %) 18) :adult :minor)) person))

;; =============================================================================
;; 4. 高階関数によるデータ処理
;; =============================================================================

(defn process-with-logging
  "処理をラップしてログを出力する高階関数"
  [f]
  (fn [& args]
    (println "入力:" args)
    (let [result (apply f args)]
      (println "出力:" result)
      result)))

(defn memoize-with-ttl
  "TTL付きメモ化を行う高階関数"
  [f ttl-ms]
  (let [cache (atom {})]
    (fn [& args]
      (let [now (System/currentTimeMillis)
            cached (get @cache args)]
        (if (and cached (< (- now (:time cached)) ttl-ms))
          (:value cached)
          (let [result (apply f args)]
            (swap! cache assoc args {:value result :time now})
            result))))))

(defn retry
  "失敗時にリトライする高階関数"
  [f max-retries]
  (fn [& args]
    (loop [attempts 0]
      (let [result (try
                     {:success true :value (apply f args)}
                     (catch Exception e
                       {:success false :error e}))]
        (if (:success result)
          (:value result)
          (if (< attempts max-retries)
            (recur (inc attempts))
            (throw (:error result))))))))

;; =============================================================================
;; 5. パイプライン処理
;; =============================================================================

(defn pipeline
  "関数のリストを順次適用するパイプラインを作成する"
  [& fns]
  (fn [input]
    (reduce (fn [acc f] (f acc)) input fns)))

;; 注文処理パイプライン
(defn validate-order
  "注文を検証する"
  [order]
  (if (empty? (:items order))
    (throw (ex-info "注文にアイテムがありません" {:order order}))
    order))

(defn calculate-order-total
  "注文合計を計算する"
  [order]
  (let [total (->> (:items order)
                   (map #(* (:price %) (:quantity %)))
                   (reduce +))]
    (assoc order :total total)))

(defn apply-order-discount
  "注文割引を適用する"
  [order]
  (let [discount-rate (get {:gold 0.1 :silver 0.05 :bronze 0.02}
                           (get-in order [:customer :membership])
                           0)]
    (update order :total #(* % (- 1 discount-rate)))))

(defn add-shipping
  "送料を追加する"
  [order]
  (let [shipping (if (>= (:total order) 5000) 0 500)]
    (-> order
        (assoc :shipping shipping)
        (update :total + shipping))))

(def process-order-pipeline
  "注文処理パイプライン"
  (pipeline validate-order
            calculate-order-total
            apply-order-discount
            add-shipping))

;; =============================================================================
;; 6. 関数合成によるバリデーション
;; =============================================================================

(defn validator
  "バリデータを作成する高階関数"
  [pred error-msg]
  (fn [value]
    (if (pred value)
      {:valid true :value value}
      {:valid false :error error-msg :value value})))

(defn combine-validators
  "複数のバリデータを合成する"
  [& validators]
  (fn [value]
    (reduce (fn [result v]
              (if (:valid result)
                (v (:value result))
                result))
            {:valid true :value value}
            validators)))

(def validate-positive (validator pos? "値は正の数である必要があります"))
(def validate-under-100 (validator #(< % 100) "値は100未満である必要があります"))
(def validate-integer (validator integer? "値は整数である必要があります"))

(def validate-quantity
  "数量バリデータ"
  (combine-validators validate-integer
                      validate-positive
                      validate-under-100))

;; =============================================================================
;; 7. 関数の変換
;; =============================================================================

(defn flip
  "引数の順序を反転する"
  [f]
  (fn [a b]
    (f b a)))

(defn complement-fn
  "述語の結果を反転する"
  [pred]
  (fn [& args]
    (not (apply pred args))))

(defn constantly-fn
  "常に同じ値を返す関数を作成する"
  [value]
  (fn [& _] value))

(defn curry
  "2引数関数をカリー化する"
  [f]
  (fn [a]
    (fn [b]
      (f a b))))

(defn uncurry
  "カリー化された関数を元に戻す"
  [f]
  (fn [a b]
    ((f a) b)))

;; =============================================================================
;; 8. 関数合成のパターン
;; =============================================================================

(defn compose-predicates
  "複数の述語を AND で合成する"
  [& preds]
  (fn [x]
    (every? #(% x) preds)))

(defn compose-predicates-or
  "複数の述語を OR で合成する"
  [& preds]
  (fn [x]
    (some #(% x) preds)))

(def valid-age?
  "有効な年齢かチェックする"
  (compose-predicates integer?
                      pos?
                      #(<= % 150)))

(def premium-customer?
  "プレミアム顧客かチェックする"
  (compose-predicates-or
   #(= (:membership %) :gold)
   #(>= (:purchase-count %) 100)
   #(>= (:total-spent %) 100000)))
