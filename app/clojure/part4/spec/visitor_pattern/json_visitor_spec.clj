(ns visitor-pattern.json-visitor-spec
  (:require [speclj.core :refer :all]
            [visitor-pattern.json-visitor :as json]
            [visitor-pattern.circle :as circle]
            [visitor-pattern.square :as square]
            [visitor-pattern.rectangle :as rectangle]))

(describe "Visitor パターン - JSON Visitor"

  (context "単一図形の変換"
    (it "円を JSON に変換できる"
      (let [c (circle/make [10 20] 5)]
        (should= "{\"type\":\"circle\",\"center\":[10,20],\"radius\":5}"
                 (json/to-json c))))

    (it "正方形を JSON に変換できる"
      (let [s (square/make [0 0] 10)]
        (should= "{\"type\":\"square\",\"topLeft\":[0,0],\"side\":10}"
                 (json/to-json s))))

    (it "長方形を JSON に変換できる"
      (let [r (rectangle/make [5 5] 20 10)]
        (should= "{\"type\":\"rectangle\",\"topLeft\":[5,5],\"width\":20,\"height\":10}"
                 (json/to-json r)))))

  (context "複数図形の変換"
    (it "複数の図形を JSON 配列に変換できる"
      (let [shapes [(circle/make [0 0] 5)
                    (square/make [10 10] 8)]]
        (should= "[{\"type\":\"circle\",\"center\":[0,0],\"radius\":5},{\"type\":\"square\",\"topLeft\":[10,10],\"side\":8}]"
                 (json/shapes-to-json shapes))))))

(run-specs)
