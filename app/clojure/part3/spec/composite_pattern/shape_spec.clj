(ns composite-pattern.shape-spec
  (:require [speclj.core :refer :all]
            [composite-pattern.shape :as shape]
            [composite-pattern.square :as square]
            [composite-pattern.circle :as circle]
            [composite-pattern.composite-shape :as cs]))

(describe "Composite パターン - Shape"

  (context "Square (Leaf)"
    (it "正方形を作成できる"
      (let [s (square/make-square [3 4] 5)]
        (should= [3 4] (::square/top-left s))
        (should= 5 (::square/side s))))

    (it "正方形を移動できる"
      (let [s (square/make-square [3 4] 1)
            translated (shape/translate s 1 1)]
        (should= [4 5] (::square/top-left translated))
        (should= 1 (::square/side translated))))

    (it "正方形を拡大できる"
      (let [s (square/make-square [1 2] 2)
            scaled (shape/scale s 5)]
        (should= [1 2] (::square/top-left scaled))
        (should= 10 (::square/side scaled)))))

  (context "Circle (Leaf)"
    (it "円を作成できる"
      (let [c (circle/make-circle [5 6] 10)]
        (should= [5 6] (::circle/center c))
        (should= 10 (::circle/radius c))))

    (it "円を移動できる"
      (let [c (circle/make-circle [3 4] 10)
            translated (shape/translate c 2 3)]
        (should= [5 7] (::circle/center translated))
        (should= 10 (::circle/radius translated))))

    (it "円を拡大できる"
      (let [c (circle/make-circle [1 2] 2)
            scaled (shape/scale c 5)]
        (should= [1 2] (::circle/center scaled))
        (should= 10 (::circle/radius scaled)))))

  (context "CompositeShape (Composite)"
    (it "空の複合形状を作成できる"
      (let [composite (cs/make)]
        (should= [] (::cs/shapes composite))))

    (it "複合形状に形状を追加できる"
      (let [composite (-> (cs/make)
                          (cs/add (square/make-square [0 0] 1))
                          (cs/add (circle/make-circle [10 10] 10)))]
        (should= 2 (count (::cs/shapes composite)))))

    (it "複合形状を移動すると全ての形状が移動する"
      (let [composite (-> (cs/make)
                          (cs/add (square/make-square [0 0] 1))
                          (cs/add (circle/make-circle [10 10] 10)))
            translated (shape/translate composite 3 4)]
        (should= #{{::shape/type ::square/square
                    ::square/top-left [3 4]
                    ::square/side 1}
                   {::shape/type ::circle/circle
                    ::circle/center [13 14]
                    ::circle/radius 10}}
                 (set (::cs/shapes translated)))))

    (it "複合形状を拡大すると全ての形状が拡大する"
      (let [composite (-> (cs/make)
                          (cs/add (square/make-square [0 0] 1))
                          (cs/add (circle/make-circle [10 10] 10)))
            scaled (shape/scale composite 12)]
        (should= #{{::shape/type ::square/square
                    ::square/top-left [0 0]
                    ::square/side 12}
                   {::shape/type ::circle/circle
                    ::circle/center [10 10]
                    ::circle/radius 120}}
                 (set (::cs/shapes scaled)))))))

(run-specs)
