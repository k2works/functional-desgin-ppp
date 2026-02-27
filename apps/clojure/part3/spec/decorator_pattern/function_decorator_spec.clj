(ns decorator-pattern.function-decorator-spec
  (:require [speclj.core :refer :all]
            [decorator-pattern.function-decorator :refer :all]))

(describe "Decorator パターン - 関数デコレータ"

  (context "with-logging"
    (it "関数を実行しながらログを出力する"
      (let [add-logged (with-logging + "add")]
        (should= 5 (add-logged 2 3)))))

  (context "with-retry"
    (it "失敗時にリトライする"
      (let [counter (atom 0)
            flaky-fn (fn []
                       (swap! counter inc)
                       (if (< @counter 3)
                         (throw (Exception. "fail"))
                         "success"))
            retry-fn (with-retry flaky-fn 5)]
        (should= "success" (retry-fn))
        (should= 3 @counter)))

    (it "最大リトライ回数を超えると例外をスローする"
      (let [always-fail (fn [] (throw (Exception. "always fail")))
            retry-fn (with-retry always-fail 2)]
        (should-throw Exception (retry-fn)))))

  (context "with-cache"
    (it "キャッシュを使用して重複呼び出しを回避する"
      (let [call-count (atom 0)
            expensive-fn (fn [x]
                           (swap! call-count inc)
                           (* x x))
            cached-fn (with-cache expensive-fn)]
        (should= 4 (cached-fn 2))
        (should= 4 (cached-fn 2))  ;; キャッシュヒット
        (should= 9 (cached-fn 3))  ;; キャッシュミス
        (should= 2 @call-count))))

  (context "with-validation"
    (it "有効な入力で関数を実行する"
      (let [positive-only (with-validation
                            (fn [x] (* x 2))
                            (fn [x] (pos? x))
                            "Input must be positive")]
        (should= 10 (positive-only 5))))

    (it "無効な入力で例外をスローする"
      (let [positive-only (with-validation
                            (fn [x] (* x 2))
                            (fn [x] (pos? x))
                            "Input must be positive")]
        (should-throw clojure.lang.ExceptionInfo (positive-only -5)))))

  (context "compose-decorators"
    (it "複数のデコレータを組み合わせる"
      (let [call-count (atom 0)
            base-fn (fn [x]
                      (swap! call-count inc)
                      (* x x))
            decorated (compose-decorators
                        base-fn
                        with-cache
                        #(with-logging % "squared"))]
        (should= 4 (decorated 2))
        (should= 4 (decorated 2))  ;; キャッシュヒット
        (should= 1 @call-count)))))

(run-specs)
