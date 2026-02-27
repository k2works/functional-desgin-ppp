(ns decorator-pattern.journaled-shape-spec
  (:require [speclj.core :refer :all]
            [composite-pattern.shape :as shape]
            [composite-pattern.square :as square]
            [composite-pattern.circle :as circle]
            [decorator-pattern.journaled-shape :as js]))

(describe "Decorator パターン - JournaledShape"

  (context "基本機能"
    (it "形状をデコレートできる"
      (let [square (square/make-square [0 0] 1)
            journaled (js/make square)]
        (should= [] (js/get-journal journaled))
        (should= square (js/get-shape journaled))))

    (it "移動操作を記録する"
      (let [journaled (-> (js/make (square/make-square [0 0] 1))
                          (shape/translate 2 3))]
        (should= [[:translate 2 3]] (js/get-journal journaled))
        (should= [2 3] (::square/top-left (js/get-shape journaled)))))

    (it "拡大操作を記録する"
      (let [journaled (-> (js/make (square/make-square [0 0] 1))
                          (shape/scale 5))]
        (should= [[:scale 5]] (js/get-journal journaled))
        (should= 5 (::square/side (js/get-shape journaled))))))

  (context "複数操作"
    (it "複数の操作を順番に記録する"
      (let [journaled (-> (js/make (square/make-square [0 0] 1))
                          (shape/translate 2 3)
                          (shape/scale 5))]
        (should= [[:translate 2 3] [:scale 5]]
                 (js/get-journal journaled))
        (should= {::shape/type ::square/square
                  ::square/top-left [2 3]
                  ::square/side 5}
                 (js/get-shape journaled))))

    (it "円にも適用できる"
      (let [journaled (-> (js/make (circle/make-circle [10 10] 5))
                          (shape/translate 5 5)
                          (shape/scale 2))]
        (should= [[:translate 5 5] [:scale 2]]
                 (js/get-journal journaled))
        (should= [15 15] (::circle/center (js/get-shape journaled)))
        (should= 10 (::circle/radius (js/get-shape journaled)))))))

(run-specs)
