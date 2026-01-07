namespace FunctionalDesign.Part2

// ============================================
// 第4章: データバリデーション
// ============================================

module Validation =

    // ============================================
    // 1. 基本的なバリデーション（Result を使用）
    // ============================================

    /// バリデーション結果の型エイリアス
    type ValidationResult<'T> = Result<'T, string list>

    /// 名前のバリデーション
    let validateName (name: string) : ValidationResult<string> =
        if System.String.IsNullOrEmpty(name) then
            Error [ "名前は空にできません" ]
        elif name.Length > 100 then
            Error [ "名前は100文字以内である必要があります" ]
        else
            Ok name

    /// 年齢のバリデーション
    let validateAge (age: int) : ValidationResult<int> =
        if age < 0 then
            Error [ "年齢は0以上である必要があります" ]
        elif age > 150 then
            Error [ "年齢は150以下である必要があります" ]
        else
            Ok age

    /// メールアドレスのバリデーション
    let validateEmail (email: string) : ValidationResult<string> =
        let emailRegex = System.Text.RegularExpressions.Regex(@".+@.+\..+")

        if emailRegex.IsMatch(email) then
            Ok email
        else
            Error [ "無効なメールアドレス形式です" ]

    // ============================================
    // 2. 列挙型とスマートコンストラクタ
    // ============================================

    /// 会員種別
    type Membership =
        | Bronze
        | Silver
        | Gold
        | Platinum

    module Membership =
        let fromString (s: string) : ValidationResult<Membership> =
            match s.ToLower() with
            | "bronze" -> Ok Bronze
            | "silver" -> Ok Silver
            | "gold" -> Ok Gold
            | "platinum" -> Ok Platinum
            | _ -> Error [ sprintf "無効な会員種別: %s" s ]

        let toString =
            function
            | Bronze -> "bronze"
            | Silver -> "silver"
            | Gold -> "gold"
            | Platinum -> "platinum"

    /// ステータス
    type Status =
        | Active
        | Inactive
        | Suspended

    // ============================================
    // 3. Validated パターン（エラー蓄積）
    // ============================================

    /// Validated 型（エラー蓄積対応）
    type Validated<'E, 'A> =
        | Valid of 'A
        | Invalid of 'E list

    module Validated =
        let valid a : Validated<'E, 'A> = Valid a
        let invalid errors : Validated<'E, 'A> = Invalid errors

        let map (f: 'A -> 'B) (va: Validated<'E, 'A>) : Validated<'E, 'B> =
            match va with
            | Valid a -> Valid(f a)
            | Invalid errs -> Invalid errs

        let flatMap (f: 'A -> Validated<'E, 'B>) (va: Validated<'E, 'A>) : Validated<'E, 'B> =
            match va with
            | Valid a -> f a
            | Invalid errs -> Invalid errs

        let isValid =
            function
            | Valid _ -> true
            | Invalid _ -> false

        let toResult =
            function
            | Valid a -> Ok a
            | Invalid errs -> Error errs

        /// 2つの Validated を結合（エラー蓄積）
        let combine
            (f: 'A -> 'B -> 'C)
            (va: Validated<'E, 'A>)
            (vb: Validated<'E, 'B>)
            : Validated<'E, 'C> =
            match va, vb with
            | Valid a, Valid b -> Valid(f a b)
            | Invalid e1, Invalid e2 -> Invalid(e1 @ e2) // エラーを蓄積！
            | Invalid e, _ -> Invalid e
            | _, Invalid e -> Invalid e

        /// 3つの Validated を結合
        let combine3
            (f: 'A -> 'B -> 'C -> 'D)
            (va: Validated<'E, 'A>)
            (vb: Validated<'E, 'B>)
            (vc: Validated<'E, 'C>)
            : Validated<'E, 'D> =
            match va, vb, vc with
            | Valid a, Valid b, Valid c -> Valid(f a b c)
            | _ ->
                let errors =
                    [ match va with
                      | Invalid e -> yield! e
                      | _ -> ()
                      match vb with
                      | Invalid e -> yield! e
                      | _ -> ()
                      match vc with
                      | Invalid e -> yield! e
                      | _ -> () ]

                Invalid errors

    // ============================================
    // 4. ドメインプリミティブ（バリデーション付き型）
    // ============================================

    /// 商品ID
    type ProductId = private ProductId of string

    module ProductId =
        let private pattern =
            System.Text.RegularExpressions.Regex(@"^PROD-\d{5}$")

        let create (id: string) : Validated<string, ProductId> =
            if pattern.IsMatch(id) then
                Validated.valid (ProductId id)
            else
                Validated.invalid [ sprintf "無効な商品ID形式: %s (PROD-XXXXXの形式が必要)" id ]

        let value (ProductId id) = id
        let unsafe id = ProductId id

    /// 商品名
    type ProductName = private ProductName of string

    module ProductName =
        let create (name: string) : Validated<string, ProductName> =
            if System.String.IsNullOrEmpty(name) then
                Validated.invalid [ "商品名は空にできません" ]
            elif name.Length > 200 then
                Validated.invalid [ "商品名は200文字以内である必要があります" ]
            else
                Validated.valid (ProductName name)

        let value (ProductName name) = name
        let unsafe name = ProductName name

    /// 価格（正の数）
    type Price = private Price of decimal

    module Price =
        let create (amount: decimal) : Validated<string, Price> =
            if amount <= 0m then
                Validated.invalid [ "価格は正の数である必要があります" ]
            else
                Validated.valid (Price amount)

        let value (Price p) = p
        let unsafe amount = Price amount

    /// 数量（正の整数）
    type Quantity = private Quantity of int

    module Quantity =
        let create (qty: int) : Validated<string, Quantity> =
            if qty <= 0 then
                Validated.invalid [ "数量は正の整数である必要があります" ]
            else
                Validated.valid (Quantity qty)

        let value (Quantity q) = q
        let unsafe qty = Quantity qty

    // ============================================
    // 5. 商品モデル
    // ============================================

    /// 商品
    type Product =
        { Id: ProductId
          Name: ProductName
          Price: Price
          Description: string option
          Category: string option }

    module Product =
        let create
            (id: string)
            (name: string)
            (price: decimal)
            (description: string option)
            (category: string option)
            : Validated<string, Product> =
            Validated.combine3
                (fun pid pname pprice ->
                    { Id = pid
                      Name = pname
                      Price = pprice
                      Description = description
                      Category = category })
                (ProductId.create id)
                (ProductName.create name)
                (Price.create price)

    // ============================================
    // 6. 注文ドメインモデル
    // ============================================

    /// 注文ID
    type OrderId = private OrderId of string

    module OrderId =
        let private pattern =
            System.Text.RegularExpressions.Regex(@"^ORD-\d{8}$")

        let create (id: string) : Validated<string, OrderId> =
            if pattern.IsMatch(id) then
                Validated.valid (OrderId id)
            else
                Validated.invalid [ sprintf "無効な注文ID形式: %s" id ]

        let value (OrderId id) = id
        let unsafe id = OrderId id

    /// 顧客ID
    type CustomerId = private CustomerId of string

    module CustomerId =
        let private pattern =
            System.Text.RegularExpressions.Regex(@"^CUST-\d{6}$")

        let create (id: string) : Validated<string, CustomerId> =
            if pattern.IsMatch(id) then
                Validated.valid (CustomerId id)
            else
                Validated.invalid [ sprintf "無効な顧客ID形式: %s" id ]

        let value (CustomerId id) = id
        let unsafe id = CustomerId id

    /// 注文アイテム
    type OrderItem =
        { ProductId: ProductId
          Quantity: Quantity
          Price: Price }

    module OrderItem =
        let create (productId: string) (quantity: int) (price: decimal) : Validated<string, OrderItem> =
            Validated.combine3
                (fun pid qty pr ->
                    { ProductId = pid
                      Quantity = qty
                      Price = pr })
                (ProductId.create productId)
                (Quantity.create quantity)
                (Price.create price)

        let total (item: OrderItem) =
            Price.value item.Price * decimal (Quantity.value item.Quantity)

    /// 注文
    type Order =
        { OrderId: OrderId
          CustomerId: CustomerId
          Items: OrderItem list
          OrderDate: System.DateTime
          Total: decimal option
          Status: Status option }

    module Order =
        let calculateTotal (order: Order) =
            order.Items |> List.sumBy OrderItem.total

    // ============================================
    // 7. 条件付きバリデーション（ADT）
    // ============================================

    /// 通知タイプ
    type NotificationType =
        | Email
        | SMS
        | Push

    /// 通知（判別共用体による条件付きバリデーション）
    type Notification =
        | EmailNotification of to': string * subject: string * body: string
        | SMSNotification of phoneNumber: string * body: string
        | PushNotification of deviceToken: string * body: string

    module Notification =
        let private emailPattern =
            System.Text.RegularExpressions.Regex(@".+@.+\..+")

        let private phonePattern =
            System.Text.RegularExpressions.Regex(@"\d{2,4}-\d{2,4}-\d{4}")

        let createEmail (to': string) (subject: string) (body: string) : Validated<string, Notification> =
            let errors =
                [ if not (emailPattern.IsMatch(to')) then
                      "無効なメールアドレス形式です"
                  if System.String.IsNullOrEmpty(subject) then
                      "件名は空にできません"
                  if System.String.IsNullOrEmpty(body) then
                      "本文は空にできません" ]

            if errors.IsEmpty then
                Validated.valid (EmailNotification(to', subject, body))
            else
                Validated.invalid errors

        let createSMS (phoneNumber: string) (body: string) : Validated<string, Notification> =
            let errors =
                [ if not (phonePattern.IsMatch(phoneNumber)) then
                      "無効な電話番号形式です"
                  if System.String.IsNullOrEmpty(body) then
                      "本文は空にできません" ]

            if errors.IsEmpty then
                Validated.valid (SMSNotification(phoneNumber, body))
            else
                Validated.invalid errors

        let createPush (deviceToken: string) (body: string) : Validated<string, Notification> =
            let errors =
                [ if System.String.IsNullOrEmpty(deviceToken) then
                      "デバイストークンは空にできません"
                  if System.String.IsNullOrEmpty(body) then
                      "本文は空にできません" ]

            if errors.IsEmpty then
                Validated.valid (PushNotification(deviceToken, body))
            else
                Validated.invalid errors

        let getBody =
            function
            | EmailNotification(_, _, body) -> body
            | SMSNotification(_, body) -> body
            | PushNotification(_, body) -> body

    // ============================================
    // 8. バリデーションユーティリティ
    // ============================================

    /// バリデーションレスポンス
    type ValidationResponse<'T> =
        { Valid: bool
          Data: 'T option
          Errors: string list }

    /// Person
    type Person =
        { Name: string
          Age: int
          Email: string option }

    /// Person のバリデーション
    let validatePerson (name: string) (age: int) (email: string option) : ValidationResponse<Person> =
        let nameV =
            if System.String.IsNullOrEmpty(name) then
                Validated.invalid [ "名前は空にできません" ]
            else
                Validated.valid name

        let ageV =
            if age < 0 then
                Validated.invalid [ "年齢は0以上である必要があります" ]
            else
                Validated.valid age

        let validated =
            Validated.combine
                (fun n a ->
                    { Name = n
                      Age = a
                      Email = email })
                nameV
                ageV

        match validated with
        | Valid p ->
            { Valid = true
              Data = Some p
              Errors = [] }
        | Invalid e ->
            { Valid = false
              Data = None
              Errors = e }

    /// 例外をスローするバリデーション
    let conformOrThrow (validated: Validated<string, 'T>) : 'T =
        match validated with
        | Valid a -> a
        | Invalid errs -> failwithf "Validation failed: %s" (System.String.Join(", ", errs))

    // ============================================
    // 9. 計算関数
    // ============================================

    /// アイテム合計を計算
    let calculateItemTotal (item: OrderItem) =
        Price.value item.Price * decimal (Quantity.value item.Quantity)

    /// 注文合計を計算
    let calculateOrderTotal (order: Order) =
        order.Items |> List.sumBy calculateItemTotal

    /// 割引を適用
    let applyDiscount (total: decimal) (discountRate: float) : Result<decimal, string> =
        if discountRate < 0.0 || discountRate > 1.0 then
            Error "割引率は0から1の間である必要があります"
        else
            Ok(total * (1m - decimal discountRate))

    /// 複数の価格を合計
    let sumPrices (prices: decimal list) : decimal = prices |> List.sum


// ============================================
// 第5章: プロパティベーステスト
// ============================================

module PropertyBasedTesting =

    // ============================================
    // 1. 文字列操作
    // ============================================

    /// 文字列を反転
    let reverseString (s: string) =
        s |> Seq.rev |> System.String.Concat

    /// 大文字に変換
    let toUpperCase (s: string) = s.ToUpperInvariant()

    /// 小文字に変換
    let toLowerCase (s: string) = s.ToLowerInvariant()

    // ============================================
    // 2. 数値操作
    // ============================================

    /// 数値リストをソート
    let sortNumbers (nums: int list) = List.sort nums

    /// 割引を計算
    let calculateDiscount (price: decimal) (rate: float) =
        if rate < 0.0 || rate > 1.0 then
            price
        else
            price * (1m - decimal rate)

    /// 絶対値
    let abs (n: int) = if n < 0 then -n else n

    // ============================================
    // 3. コレクション操作
    // ============================================

    /// フィルタ
    let filter (predicate: 'a -> bool) (list: 'a list) = List.filter predicate list

    /// マップ
    let map (f: 'a -> 'b) (list: 'a list) = List.map f list

    /// 反転
    let reverse (list: 'a list) = List.rev list

    /// 連結
    let concat (list1: 'a list) (list2: 'a list) = list1 @ list2

    /// 重複除去
    let distinct (list: 'a list) = List.distinct list

    // ============================================
    // 4. ランレングス符号化
    // ============================================

    /// ランレングス符号化
    let encode (s: string) : (char * int) list =
        if System.String.IsNullOrEmpty(s) then
            []
        else
            s
            |> Seq.fold
                (fun acc c ->
                    match acc with
                    | [] -> [ (c, 1) ]
                    | (lastChar, count) :: rest when lastChar = c -> (lastChar, count + 1) :: rest
                    | _ -> (c, 1) :: acc)
                []
            |> List.rev

    /// ランレングス復号化
    let decode (encoded: (char * int) list) : string =
        encoded
        |> List.map (fun (c, count) -> System.String(c, count))
        |> System.String.Concat

    // ============================================
    // 5. Base64 エンコード/デコード
    // ============================================

    /// Base64 エンコード
    let base64Encode (s: string) =
        s
        |> System.Text.Encoding.UTF8.GetBytes
        |> System.Convert.ToBase64String

    /// Base64 デコード
    let base64Decode (s: string) =
        s
        |> System.Convert.FromBase64String
        |> System.Text.Encoding.UTF8.GetString

    // ============================================
    // 6. モノイド
    // ============================================

    /// モノイドインターフェース
    type IMonoid<'T> =
        abstract member Empty: 'T
        abstract member Combine: 'T -> 'T -> 'T

    /// 整数加算モノイド
    let intAdditionMonoid =
        { new IMonoid<int> with
            member _.Empty = 0
            member _.Combine x y = x + y }

    /// 文字列連結モノイド
    let stringConcatMonoid =
        { new IMonoid<string> with
            member _.Empty = ""
            member _.Combine x y = x + y }

    /// リスト連結モノイド
    let listConcatMonoid<'T> () =
        { new IMonoid<'T list> with
            member _.Empty = []
            member _.Combine x y = x @ y }

    // ============================================
    // 7. ビジネスロジック
    // ============================================

    /// 会員種別
    type Membership =
        | Bronze
        | Silver
        | Gold
        | Platinum

    /// 会員割引率を取得
    let getMembershipDiscount =
        function
        | Bronze -> 0.02
        | Silver -> 0.05
        | Gold -> 0.10
        | Platinum -> 0.15

    /// 最終価格を計算
    let calculateFinalPrice (total: decimal) (membership: Membership) =
        let discount = getMembershipDiscount membership
        total * (1m - decimal discount)

    // ============================================
    // 8. バリデーション関数
    // ============================================

    /// 有効なメールかどうか
    let isValidEmail (email: string) =
        not (System.String.IsNullOrEmpty(email))
        && email.Contains("@")
        && email.Contains(".")

    /// 有効な電話番号かどうか（数字のみ、10〜15桁）
    let isValidPhoneNumber (phone: string) =
        not (System.String.IsNullOrEmpty(phone))
        && phone.Length >= 10
        && phone.Length <= 15
        && phone |> Seq.forall System.Char.IsDigit

