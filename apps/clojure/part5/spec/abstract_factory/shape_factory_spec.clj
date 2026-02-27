(ns abstract-factory.shape-factory-spec
  (:require [speclj.core :refer :all]
            [abstract-factory.shape :as shape]
            [abstract-factory.shape-factory :as factory]
            [abstract-factory.circle :as circle]
            [abstract-factory.square :as square]
            [abstract-factory.rectangle :as rectangle]
            [abstract-factory.standard-shape-factory :as standard]
            [abstract-factory.outlined-shape-factory :as outlined]
            [abstract-factory.filled-shape-factory :as filled]))

(describe "Abstract Factory パターン - ShapeFactory"

  (context "StandardShapeFactory"
    (it "ファクトリを作成できる"
      (let [factory (standard/make)]
        (should= :abstract-factory.standard-shape-factory/standard-factory
                 (:abstract-factory.shape-factory/type factory))))

    (it "円を生成できる"
      (let [factory (standard/make)
            circle (factory/make-shape factory :circle [10 20] 5)]
        (should= [10 20] (::circle/center circle))
        (should= 5 (::circle/radius circle))))

    (it "正方形を生成できる"
      (let [factory (standard/make)
            square (factory/make-shape factory :square [0 0] 10)]
        (should= [0 0] (::square/top-left square))
        (should= 10 (::square/side square))))

    (it "長方形を生成できる"
      (let [factory (standard/make)
            rect (factory/make-shape factory :rectangle [5 5] 20 10)]
        (should= [5 5] (::rectangle/top-left rect))
        (should= 20 (::rectangle/width rect))
        (should= 10 (::rectangle/height rect))))

    (it "生成した図形を操作できる"
      (let [factory (standard/make)
            circle (factory/make-shape factory :circle [10 10] 5)
            moved (shape/translate circle 5 5)]
        (should= [15 15] (::circle/center moved)))))

  (context "OutlinedShapeFactory"
    (it "輪郭線付き円を生成できる"
      (let [factory (outlined/make "black" 2)
            circle (factory/make-shape factory :circle [10 20] 5)]
        (should= [10 20] (::circle/center circle))
        (should= 5 (::circle/radius circle))
        (should= "black" (::outlined/outline-color circle))
        (should= 2 (::outlined/outline-width circle))))

    (it "輪郭線付き正方形を生成できる"
      (let [factory (outlined/make "red" 3)
            square (factory/make-shape factory :square [0 0] 10)]
        (should= "red" (::outlined/outline-color square))
        (should= 3 (::outlined/outline-width square)))))

  (context "FilledShapeFactory"
    (it "塗りつぶし付き円を生成できる"
      (let [factory (filled/make "blue")
            circle (factory/make-shape factory :circle [10 20] 5)]
        (should= [10 20] (::circle/center circle))
        (should= "blue" (::filled/fill-color circle))))

    (it "塗りつぶし付き長方形を生成できる"
      (let [factory (filled/make "green")
            rect (factory/make-shape factory :rectangle [0 0] 20 10)]
        (should= "green" (::filled/fill-color rect)))))

  (context "ファクトリの交換"
    (it "同じコードで異なるファクトリを使用できる"
      (let [create-shapes (fn [factory]
                            [(factory/make-shape factory :circle [0 0] 10)
                             (factory/make-shape factory :square [0 0] 5)])
            standard-shapes (create-shapes (standard/make))
            outlined-shapes (create-shapes (outlined/make "black" 1))]
        (should= 2 (count standard-shapes))
        (should= 2 (count outlined-shapes))
        (should-not (contains? (first standard-shapes) ::outlined/outline-color))
        (should (contains? (first outlined-shapes) ::outlined/outline-color))))))

(run-specs)
