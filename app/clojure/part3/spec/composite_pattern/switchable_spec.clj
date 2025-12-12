(ns composite-pattern.switchable-spec
  (:require [speclj.core :refer :all]
            [composite-pattern.switchable :as s]
            [composite-pattern.light :as l]
            [composite-pattern.variable-light :as v]
            [composite-pattern.composite-switchable :as cs]))

(describe "Composite パターン - Switchable"

  (context "Light (Leaf)"
    (with-stubs)

    (it "ライトをオンにできる"
      (with-redefs [l/turn-on-light (stub :turn-on-light)]
        (let [light (l/make-light)
              turned-on (s/turn-on light)]
          (should-have-invoked :turn-on-light)
          (should (:on turned-on)))))

    (it "ライトをオフにできる"
      (with-redefs [l/turn-off-light (stub :turn-off-light)]
        (let [light (assoc (l/make-light) :on true)
              turned-off (s/turn-off light)]
          (should-have-invoked :turn-off-light)
          (should-not (:on turned-off))))))

  (context "VariableLight (Leaf)"
    (with-stubs)

    (it "調光ライトをオンにすると強度100になる"
      (with-redefs [v/set-light-intensity (stub :set-intensity)]
        (let [vlight (v/make-variable-light)
              turned-on (s/turn-on vlight)]
          (should-have-invoked :set-intensity {:with [100]})
          (should= 100 (:intensity turned-on)))))

    (it "調光ライトをオフにすると強度0になる"
      (with-redefs [v/set-light-intensity (stub :set-intensity)]
        (let [vlight (assoc (v/make-variable-light) :intensity 100)
              turned-off (s/turn-off vlight)]
          (should-have-invoked :set-intensity {:with [0]})
          (should= 0 (:intensity turned-off))))))

  (context "CompositeSwitchable (Composite)"
    (with-stubs)

    (it "空の複合スイッチを作成できる"
      (let [composite (cs/make-composite-switchable)]
        (should= [] (:switchables composite))))

    (it "複合スイッチに要素を追加できる"
      (let [composite (-> (cs/make-composite-switchable)
                          (cs/add (l/make-light))
                          (cs/add (v/make-variable-light)))]
        (should= 2 (count (:switchables composite)))))

    (it "複合スイッチをオンにすると全ての要素がオンになる"
      (with-redefs [l/turn-on-light (stub :turn-on-light)
                    v/set-light-intensity (stub :set-intensity)]
        (let [composite (-> (cs/make-composite-switchable)
                            (cs/add (l/make-light))
                            (cs/add (v/make-variable-light)))
              turned-on (s/turn-on composite)]
          (should-have-invoked :turn-on-light)
          (should-have-invoked :set-intensity {:with [100]}))))

    (it "複合スイッチをオフにすると全ての要素がオフになる"
      (with-redefs [l/turn-off-light (stub :turn-off-light)
                    v/set-light-intensity (stub :set-intensity)]
        (let [composite (-> (cs/make-composite-switchable)
                            (cs/add (l/make-light))
                            (cs/add (v/make-variable-light)))
              turned-off (s/turn-off composite)]
          (should-have-invoked :turn-off-light)
          (should-have-invoked :set-intensity {:with [0]}))))))

(run-specs)
