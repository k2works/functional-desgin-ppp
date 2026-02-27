(ns property-based-testing
  "第5章: プロパティベーステスト

   test.check を使った生成的テストの手法を学びます。
   ジェネレータの作成、プロパティの定義、シュリンキングについて扱います。"
  (:require [clojure.test.check :as tc]
            [clojure.test.check.generators :as gen]
            [clojure.test.check.properties :as prop]
            [clojure.spec.alpha :as s]))

;; =============================================================================
;; 1. 基本的なジェネレータ
;; =============================================================================

;; プリミティブジェネレータ
(def int-gen gen/small-integer)
(def pos-int-gen gen/nat)
(def string-gen gen/string-alphanumeric)
(def bool-gen gen/boolean)

;; 範囲指定
(def age-gen (gen/choose 0 150))
(def percentage-gen (gen/double* {:min 0.0 :max 1.0}))

;; 列挙型
(def membership-gen (gen/elements [:bronze :silver :gold :platinum]))
(def status-gen (gen/elements [:active :inactive :suspended]))

;; =============================================================================
;; 2. コレクションジェネレータ
;; =============================================================================

;; ベクター
(def int-vector-gen (gen/vector gen/small-integer))
(def sized-int-vector-gen (gen/vector gen/small-integer 1 10))

;; マップ
(def string-int-map-gen (gen/map gen/string-alphanumeric gen/small-integer))

;; セット
(def int-set-gen (gen/set gen/small-integer))

;; =============================================================================
;; 3. 複合ジェネレータ
;; =============================================================================

(def person-gen
  "人物データのジェネレータ"
  (gen/hash-map
   :name (gen/such-that #(not (empty? %)) gen/string-alphanumeric)
   :age age-gen
   :membership membership-gen))

(def address-gen
  "住所データのジェネレータ"
  (gen/hash-map
   :street gen/string-alphanumeric
   :city gen/string-alphanumeric
   :postal-code (gen/fmap #(str (format "%03d" (mod % 1000))
                                "-"
                                (format "%04d" (mod % 10000)))
                          gen/nat)))

(def product-gen
  "商品データのジェネレータ"
  (gen/hash-map
   :product-id (gen/fmap #(str "PROD-" (format "%05d" (mod % 100000))) gen/nat)
   :name (gen/such-that #(not (empty? %)) gen/string-alphanumeric)
   :price (gen/fmap #(+ 1 (mod % 10000)) gen/nat)
   :quantity (gen/fmap #(+ 1 (mod % 100)) gen/nat)))

;; =============================================================================
;; 4. ジェネレータの変換
;; =============================================================================

;; fmap: 生成された値を変換
(def uppercase-string-gen
  (gen/fmap clojure.string/upper-case gen/string-alphanumeric))

;; bind: 生成された値に基づいて別のジェネレータを選択
(def non-empty-subset-gen
  (gen/bind (gen/not-empty (gen/vector gen/small-integer))
            (fn [v]
              (gen/fmap #(take % v)
                        (gen/choose 1 (count v))))))

;; such-that: 条件を満たす値のみを生成
(def positive-even-gen
  (gen/such-that #(and (pos? %) (even? %)) gen/small-integer 100))

;; =============================================================================
;; 5. テスト対象の関数
;; =============================================================================

(defn reverse-string
  "文字列を反転する"
  [s]
  (apply str (reverse s)))

(defn sort-numbers
  "数値リストをソートする"
  [nums]
  (sort nums))

(defn calculate-discount
  "割引を計算する"
  [price rate]
  (if (or (neg? price) (neg? rate) (> rate 1))
    price
    (* price (- 1 rate))))

(defn merge-sorted
  "2つのソート済みリストをマージする"
  [xs ys]
  (loop [result []
         xs xs
         ys ys]
    (cond
      (empty? xs) (into result ys)
      (empty? ys) (into result xs)
      (<= (first xs) (first ys))
      (recur (conj result (first xs)) (rest xs) ys)
      :else
      (recur (conj result (first ys)) xs (rest ys)))))

(defn encode-run-length
  "ランレングス圧縮"
  [s]
  (->> s
       (partition-by identity)
       (map (fn [group] [(first group) (count group)]))
       (into [])))

(defn decode-run-length
  "ランレングス展開"
  [encoded]
  (->> encoded
       (mapcat (fn [[ch n]] (repeat n ch)))
       (apply str)))

;; =============================================================================
;; 6. プロパティの定義
;; =============================================================================

(def prop-reverse-involutory
  "文字列を2回反転すると元に戻る"
  (prop/for-all [s gen/string]
    (= s (reverse-string (reverse-string s)))))

(def prop-reverse-length-preserved
  "反転しても長さは変わらない"
  (prop/for-all [s gen/string]
    (= (count s) (count (reverse-string s)))))

(def prop-sort-idempotent
  "ソートは冪等（2回ソートしても結果は同じ）"
  (prop/for-all [nums (gen/vector gen/small-integer)]
    (= (sort-numbers nums) (sort-numbers (sort-numbers nums)))))

(def prop-sort-preserves-elements
  "ソートは要素を保存する（追加も削除もしない）"
  (prop/for-all [nums (gen/vector gen/small-integer)]
    (= (frequencies nums) (frequencies (sort-numbers nums)))))

(def prop-sort-ordered
  "ソート結果は昇順に並ぶ"
  (prop/for-all [nums (gen/vector gen/small-integer)]
    (let [sorted (sort-numbers nums)]
      (or (empty? sorted)
          (apply <= sorted)))))

(def prop-discount-bounds
  "割引後の価格は0以上、元の価格以下"
  (prop/for-all [price (gen/fmap #(+ 1 (Math/abs %)) gen/small-integer)
                 rate (gen/double* {:min 0.0 :max 0.99})]
    (let [discounted (calculate-discount price rate)]
      (and (>= discounted 0)
           (<= discounted price)))))

(def prop-merge-sorted-is-sorted
  "マージ結果はソート済み"
  (prop/for-all [xs (gen/vector gen/small-integer)
                 ys (gen/vector gen/small-integer)]
    (let [sorted-xs (sort xs)
          sorted-ys (sort ys)
          merged (merge-sorted sorted-xs sorted-ys)]
      (or (empty? merged)
          (apply <= merged)))))

(def prop-run-length-roundtrip
  "ランレングス符号化は可逆"
  (prop/for-all [s (gen/fmap #(apply str %) (gen/vector gen/char-alpha))]
    (= s (decode-run-length (encode-run-length s)))))

;; =============================================================================
;; 7. プロパティの実行
;; =============================================================================

(defn run-property
  "プロパティを実行してレポートを返す"
  ([prop]
   (run-property prop 100))
  ([prop num-tests]
   (tc/quick-check num-tests prop)))

(defn check-all-properties
  "すべてのプロパティをチェック"
  []
  {:reverse-involutory (run-property prop-reverse-involutory)
   :reverse-length (run-property prop-reverse-length-preserved)
   :sort-idempotent (run-property prop-sort-idempotent)
   :sort-preserves (run-property prop-sort-preserves-elements)
   :sort-ordered (run-property prop-sort-ordered)
   :discount-bounds (run-property prop-discount-bounds)
   :merge-sorted (run-property prop-merge-sorted-is-sorted)
   :run-length (run-property prop-run-length-roundtrip)})

;; =============================================================================
;; 8. シュリンキング（失敗時の最小反例探索）
;; =============================================================================

(defn buggy-abs
  "バグのある絶対値関数（Integer/MIN_VALUE で失敗）"
  [n]
  (if (neg? n)
    (- n)
    n))

(def prop-abs-always-positive
  "絶対値は常に正（バグがあると失敗する）"
  (prop/for-all [n gen/small-integer]
    (>= (buggy-abs n) 0)))

;; =============================================================================
;; 9. カスタムジェネレータとプロパティ
;; =============================================================================

(def order-item-gen
  "注文アイテムのジェネレータ"
  (gen/hash-map
   :product-id (gen/fmap #(str "PROD-" (format "%05d" (mod % 100000))) gen/nat)
   :quantity (gen/fmap #(+ 1 (mod % 10)) gen/nat)
   :price (gen/fmap #(+ 100 (mod % 10000)) gen/nat)))

(def order-gen
  "注文のジェネレータ"
  (gen/hash-map
   :order-id (gen/fmap #(str "ORD-" (format "%08d" (mod % 100000000))) gen/nat)
   :items (gen/not-empty (gen/vector order-item-gen 1 5))))

(defn calculate-order-total
  "注文合計を計算"
  [order]
  (->> (:items order)
       (map #(* (:price %) (:quantity %)))
       (reduce +)))

(def prop-order-total-positive
  "注文合計は常に正"
  (prop/for-all [order order-gen]
    (pos? (calculate-order-total order))))

(def prop-order-total-sum-of-items
  "注文合計は各アイテムの合計と等しい"
  (prop/for-all [order order-gen]
    (let [total (calculate-order-total order)
          item-totals (map #(* (:price %) (:quantity %)) (:items order))]
      (= total (reduce + item-totals)))))

;; =============================================================================
;; 10. Spec との統合
;; =============================================================================

(s/def ::positive-int (s/and int? pos?))
(s/def ::percentage (s/and number? #(<= 0 % 1)))

(s/def ::item
  (s/keys :req-un [::product-id ::quantity ::price]))

(s/def ::product-id string?)
(s/def ::quantity ::positive-int)
(s/def ::price ::positive-int)

(defn spec-gen
  "Specからジェネレータを取得"
  [spec]
  (s/gen spec))

;; Specベースのプロパティテスト
(def prop-item-spec-valid
  "生成されたアイテムはSpecに適合する"
  (prop/for-all [item (gen/hash-map
                       :product-id (gen/fmap #(str "PROD-" %) gen/string-alphanumeric)
                       :quantity (gen/fmap #(+ 1 (Math/abs %)) gen/small-integer)
                       :price (gen/fmap #(+ 1 (Math/abs %)) gen/small-integer))]
    (s/valid? ::item item)))
