(ns visitor-pattern.shape-spec
  (:require [speclj.core :refer :all]
            [visitor-pattern.shape :as shape]
            [visitor-pattern.circle :as circle]
            [visitor-pattern.square :as square]
            [visitor-pattern.rectangle :as rectangle]))

(describe "Visitor パターン - Shape"

  (context "Circle"
    (it "円を作成できる"
      (let [c (circle/make [10 20] 5)]
        (should= [10 20] (::circle/center c))
        (should= 5 (::circle/radius c))))

    (it "円を移動できる"
      (let [c (circle/make [10 20] 5)
            moved (shape/translate c 5 -5)]
        (should= [15 15] (::circle/center moved))))

    (it "円を拡大できる"
      (let [c (circle/make [10 20] 5)
            scaled (shape/scale c 2)]
        (should= 10 (::circle/radius scaled)))))

  (context "Square"
    (it "正方形を作成できる"
      (let [s (square/make [0 0] 10)]
        (should= [0 0] (::square/top-left s))
        (should= 10 (::square/side s))))

    (it "正方形を移動できる"
      (let [s (square/make [0 0] 10)
            moved (shape/translate s 5 5)]
        (should= [5 5] (::square/top-left moved))))

    (it "正方形を拡大できる"
      (let [s (square/make [0 0] 10)
            scaled (shape/scale s 1.5)]
        (should= 15.0 (::square/side scaled)))))

  (context "Rectangle"
    (it "長方形を作成できる"
      (let [r (rectangle/make [0 0] 20 10)]
        (should= [0 0] (::rectangle/top-left r))
        (should= 20 (::rectangle/width r))
        (should= 10 (::rectangle/height r))))

    (it "長方形を移動できる"
      (let [r (rectangle/make [0 0] 20 10)
            moved (shape/translate r 10 20)]
        (should= [10 20] (::rectangle/top-left moved))))

    (it "長方形を拡大できる"
      (let [r (rectangle/make [0 0] 20 10)
            scaled (shape/scale r 2)]
        (should= 40 (::rectangle/width scaled))
        (should= 20 (::rectangle/height scaled))))))

(run-specs)
