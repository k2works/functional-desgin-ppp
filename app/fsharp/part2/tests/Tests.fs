module Tests

open System
open Xunit
open FunctionalDesign.Part2.Validation

// ============================================
// 第4章: データバリデーション
// ============================================

// ============================================
// 1. 基本的なバリデーション
// ============================================

module BasicValidationTests =

    [<Fact>]
    let ``validateName は有効な名前を受け入れる`` () =
        let result = validateName "田中太郎"
        Assert.Equal(Ok "田中太郎", result)

    [<Fact>]
    let ``validateName は空の名前を拒否`` () =
        let result = validateName ""

        match result with
        | Error errors -> Assert.Contains("名前は空にできません", errors)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``validateName は100文字を超える名前を拒否`` () =
        let longName = String.replicate 101 "a"
        let result = validateName longName

        match result with
        | Error errors -> Assert.Contains("名前は100文字以内である必要があります", errors)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``validateAge は有効な年齢を受け入れる`` () =
        let result = validateAge 25
        Assert.Equal(Ok 25, result)

    [<Fact>]
    let ``validateAge は負の年齢を拒否`` () =
        let result = validateAge -1

        match result with
        | Error errors -> Assert.Contains("年齢は0以上である必要があります", errors)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``validateAge は150歳を超える年齢を拒否`` () =
        let result = validateAge 200

        match result with
        | Error errors -> Assert.Contains("年齢は150以下である必要があります", errors)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``validateEmail は有効なメールを受け入れる`` () =
        let result = validateEmail "test@example.com"
        Assert.Equal(Ok "test@example.com", result)

    [<Fact>]
    let ``validateEmail は無効なメールを拒否`` () =
        let result = validateEmail "invalid-email"

        match result with
        | Error errors -> Assert.Contains("無効なメールアドレス形式です", errors)
        | Ok _ -> Assert.Fail("Expected error")

// ============================================
// 2. 列挙型
// ============================================

module MembershipTests =

    [<Fact>]
    let ``Membership.fromString は有効な値を受け入れる`` () =
        Assert.Equal(Ok Bronze, Membership.fromString "bronze")
        Assert.Equal(Ok Silver, Membership.fromString "silver")
        Assert.Equal(Ok Gold, Membership.fromString "gold")
        Assert.Equal(Ok Platinum, Membership.fromString "platinum")

    [<Fact>]
    let ``Membership.fromString は大文字小文字を区別しない`` () =
        Assert.Equal(Ok Gold, Membership.fromString "GOLD")
        Assert.Equal(Ok Gold, Membership.fromString "Gold")

    [<Fact>]
    let ``Membership.fromString は無効な値を拒否`` () =
        let result = Membership.fromString "invalid"

        match result with
        | Error errors -> Assert.Contains("無効な会員種別: invalid", errors)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``Membership.toString は正しい文字列を返す`` () =
        Assert.Equal("gold", Membership.toString Gold)
        Assert.Equal("bronze", Membership.toString Bronze)

// ============================================
// 3. Validated パターン
// ============================================

module ValidatedTests =

    [<Fact>]
    let ``Validated.valid は Valid を作成`` () =
        let result = Validated.valid 42
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``Validated.invalid は Invalid を作成`` () =
        let result: Validated<string, int> = Validated.invalid [ "error" ]
        Assert.False(Validated.isValid result)

    [<Fact>]
    let ``Validated.map は値を変換`` () =
        let result = Validated.valid 5 |> Validated.map (fun x -> x * 2)

        match result with
        | Valid v -> Assert.Equal(10, v)
        | Invalid _ -> Assert.Fail("Expected Valid")

    [<Fact>]
    let ``Validated.combine は両方 Valid のとき成功`` () =
        let result = Validated.combine (fun a b -> a + b) (Validated.valid 1) (Validated.valid 2)

        match result with
        | Valid v -> Assert.Equal(3, v)
        | Invalid _ -> Assert.Fail("Expected Valid")

    [<Fact>]
    let ``Validated.combine はエラーを蓄積`` () =
        let va: Validated<string, int> = Validated.invalid [ "error1" ]
        let vb: Validated<string, int> = Validated.invalid [ "error2" ]
        let result = Validated.combine (+) va vb

        match result with
        | Invalid errors ->
            Assert.Contains("error1", errors)
            Assert.Contains("error2", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``Validated.toResult は正しく変換`` () =
        Assert.Equal(Ok 42, Validated.toResult (Validated.valid 42))
        Assert.Equal(Error [ "err" ], Validated.toResult (Validated.invalid [ "err" ]))

// ============================================
// 4. ドメインプリミティブ
// ============================================

module DomainPrimitiveTests =

    [<Fact>]
    let ``ProductId.create は有効なIDを受け入れる`` () =
        let result = ProductId.create "PROD-00001"
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``ProductId.create は無効なIDを拒否`` () =
        let result = ProductId.create "INVALID"

        match result with
        | Invalid errors -> Assert.True(errors |> List.exists (fun e -> e.Contains("無効な商品ID形式")))
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``ProductId.value は値を取得`` () =
        let pid = ProductId.unsafe "PROD-12345"
        Assert.Equal("PROD-12345", ProductId.value pid)

    [<Fact>]
    let ``ProductName.create は有効な名前を受け入れる`` () =
        let result = ProductName.create "テスト商品"
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``ProductName.create は空の名前を拒否`` () =
        let result = ProductName.create ""

        match result with
        | Invalid errors -> Assert.Contains("商品名は空にできません", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``Price.create は正の価格を受け入れる`` () =
        let result = Price.create 1000m
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``Price.create はゼロ以下の価格を拒否`` () =
        let result = Price.create 0m

        match result with
        | Invalid errors -> Assert.Contains("価格は正の数である必要があります", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``Quantity.create は正の数量を受け入れる`` () =
        let result = Quantity.create 5
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``Quantity.create はゼロ以下の数量を拒否`` () =
        let result = Quantity.create 0

        match result with
        | Invalid errors -> Assert.Contains("数量は正の整数である必要があります", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

// ============================================
// 5. 商品モデル
// ============================================

module ProductTests =

    [<Fact>]
    let ``Product.create は有効な商品を作成`` () =
        let result = Product.create "PROD-00001" "テスト商品" 1000m None None
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``Product.create は複数のエラーを蓄積`` () =
        let result = Product.create "INVALID" "" -100m None None

        match result with
        | Invalid errors ->
            Assert.True(errors.Length >= 3)
            Assert.True(errors |> List.exists (fun e -> e.Contains("商品ID")))
            Assert.True(errors |> List.exists (fun e -> e.Contains("商品名")))
            Assert.True(errors |> List.exists (fun e -> e.Contains("価格")))
        | Valid _ -> Assert.Fail("Expected Invalid")

// ============================================
// 6. 注文ドメインモデル
// ============================================

module OrderTests =

    [<Fact>]
    let ``OrderId.create は有効なIDを受け入れる`` () =
        let result = OrderId.create "ORD-12345678"
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``CustomerId.create は有効なIDを受け入れる`` () =
        let result = CustomerId.create "CUST-123456"
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``OrderItem.create は有効なアイテムを作成`` () =
        let result = OrderItem.create "PROD-00001" 2 1000m
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``OrderItem.total は正しく計算`` () =
        let item =
            { ProductId = ProductId.unsafe "PROD-00001"
              Quantity = Quantity.unsafe 3
              Price = Price.unsafe 500m }

        Assert.Equal(1500m, OrderItem.total item)

    [<Fact>]
    let ``Order.calculateTotal は全アイテムの合計を計算`` () =
        let item1 =
            { ProductId = ProductId.unsafe "PROD-00001"
              Quantity = Quantity.unsafe 2
              Price = Price.unsafe 1000m }

        let item2 =
            { ProductId = ProductId.unsafe "PROD-00002"
              Quantity = Quantity.unsafe 3
              Price = Price.unsafe 500m }

        let order =
            { OrderId = OrderId.unsafe "ORD-12345678"
              CustomerId = CustomerId.unsafe "CUST-123456"
              Items = [ item1; item2 ]
              OrderDate = DateTime.Now
              Total = None
              Status = None }

        // 2000 + 1500 = 3500
        Assert.Equal(3500m, Order.calculateTotal order)

// ============================================
// 7. 条件付きバリデーション
// ============================================

module NotificationTests =

    [<Fact>]
    let ``createEmail は有効なメール通知を作成`` () =
        let result = Notification.createEmail "test@example.com" "件名" "本文"
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``createEmail は無効なメールアドレスを拒否`` () =
        let result = Notification.createEmail "invalid" "件名" "本文"

        match result with
        | Invalid errors -> Assert.Contains("無効なメールアドレス形式です", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``createEmail は複数のエラーを蓄積`` () =
        let result = Notification.createEmail "invalid" "" ""

        match result with
        | Invalid errors ->
            Assert.True(errors.Length >= 3)
            Assert.Contains("無効なメールアドレス形式です", errors)
            Assert.Contains("件名は空にできません", errors)
            Assert.Contains("本文は空にできません", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``createSMS は有効なSMS通知を作成`` () =
        let result = Notification.createSMS "090-1234-5678" "本文"
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``createSMS は無効な電話番号を拒否`` () =
        let result = Notification.createSMS "invalid" "本文"

        match result with
        | Invalid errors -> Assert.Contains("無効な電話番号形式です", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``createPush は有効なプッシュ通知を作成`` () =
        let result = Notification.createPush "device-token-123" "本文"
        Assert.True(Validated.isValid result)

    [<Fact>]
    let ``createPush は空のトークンを拒否`` () =
        let result = Notification.createPush "" "本文"

        match result with
        | Invalid errors -> Assert.Contains("デバイストークンは空にできません", errors)
        | Valid _ -> Assert.Fail("Expected Invalid")

    [<Fact>]
    let ``Notification.getBody は本文を取得`` () =
        Assert.Equal(
            "本文",
            EmailNotification("test@example.com", "件名", "本文")
            |> Notification.getBody
        )

        Assert.Equal("SMS本文", SMSNotification("090-0000-0000", "SMS本文") |> Notification.getBody)
        Assert.Equal("プッシュ本文", PushNotification("token", "プッシュ本文") |> Notification.getBody)

// ============================================
// 8. バリデーションユーティリティ
// ============================================

module ValidationUtilityTests =

    [<Fact>]
    let ``validatePerson は有効な人物データを検証`` () =
        let response = validatePerson "田中" 30 None
        Assert.True(response.Valid)
        Assert.True(response.Data.IsSome)
        Assert.Empty(response.Errors)

    [<Fact>]
    let ``validatePerson は無効なデータでエラーを返す`` () =
        let response = validatePerson "" -1 None
        Assert.False(response.Valid)
        Assert.True(response.Data.IsNone)
        Assert.Contains("名前は空にできません", response.Errors)
        Assert.Contains("年齢は0以上である必要があります", response.Errors)

    [<Fact>]
    let ``conformOrThrow は Valid で値を返す`` () =
        let value = conformOrThrow (Validated.valid 42)
        Assert.Equal(42, value)

    [<Fact>]
    let ``conformOrThrow は Invalid で例外を投げる`` () =
        Assert.Throws<Exception>(fun () ->
            conformOrThrow (Validated.invalid [ "error1"; "error2" ])
            |> ignore)

// ============================================
// 9. 計算関数
// ============================================

module CalculationTests =

    [<Fact>]
    let ``calculateItemTotal は正しく計算`` () =
        let item =
            { ProductId = ProductId.unsafe "PROD-00001"
              Quantity = Quantity.unsafe 3
              Price = Price.unsafe 1000m }

        Assert.Equal(3000m, calculateItemTotal item)

    [<Fact>]
    let ``applyDiscount は有効な割引率で計算`` () =
        let result = applyDiscount 1000m 0.1
        Assert.Equal(Ok 900m, result)

    [<Fact>]
    let ``applyDiscount は無効な割引率でエラー`` () =
        let result = applyDiscount 1000m 1.5

        match result with
        | Error msg -> Assert.Contains("0から1の間", msg)
        | Ok _ -> Assert.Fail("Expected error")

    [<Fact>]
    let ``sumPrices は複数の価格を合計`` () =
        let result = sumPrices [ 100m; 200m; 300m ]
        Assert.Equal(600m, result)

