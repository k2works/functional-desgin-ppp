(ns tdd-in-functional
  "第6章: テスト駆動開発と関数型プログラミング

   Red-Green-Refactor サイクルを関数型スタイルで実践する方法を学びます。
   テストファーストの関数設計とリファクタリングについて扱います。")

;; =============================================================================
;; 1. TDD の基本サイクル: Red-Green-Refactor
;; =============================================================================

;; このファイルでは、TDD サイクルを通じて開発した関数を示します。
;; 各関数は、まずテストを書き（Red）、次に実装し（Green）、
;; 最後にリファクタリング（Refactor）を行って完成させました。

;; =============================================================================
;; 2. FizzBuzz - TDD の典型例
;; =============================================================================

(defn fizz? [n] (zero? (mod n 3)))
(defn buzz? [n] (zero? (mod n 5)))
(defn fizzbuzz? [n] (and (fizz? n) (buzz? n)))

(defn fizzbuzz
  "FizzBuzz を返す
   - 3で割り切れる場合は \"Fizz\"
   - 5で割り切れる場合は \"Buzz\"
   - 両方で割り切れる場合は \"FizzBuzz\"
   - それ以外は数値の文字列"
  [n]
  (cond
    (fizzbuzz? n) "FizzBuzz"
    (fizz? n) "Fizz"
    (buzz? n) "Buzz"
    :else (str n)))

(defn fizzbuzz-sequence
  "1からnまでのFizzBuzzシーケンスを生成"
  [n]
  (map fizzbuzz (range 1 (inc n))))

;; =============================================================================
;; 3. ローマ数字変換 - 段階的な実装
;; =============================================================================

(def roman-numerals
  "ローマ数字の対応表（大きい順）"
  [[1000 "M"]
   [900 "CM"]
   [500 "D"]
   [400 "CD"]
   [100 "C"]
   [90 "XC"]
   [50 "L"]
   [40 "XL"]
   [10 "X"]
   [9 "IX"]
   [5 "V"]
   [4 "IV"]
   [1 "I"]])

(defn to-roman
  "アラビア数字をローマ数字に変換する"
  [n]
  {:pre [(pos? n) (<= n 3999)]}
  (loop [n n
         result ""]
    (if (zero? n)
      result
      (let [[value numeral] (first (filter #(<= (first %) n) roman-numerals))]
        (recur (- n value) (str result numeral))))))

(defn from-roman
  "ローマ数字をアラビア数字に変換する"
  [s]
  (let [values {"M" 1000 "CM" 900 "D" 500 "CD" 400
                "C" 100 "XC" 90 "L" 50 "XL" 40
                "X" 10 "IX" 9 "V" 5 "IV" 4 "I" 1}]
    (loop [s s
           result 0]
      (if (empty? s)
        result
        (let [two-chars (when (>= (count s) 2) (subs s 0 2))
              one-char (subs s 0 1)]
          (if (and two-chars (get values two-chars))
            (recur (subs s 2) (+ result (get values two-chars)))
            (recur (subs s 1) (+ result (get values one-char)))))))))

;; =============================================================================
;; 4. ボウリングスコア計算 - 複雑なビジネスロジック
;; =============================================================================

(defn strike?
  "ストライクかどうか"
  [frame]
  (= 10 (first frame)))

(defn spare?
  "スペアかどうか"
  [frame]
  (and (not (strike? frame))
       (>= (count frame) 2)
       (= 10 (+ (first frame) (second frame)))))

(defn frame-score
  "フレームの基本スコア"
  [frame]
  (reduce + (take 2 frame)))

(defn strike-bonus
  "ストライクボーナス（次の2投の合計）"
  [remaining-rolls]
  (reduce + (take 2 remaining-rolls)))

(defn spare-bonus
  "スペアボーナス（次の1投）"
  [remaining-rolls]
  (first remaining-rolls))

(defn calculate-frame
  "1フレームのスコアを計算"
  [frame remaining-rolls]
  (cond
    (strike? frame) (+ 10 (strike-bonus remaining-rolls))
    (spare? frame) (+ 10 (spare-bonus remaining-rolls))
    :else (frame-score frame)))

(defn parse-rolls-to-frames
  "投球リストをフレームに分割"
  [rolls]
  (loop [rolls rolls
         frames []
         frame-count 0]
    (cond
      (>= frame-count 10) frames
      (empty? rolls) frames
      (= frame-count 9) ;; 10フレーム目は特別
      (conj frames rolls)
      (strike? rolls)
      (recur (rest rolls) (conj frames [10]) (inc frame-count))
      :else
      (recur (drop 2 rolls)
             (conj frames (vec (take 2 rolls)))
             (inc frame-count)))))

(defn remaining-rolls-after-frame
  "フレーム後の残り投球を取得"
  [rolls frame-index]
  (let [frames (parse-rolls-to-frames rolls)]
    (if (< frame-index (count frames))
      (let [frame (nth frames frame-index)]
        (drop (if (strike? frame) 1 2)
              (drop (->> (take frame-index frames)
                         (map #(if (strike? %) 1 2))
                         (reduce + 0))
                    rolls)))
      [])))

(defn bowling-score
  "ボウリングのスコアを計算"
  [rolls]
  (let [frames (parse-rolls-to-frames rolls)]
    (loop [frame-idx 0
           remaining rolls
           total 0]
      (if (or (>= frame-idx 10) (empty? remaining))
        total
        (let [frame (nth frames frame-idx nil)]
          (if (nil? frame)
            total
            (let [frame-rolls (if (strike? frame) 1 2)
                  after-frame (drop frame-rolls remaining)
                  score (calculate-frame frame after-frame)]
              (recur (inc frame-idx)
                     after-frame
                     (+ total score)))))))))

;; =============================================================================
;; 5. 素数生成 - シンプルな関数の TDD
;; =============================================================================

(defn prime?
  "素数かどうかを判定する"
  [n]
  (cond
    (< n 2) false
    (= n 2) true
    (even? n) false
    :else (not-any? #(zero? (mod n %))
                    (range 3 (inc (Math/sqrt n)) 2))))

(defn primes-up-to
  "n以下の素数をすべて返す"
  [n]
  (filter prime? (range 2 (inc n))))

(defn nth-prime
  "n番目の素数を返す（1-indexed）"
  [n]
  {:pre [(pos? n)]}
  (nth (filter prime? (iterate inc 2)) (dec n)))

(defn prime-factors
  "素因数分解"
  [n]
  {:pre [(pos? n)]}
  (loop [n n
         factor 2
         factors []]
    (cond
      (= n 1) factors
      (zero? (mod n factor)) (recur (/ n factor) factor (conj factors factor))
      :else (recur n (inc factor) factors))))

;; =============================================================================
;; 6. スタック - データ構造の TDD
;; =============================================================================

(defn create-stack
  "空のスタックを作成"
  []
  {:items []})

(defn stack-push
  "スタックに要素を追加"
  [stack item]
  (update stack :items conj item))

(defn stack-pop
  "スタックから要素を取り出す"
  [stack]
  {:pre [(not (empty? (:items stack)))]}
  (let [items (:items stack)]
    {:value (peek items)
     :stack {:items (pop items)}}))

(defn stack-peek
  "スタックの先頭要素を参照（取り出さない）"
  [stack]
  {:pre [(not (empty? (:items stack)))]}
  (peek (:items stack)))

(defn stack-empty?
  "スタックが空かどうか"
  [stack]
  (empty? (:items stack)))

(defn stack-size
  "スタックのサイズ"
  [stack]
  (count (:items stack)))

;; =============================================================================
;; 7. 文字列電卓 - 文字列パースの TDD
;; =============================================================================

(defn parse-numbers
  "文字列から数値を解析"
  [s]
  (if (empty? s)
    []
    (let [[delimiter s] (if (.startsWith s "//")
                          (let [end-idx (.indexOf s "\n")]
                            [(subs s 2 end-idx) (subs s (inc end-idx))])
                          [#"[,\n]" s])]
      (->> (if (string? delimiter)
             (clojure.string/split s (re-pattern (java.util.regex.Pattern/quote delimiter)))
             (clojure.string/split s delimiter))
           (map #(Integer/parseInt (clojure.string/trim %)))))))

(defn validate-numbers
  "負の数がないか検証"
  [numbers]
  (let [negatives (filter neg? numbers)]
    (when (seq negatives)
      (throw (ex-info "Negatives not allowed" {:negatives negatives}))))
  numbers)

(defn string-calculator
  "文字列電卓
   - 空文字列は0
   - 単一の数値はその値
   - カンマまたは改行区切りで合計
   - カスタム区切り文字: //[delimiter]\\n
   - 負の数は例外
   - 1000より大きい数は無視"
  [s]
  (if (empty? s)
    0
    (->> (parse-numbers s)
         (validate-numbers)
         (filter #(<= % 1000))
         (reduce +))))

;; =============================================================================
;; 8. Word Wrap - 文字列処理の TDD
;; =============================================================================

(defn word-wrap
  "指定した幅で文字列を折り返す"
  [s width]
  (if (or (empty? s) (<= (count s) width))
    s
    (let [break-point (or (some #(when (= (nth s %) \space) %)
                                (range (min width (count s)) 0 -1))
                          width)]
      (str (clojure.string/trim (subs s 0 break-point))
           "\n"
           (word-wrap (clojure.string/trim (subs s break-point)) width)))))

;; =============================================================================
;; 9. 純粋関数とテスト容易性
;; =============================================================================

;; 純粋関数：テストが容易
(defn calculate-tax
  "税額を計算する純粋関数"
  [amount rate]
  (* amount rate))

(defn calculate-total-with-tax
  "税込み総額を計算する純粋関数"
  [items tax-rate]
  (let [subtotal (reduce + (map :price items))
        tax (calculate-tax subtotal tax-rate)]
    {:subtotal subtotal
     :tax tax
     :total (+ subtotal tax)}))

;; 副作用を分離
(defn format-receipt
  "レシートをフォーマットする純粋関数"
  [{:keys [subtotal tax total]}]
  (str "小計: " subtotal "円\n"
       "消費税: " tax "円\n"
       "合計: " total "円"))

;; =============================================================================
;; 10. リファクタリングパターン
;; =============================================================================

;; Before: 複雑な条件分岐
(defn calculate-shipping-before
  "送料を計算（リファクタリング前）"
  [order]
  (let [total (:total order)
        weight (:weight order)
        region (:region order)]
    (cond
      (>= total 10000) 0
      (= region :local) (if (< weight 5) 300 500)
      (= region :domestic) (if (< weight 5) 500 800)
      (= region :international) (if (< weight 5) 2000 3000)
      :else 500)))

;; After: 関数に分割
(defn free-shipping? [total] (>= total 10000))

(def shipping-rates
  {:local {true 300 false 500}
   :domestic {true 500 false 800}
   :international {true 2000 false 3000}})

(defn calculate-shipping
  "送料を計算（リファクタリング後）"
  [{:keys [total weight region] :or {region :domestic}}]
  (if (free-shipping? total)
    0
    (get-in shipping-rates [region (< weight 5)] 500)))
