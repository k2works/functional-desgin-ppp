(ns visitor-pattern.xml-visitor-spec
  (:require [speclj.core :refer :all]
            [visitor-pattern.xml-visitor :as xml]
            [visitor-pattern.circle :as circle]
            [visitor-pattern.square :as square]
            [visitor-pattern.rectangle :as rectangle]))

(describe "Visitor パターン - XML Visitor"

  (context "単一図形の変換"
    (it "円を XML に変換できる"
      (let [c (circle/make [10 20] 5)]
        (should= "<circle><center x=\"10\" y=\"20\"/><radius>5</radius></circle>"
                 (xml/to-xml c))))

    (it "正方形を XML に変換できる"
      (let [s (square/make [0 0] 10)]
        (should= "<square><topLeft x=\"0\" y=\"0\"/><side>10</side></square>"
                 (xml/to-xml s))))

    (it "長方形を XML に変換できる"
      (let [r (rectangle/make [5 5] 20 10)]
        (should= "<rectangle><topLeft x=\"5\" y=\"5\"/><width>20</width><height>10</height></rectangle>"
                 (xml/to-xml r)))))

  (context "複数図形の変換"
    (it "複数の図形を XML ドキュメントに変換できる"
      (let [shapes [(circle/make [0 0] 5)
                    (square/make [10 10] 8)]]
        (should= "<shapes><circle><center x=\"0\" y=\"0\"/><radius>5</radius></circle><square><topLeft x=\"10\" y=\"10\"/><side>8</side></square></shapes>"
                 (xml/shapes-to-xml shapes))))))

(run-specs)
