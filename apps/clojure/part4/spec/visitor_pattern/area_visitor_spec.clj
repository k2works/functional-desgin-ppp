(ns visitor-pattern.area-visitor-spec
  (:require [speclj.core :refer :all]
            [visitor-pattern.area-visitor :as area]
            [visitor-pattern.circle :as circle]
            [visitor-pattern.square :as square]
            [visitor-pattern.rectangle :as rectangle]))

(describe "Visitor パターン - Area Visitor"

  (context "単一図形の面積"
    (it "円の面積を計算できる"
      (let [c (circle/make [0 0] 5)]
        (should (> 0.01 (Math/abs (- (* Math/PI 25) (area/calculate-area c)))))))

    (it "正方形の面積を計算できる"
      (let [s (square/make [0 0] 10)]
        (should= 100 (area/calculate-area s))))

    (it "長方形の面積を計算できる"
      (let [r (rectangle/make [0 0] 20 10)]
        (should= 200 (area/calculate-area r)))))

  (context "複数図形の合計面積"
    (it "複数の図形の合計面積を計算できる"
      (let [shapes [(square/make [0 0] 10)
                    (rectangle/make [0 0] 20 10)]]
        (should= 300 (area/total-area shapes))))))

(run-specs)
