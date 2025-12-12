(ns tdd-in-functional-spec
  (:require [speclj.core :refer :all]
            [tdd-in-functional :refer :all]))

(describe "テスト駆動開発と関数型プログラミング"

  ;; =========================================================================
  ;; FizzBuzz
  ;; =========================================================================
  (context "FizzBuzz"
    (it "1は\"1\"を返す"
      (should= "1" (fizzbuzz 1)))

    (it "2は\"2\"を返す"
      (should= "2" (fizzbuzz 2)))

    (it "3は\"Fizz\"を返す"
      (should= "Fizz" (fizzbuzz 3)))

    (it "5は\"Buzz\"を返す"
      (should= "Buzz" (fizzbuzz 5)))

    (it "15は\"FizzBuzz\"を返す"
      (should= "FizzBuzz" (fizzbuzz 15)))

    (it "6は\"Fizz\"を返す（3の倍数）"
      (should= "Fizz" (fizzbuzz 6)))

    (it "10は\"Buzz\"を返す（5の倍数）"
      (should= "Buzz" (fizzbuzz 10)))

    (it "30は\"FizzBuzz\"を返す（15の倍数）"
      (should= "FizzBuzz" (fizzbuzz 30)))

    (it "fizzbuzz-sequence は正しいシーケンスを生成する"
      (should= ["1" "2" "Fizz" "4" "Buzz" "Fizz" "7" "8" "Fizz" "Buzz"
                "11" "Fizz" "13" "14" "FizzBuzz"]
               (fizzbuzz-sequence 15))))

  ;; =========================================================================
  ;; ローマ数字変換
  ;; =========================================================================
  (context "ローマ数字変換"
    (context "to-roman"
      (it "1はIを返す"
        (should= "I" (to-roman 1)))

      (it "3はIIIを返す"
        (should= "III" (to-roman 3)))

      (it "4はIVを返す"
        (should= "IV" (to-roman 4)))

      (it "5はVを返す"
        (should= "V" (to-roman 5)))

      (it "9はIXを返す"
        (should= "IX" (to-roman 9)))

      (it "10はXを返す"
        (should= "X" (to-roman 10)))

      (it "40はXLを返す"
        (should= "XL" (to-roman 40)))

      (it "50はLを返す"
        (should= "L" (to-roman 50)))

      (it "90はXCを返す"
        (should= "XC" (to-roman 90)))

      (it "100はCを返す"
        (should= "C" (to-roman 100)))

      (it "400はCDを返す"
        (should= "CD" (to-roman 400)))

      (it "500はDを返す"
        (should= "D" (to-roman 500)))

      (it "900はCMを返す"
        (should= "CM" (to-roman 900)))

      (it "1000はMを返す"
        (should= "M" (to-roman 1000)))

      (it "1984はMCMLXXXIVを返す"
        (should= "MCMLXXXIV" (to-roman 1984)))

      (it "3999はMMMCMXCIXを返す"
        (should= "MMMCMXCIX" (to-roman 3999))))

    (context "from-roman"
      (it "Iは1を返す"
        (should= 1 (from-roman "I")))

      (it "IVは4を返す"
        (should= 4 (from-roman "IV")))

      (it "MCMLXXXIVは1984を返す"
        (should= 1984 (from-roman "MCMLXXXIV")))))

  ;; =========================================================================
  ;; ボウリングスコア計算
  ;; =========================================================================
  (context "ボウリングスコア計算"
    (it "ガタースコアは0"
      (should= 0 (bowling-score (repeat 20 0))))

    (it "すべて1ピンは20点"
      (should= 20 (bowling-score (repeat 20 1))))

    (it "スペアの後の投球はボーナス"
      (should= 16 (bowling-score [5 5 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0])))

    (it "ストライクの後の2投はボーナス"
      (should= 24 (bowling-score [10 3 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0])))

    (it "パーフェクトゲームは300点"
      (should= 300 (bowling-score (repeat 12 10)))))

  ;; =========================================================================
  ;; 素数
  ;; =========================================================================
  (context "素数"
    (it "prime? は素数を正しく判定する"
      (should-not (prime? 0))
      (should-not (prime? 1))
      (should (prime? 2))
      (should (prime? 3))
      (should-not (prime? 4))
      (should (prime? 5))
      (should (prime? 7))
      (should-not (prime? 9))
      (should (prime? 11))
      (should (prime? 97)))

    (it "primes-up-to は正しい素数リストを返す"
      (should= [2 3 5 7 11 13 17 19] (primes-up-to 20)))

    (it "nth-prime はn番目の素数を返す"
      (should= 2 (nth-prime 1))
      (should= 3 (nth-prime 2))
      (should= 5 (nth-prime 3))
      (should= 97 (nth-prime 25)))

    (it "prime-factors は素因数分解を返す"
      (should= [2] (prime-factors 2))
      (should= [2 2] (prime-factors 4))
      (should= [2 3] (prime-factors 6))
      (should= [2 2 2 3] (prime-factors 24))
      (should= [2 2 5 5] (prime-factors 100))))

  ;; =========================================================================
  ;; スタック
  ;; =========================================================================
  (context "スタック"
    (it "create-stack は空のスタックを作成する"
      (should (stack-empty? (create-stack))))

    (it "stack-push は要素を追加する"
      (let [stack (-> (create-stack)
                      (stack-push 1)
                      (stack-push 2))]
        (should= 2 (stack-size stack))
        (should= 2 (stack-peek stack))))

    (it "stack-pop は最後に追加した要素を取り出す"
      (let [stack (-> (create-stack)
                      (stack-push 1)
                      (stack-push 2))
            {:keys [value stack]} (stack-pop stack)]
        (should= 2 value)
        (should= 1 (stack-peek stack))))

    (it "LIFO順序で動作する"
      (let [stack (-> (create-stack)
                      (stack-push "a")
                      (stack-push "b")
                      (stack-push "c"))
            {v1 :value s1 :stack} (stack-pop stack)
            {v2 :value s2 :stack} (stack-pop s1)
            {v3 :value _s3 :stack} (stack-pop s2)]
        (should= "c" v1)
        (should= "b" v2)
        (should= "a" v3))))

  ;; =========================================================================
  ;; 文字列電卓
  ;; =========================================================================
  (context "文字列電卓"
    (it "空文字列は0を返す"
      (should= 0 (string-calculator "")))

    (it "単一の数値はその値を返す"
      (should= 1 (string-calculator "1"))
      (should= 5 (string-calculator "5")))

    (it "カンマ区切りの数値を合計する"
      (should= 3 (string-calculator "1,2"))
      (should= 6 (string-calculator "1,2,3")))

    (it "改行区切りも処理する"
      (should= 6 (string-calculator "1\n2,3")))

    (it "カスタム区切り文字を使用できる"
      (should= 3 (string-calculator "//;\n1;2")))

    (it "負の数は例外をスローする"
      (should-throw clojure.lang.ExceptionInfo
                    (string-calculator "1,-2,3")))

    (it "1000より大きい数は無視する"
      (should= 2 (string-calculator "2,1001"))))

  ;; =========================================================================
  ;; Word Wrap
  ;; =========================================================================
  (context "Word Wrap"
    (it "空文字列はそのまま返す"
      (should= "" (word-wrap "" 10)))

    (it "幅以内の文字列はそのまま返す"
      (should= "hello" (word-wrap "hello" 10)))

    (it "長い文字列はスペースで折り返す"
      (should= "hello\nworld" (word-wrap "hello world" 7)))

    (it "複数回折り返す"
      (should= "one two\nthree\nfour" (word-wrap "one two three four" 8))))

  ;; =========================================================================
  ;; 純粋関数とテスト
  ;; =========================================================================
  (context "純粋関数"
    (it "calculate-tax は税額を計算する"
      (should= 100.0 (calculate-tax 1000 0.1))
      (should= 80.0 (calculate-tax 1000 0.08)))

    (it "calculate-total-with-tax は税込み総額を計算する"
      (let [items [{:name "商品A" :price 1000}
                   {:name "商品B" :price 2000}]
            result (calculate-total-with-tax items 0.1)]
        (should= 3000 (:subtotal result))
        (should= 300.0 (:tax result))
        (should= 3300.0 (:total result))))

    (it "format-receipt はレシートをフォーマットする"
      (should= "小計: 3000円\n消費税: 300円\n合計: 3300円"
               (format-receipt {:subtotal 3000 :tax 300 :total 3300}))))

  ;; =========================================================================
  ;; 送料計算（リファクタリング後）
  ;; =========================================================================
  (context "送料計算"
    (it "10000円以上は送料無料"
      (should= 0 (calculate-shipping {:total 10000 :weight 1 :region :local}))
      (should= 0 (calculate-shipping {:total 15000 :weight 10 :region :international})))

    (it "ローカル配送は軽量300円、重量500円"
      (should= 300 (calculate-shipping {:total 5000 :weight 3 :region :local}))
      (should= 500 (calculate-shipping {:total 5000 :weight 6 :region :local})))

    (it "国内配送は軽量500円、重量800円"
      (should= 500 (calculate-shipping {:total 5000 :weight 3 :region :domestic}))
      (should= 800 (calculate-shipping {:total 5000 :weight 6 :region :domestic})))

    (it "国際配送は軽量2000円、重量3000円"
      (should= 2000 (calculate-shipping {:total 5000 :weight 3 :region :international}))
      (should= 3000 (calculate-shipping {:total 5000 :weight 6 :region :international})))))

(run-specs)
