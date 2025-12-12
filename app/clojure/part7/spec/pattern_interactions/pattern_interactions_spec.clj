(ns pattern-interactions.pattern-interactions-spec
  (:require [speclj.core :refer :all]
            [pattern-interactions.shape :as shape]
            [pattern-interactions.composite-shape :as composite]
            [pattern-interactions.decorated-shape :as decorated]
            [pattern-interactions.observer :as obs]
            [pattern-interactions.command :as cmd]
            [pattern-interactions.command-observer :as cmd-obs]))

(describe "Composite + Decorator パターンの組み合わせ"

  (describe "基本図形"
    (it "円を作成して移動できる"
      (let [circle (shape/make-circle 0 0 10)
            moved (shape/move circle 5 3)]
        (should= 5 (:x moved))
        (should= 3 (:y moved))
        (should= 10 (:radius moved))))

    (it "矩形を作成して拡大できる"
      (let [rect (shape/make-rectangle 0 0 10 20)
            scaled (shape/scale rect 2)]
        (should= 20 (:width scaled))
        (should= 40 (:height scaled)))))

  (describe "Composite パターン"
    (it "複合図形を作成できる"
      (let [comp (composite/make-composite)]
        (should= :composite (:type comp))
        (should= [] (:shapes comp))))

    (it "複合図形に図形を追加できる"
      (let [circle (shape/make-circle 0 0 10)
            rect (shape/make-rectangle 0 0 10 20)
            comp (-> (composite/make-composite)
                     (composite/add-shape circle)
                     (composite/add-shape rect))]
        (should= 2 (count (:shapes comp)))))

    (it "複合図形を一括移動できる"
      (let [circle (shape/make-circle 0 0 10)
            rect (shape/make-rectangle 0 0 10 20)
            comp (-> (composite/make-composite)
                     (composite/add-shape circle)
                     (composite/add-shape rect))
            moved (shape/move comp 5 3)]
        (should= 5 (:x (first (:shapes moved))))
        (should= 5 (:x (second (:shapes moved))))))

    (it "複合図形の合計面積を計算できる"
      (let [circle (shape/make-circle 0 0 10)
            rect (shape/make-rectangle 0 0 10 20)
            comp (-> (composite/make-composite)
                     (composite/add-shape circle)
                     (composite/add-shape rect))
            expected (+ (* Math/PI 100) 200)]
        (should (< (Math/abs (- expected (shape/area comp))) 0.001)))))

  (describe "Decorator パターン"
    (it "ジャーナル付き図形で操作を記録できる"
      (let [circle (shape/make-circle 0 0 10)
            journaled (decorated/make-journaled circle)
            after-move (shape/move journaled 5 3)
            after-scale (shape/scale after-move 2)]
        (should= 2 (count (decorated/get-journal after-scale)))
        (should= "move(5, 3)" (:operation (first (decorated/get-journal after-scale))))))

    (it "色付き図形を作成できる"
      (let [circle (shape/make-circle 0 0 10)
            colored (decorated/make-colored circle "red")]
        (should= "red" (decorated/get-color colored))
        (should-contain "[red]" (shape/draw colored))))

    (it "境界線付き図形を作成できる"
      (let [rect (shape/make-rectangle 0 0 10 20)
            bordered (decorated/make-bordered rect 2)]
        (should= 2 (decorated/get-border-width bordered))
        (should-contain "[Border: 2px]" (shape/draw bordered)))))

  (describe "Composite + Decorator の組み合わせ"
    (it "複合図形にデコレータを適用できる"
      (let [circle (shape/make-circle 0 0 10)
            rect (shape/make-rectangle 0 0 10 20)
            comp (-> (composite/make-composite)
                     (composite/add-shape circle)
                     (composite/add-shape rect))
            journaled (decorated/make-journaled comp)
            after-move (shape/move journaled 5 3)]
        (should= 1 (count (decorated/get-journal after-move)))))

    (it "デコレートされた図形を複合図形に含められる"
      (let [colored-circle (-> (shape/make-circle 0 0 10)
                               (decorated/make-colored "red"))
            bordered-rect (-> (shape/make-rectangle 0 0 10 20)
                              (decorated/make-bordered 2))
            comp (-> (composite/make-composite)
                     (composite/add-shape colored-circle)
                     (composite/add-shape bordered-rect))]
        (should-contain "[red]" (shape/draw comp))
        (should-contain "[Border: 2px]" (shape/draw comp))))

    (it "多重デコレータを適用できる"
      (let [circle (shape/make-circle 0 0 10)
            decorated-circle (-> circle
                                 (decorated/make-colored "blue")
                                 (decorated/make-bordered 3)
                                 (decorated/make-journaled))]
        (should-contain "[Journaled:" (shape/draw decorated-circle))
        (should-contain "[Border: 3px]" (shape/draw decorated-circle))
        (should-contain "[blue]" (shape/draw decorated-circle))))))

(describe "Command + Observer パターンの組み合わせ"

  (describe "Observer パターン"
    (it "サブジェクトを作成できる"
      (let [subject (obs/make-subject)]
        (should-not-be-nil subject)))

    (it "オブザーバーに通知できる"
      (let [subject (obs/make-subject)
            notifications (atom [])
            observer (fn [event] (swap! notifications conj event))]
        (obs/add-observer subject observer)
        (obs/notify-observers subject {:type :test :value 42})
        (should= 1 (count @notifications))
        (should= :test (:type (first @notifications))))))

  (describe "Command パターン"
    (it "図形追加コマンドを実行できる"
      (let [circle (shape/make-circle 0 0 10)
            cmd (cmd/make-add-shape-command circle)
            canvas {:shapes []}
            executor (cmd/execute cmd)
            result (executor canvas)]
        (should= 1 (count (:shapes result)))))

    (it "図形移動コマンドを実行できる"
      (let [circle (shape/make-circle 0 0 10)
            move-cmd (cmd/make-move-shape-command 0 5 3)
            canvas {:shapes [circle]}
            executor (cmd/execute move-cmd)
            result (executor canvas)]
        (should= 5 (:x (first (:shapes result))))
        (should= 3 (:y (first (:shapes result))))))

    (it "マクロコマンドを実行できる"
      (let [circle (shape/make-circle 0 0 10)
            add-cmd (cmd/make-add-shape-command circle)
            move-cmd (cmd/make-move-shape-command 0 5 3)
            macro (cmd/make-macro-command [add-cmd move-cmd])
            canvas {:shapes []}
            executor (cmd/execute macro)
            result (executor canvas)]
        (should= 1 (count (:shapes result)))
        (should= 5 (:x (first (:shapes result)))))))

  (describe "Command + Observer の統合"
    (it "オブザーバブルキャンバスを作成できる"
      (let [canvas (cmd-obs/make-observable-canvas)]
        (should= [] (cmd-obs/get-shapes canvas))
        (should= [] (cmd-obs/get-history canvas))))

    (it "コマンド実行時にオブザーバーに通知される"
      (let [canvas (cmd-obs/make-observable-canvas)
            notifications (atom [])
            observer (fn [event] (swap! notifications conj event))
            _ (cmd-obs/add-observer canvas observer)
            circle (shape/make-circle 0 0 10)
            cmd (cmd/make-add-shape-command circle)
            new-canvas (cmd-obs/execute-command canvas cmd)]
        (should= 1 (count @notifications))
        (should= :command-executed (:type (first @notifications)))))

    (it "Undo/Redo が機能する"
      (let [canvas (cmd-obs/make-observable-canvas)
            circle (shape/make-circle 0 0 10)
            cmd (cmd/make-add-shape-command circle)
            after-add (cmd-obs/execute-command canvas cmd)
            after-undo (cmd-obs/undo-last after-add)
            after-redo (cmd-obs/redo-last after-undo)]
        (should= 1 (count (cmd-obs/get-shapes after-add)))
        (should= 0 (count (cmd-obs/get-shapes after-undo)))
        (should= 1 (count (cmd-obs/get-shapes after-redo)))))

    (it "Undo 時にオブザーバーに通知される"
      (let [canvas (cmd-obs/make-observable-canvas)
            notifications (atom [])
            observer (fn [event] (swap! notifications conj event))
            _ (cmd-obs/add-observer canvas observer)
            circle (shape/make-circle 0 0 10)
            cmd (cmd/make-add-shape-command circle)
            after-add (cmd-obs/execute-command canvas cmd)
            _ (cmd-obs/undo-last after-add)]
        (should= 2 (count @notifications))
        (should= :command-undone (:type (second @notifications)))))))

(run-specs)
