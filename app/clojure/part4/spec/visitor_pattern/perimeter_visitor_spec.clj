(ns visitor-pattern.perimeter-visitor-spec
  (:require [speclj.core :refer :all]
            [visitor-pattern.perimeter-visitor :as perimeter]
            [visitor-pattern.circle :as circle]
            [visitor-pattern.square :as square]
            [visitor-pattern.rectangle :as rectangle]))

(describe "Visitor パターン - Perimeter Visitor"

  (context "単一図形の周囲長"
    (it "円の周囲長を計算できる"
      (let [c (circle/make [0 0] 5)]
        (should (> 0.01 (Math/abs (- (* 2 Math/PI 5) (perimeter/calculate-perimeter c)))))))

    (it "正方形の周囲長を計算できる"
      (let [s (square/make [0 0] 10)]
        (should= 40 (perimeter/calculate-perimeter s))))

    (it "長方形の周囲長を計算できる"
      (let [r (rectangle/make [0 0] 20 10)]
        (should= 60 (perimeter/calculate-perimeter r)))))

  (context "複数図形の合計周囲長"
    (it "複数の図形の合計周囲長を計算できる"
      (let [shapes [(square/make [0 0] 10)
                    (rectangle/make [0 0] 20 10)]]
        (should= 100 (perimeter/total-perimeter shapes))))))

(run-specs)
