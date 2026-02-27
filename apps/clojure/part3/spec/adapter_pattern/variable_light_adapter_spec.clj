(ns adapter-pattern.variable-light-adapter-spec
  (:require [speclj.core :refer :all]
            [adapter-pattern.switchable :as s]
            [adapter-pattern.variable-light :as vl]
            [adapter-pattern.variable-light-adapter :as adapter]
            [adapter-pattern.engage-switch :as client]))

(describe "Adapter パターン - VariableLightAdapter"

  (context "アダプターの作成"
    (it "最小/最大強度でアダプターを作成できる"
      (let [adapter (adapter/make-adapter 0 100)]
        (should= :variable-light-adapter (:type adapter))
        (should= 0 (:min-intensity adapter))
        (should= 100 (:max-intensity adapter)))))

  (context "Switchable インターフェース"
    (with-stubs)

    (it "turn-on で最大強度が設定される"
      (with-redefs [vl/turn-on-light (stub :turn-on-light
                                           {:return {:intensity 100}})]
        (let [adapter (adapter/make-adapter 0 100)
              result (s/turn-on adapter)]
          (should-have-invoked :turn-on-light {:with [100]})
          (should= {:intensity 100} result))))

    (it "turn-off で最小強度が設定される"
      (with-redefs [vl/turn-on-light (stub :turn-on-light
                                           {:return {:intensity 0}})]
        (let [adapter (adapter/make-adapter 0 100)
              result (s/turn-off adapter)]
          (should-have-invoked :turn-on-light {:with [0]})
          (should= {:intensity 0} result)))))

  (context "クライアント統合"
    (with-stubs)

    (it "クライアントがアダプターを通じてライトを操作できる"
      (with-redefs [vl/turn-on-light (stub :turn-on-light
                                           {:return {:intensity 50}})]
        (let [adapter (adapter/make-adapter 10 90)
              result (client/engage-switch adapter)]
          (should-have-invoked :turn-on-light {:times 2}))))))

(run-specs)
