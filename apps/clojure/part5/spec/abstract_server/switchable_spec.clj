(ns abstract-server.switchable-spec
  (:require [speclj.core :refer :all]
            [abstract-server.switchable :as switchable]
            [abstract-server.switch :as sw]
            [abstract-server.light :as light]
            [abstract-server.fan :as fan]
            [abstract-server.motor :as motor]))

(describe "Abstract Server パターン - Switchable"

  (context "Light"
    (it "照明を作成できる"
      (let [l (light/make)]
        (should-not (switchable/is-on? l))))

    (it "照明をオンにできる"
      (let [l (light/make)
            l-on (switchable/turn-on l)]
        (should (switchable/is-on? l-on))))

    (it "照明をオフにできる"
      (let [l (light/make-on)
            l-off (switchable/turn-off l)]
        (should-not (switchable/is-on? l-off)))))

  (context "Fan"
    (it "扇風機を作成できる"
      (let [f (fan/make)]
        (should-not (switchable/is-on? f))))

    (it "扇風機をオンにすると速度が設定される"
      (let [f (fan/make)
            f-on (switchable/turn-on f)]
        (should (switchable/is-on? f-on))
        (should= :low (:speed f-on))))

    (it "扇風機の速度を変更できる"
      (let [f (-> (fan/make)
                  switchable/turn-on
                  (fan/set-speed :high))]
        (should= :high (:speed f)))))

  (context "Motor"
    (it "モーターを作成できる"
      (let [m (motor/make)]
        (should-not (switchable/is-on? m))))

    (it "モーターをオンにすると方向が設定される"
      (let [m (motor/make)
            m-on (switchable/turn-on m)]
        (should (switchable/is-on? m-on))
        (should= :forward (:direction m-on))))

    (it "モーターの方向を反転できる"
      (let [m (-> (motor/make)
                  switchable/turn-on
                  motor/reverse-direction)]
        (should= :reverse (:direction m)))))

  (context "Switch（抽象に依存）"
    (it "任意のSwitchableデバイスをengageできる"
      (let [light-on (sw/engage (light/make))
            fan-on (sw/engage (fan/make))
            motor-on (sw/engage (motor/make))]
        (should (switchable/is-on? light-on))
        (should (switchable/is-on? fan-on))
        (should (switchable/is-on? motor-on))))

    (it "任意のSwitchableデバイスをdisengageできる"
      (let [light-off (sw/disengage (light/make-on))
            fan-off (sw/disengage (switchable/turn-on (fan/make)))]
        (should-not (switchable/is-on? light-off))
        (should-not (switchable/is-on? fan-off))))

    (it "任意のSwitchableデバイスをtoggleできる"
      (let [l (light/make)
            l-toggled (sw/toggle l)
            l-toggled-again (sw/toggle l-toggled)]
        (should (switchable/is-on? l-toggled))
        (should-not (switchable/is-on? l-toggled-again))))

    (it "デバイスの状態を取得できる"
      (let [l-off (light/make)
            l-on (light/make-on)]
        (should= :off (sw/status l-off))
        (should= :on (sw/status l-on))))))

(run-specs)
