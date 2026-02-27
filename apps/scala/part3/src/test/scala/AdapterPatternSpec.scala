/**
 * 第9章: Adapter パターン - テストコード
 */
package adapterpattern

import org.scalatest.funsuite.AnyFunSuite
import org.scalatest.matchers.should.Matchers
import java.time.LocalDateTime

class AdapterPatternSpec extends AnyFunSuite with Matchers:

  // ============================================
  // 1. VariableLightAdapter のテスト
  // ============================================
  
  test("VariableLight: setIntensityは強度を設定する") {
    val light = VariableLight(0)
    light.setIntensity(50).intensity shouldBe 50
  }
  
  test("VariableLight: setIntensityは範囲を制限する") {
    val light = VariableLight(50)
    light.setIntensity(150).intensity shouldBe 100
    light.setIntensity(-10).intensity shouldBe 0
  }
  
  test("VariableLight: brightenは強度を増加させる") {
    val light = VariableLight(30)
    light.brighten(20).intensity shouldBe 50
  }
  
  test("VariableLight: dimは強度を減少させる") {
    val light = VariableLight(50)
    light.dim(20).intensity shouldBe 30
  }
  
  test("VariableLightAdapter: turnOnは最大強度に設定する") {
    val adapter = VariableLightAdapter(0, 100)
    val on = adapter.turnOn()
    
    on.isOn shouldBe true
    on.getIntensity shouldBe 100
  }
  
  test("VariableLightAdapter: turnOffは最小強度に設定する") {
    val adapter = VariableLightAdapter(0, 100).turnOn()
    val off = adapter.turnOff()
    
    off.isOn shouldBe false
    off.getIntensity shouldBe 0
  }
  
  test("VariableLightAdapter: カスタム範囲で動作する") {
    val adapter = VariableLightAdapter(20, 80)
    
    adapter.turnOn().getIntensity shouldBe 80
    adapter.turnOff().getIntensity shouldBe 20
  }
  
  test("VariableLightAdapter: isOnは最小強度より大きい場合にtrue") {
    val adapter = VariableLightAdapter(VariableLight(30), 20, 100)
    adapter.isOn shouldBe true
    
    val offAdapter = VariableLightAdapter(VariableLight(20), 20, 100)
    offAdapter.isOn shouldBe false
  }

  // ============================================
  // 2. UserFormatAdapter のテスト
  // ============================================
  
  test("UserFormatAdapter: 旧フォーマットを新フォーマットに変換する") {
    val old = OldUserFormat("太郎", "山田", "taro@example.com", "090-1234-5678")
    val newUser = UserFormatAdapter.adaptOldToNew(old)
    
    newUser.name shouldBe "山田 太郎"
    newUser.email shouldBe "taro@example.com"
    newUser.phone shouldBe "090-1234-5678"
    newUser.metadata("migrated") shouldBe true
    newUser.metadata("originalFormat") shouldBe "old"
  }
  
  test("UserFormatAdapter: 新フォーマットを旧フォーマットに変換する") {
    val newUser = NewUserFormat("山田 太郎", "taro@example.com", "090-1234-5678")
    val old = UserFormatAdapter.adaptNewToOld(newUser)
    
    old.firstName shouldBe "太郎"
    old.lastName shouldBe "山田"
    old.emailAddress shouldBe "taro@example.com"
    old.phoneNumber shouldBe "090-1234-5678"
  }
  
  test("UserFormatAdapter: 名前が1語の場合も処理できる") {
    val newUser = NewUserFormat("Madonna", "madonna@example.com", "000-0000-0000")
    val old = UserFormatAdapter.adaptNewToOld(newUser)
    
    old.firstName shouldBe ""
    old.lastName shouldBe "Madonna"
  }
  
  test("UserFormatAdapter: ラウンドトリップ変換が可能") {
    val original = OldUserFormat("花子", "鈴木", "hanako@example.com", "080-9876-5432")
    val converted = UserFormatAdapter.adaptNewToOld(UserFormatAdapter.adaptOldToNew(original))
    
    converted.firstName shouldBe original.firstName
    converted.lastName shouldBe original.lastName
    converted.emailAddress shouldBe original.emailAddress
    converted.phoneNumber shouldBe original.phoneNumber
  }

  // ============================================
  // 3. ApiResponseAdapter のテスト
  // ============================================
  
  test("ApiResponseAdapter: 外部レスポンスを内部形式に変換する") {
    val external = ExternalApiResponse(Map(
      "data" -> Map(
        "identifier" -> "123",
        "id" -> "ext-123",
        "attributes" -> Map(
          "name" -> "Test Resource",
          "createdAt" -> "2024-01-15T10:30:00"
        )
      )
    ))
    
    val internal = ApiResponseAdapter.adaptExternalToInternal(external)
    
    internal shouldBe defined
    internal.get.id shouldBe "123"
    internal.get.name shouldBe "Test Resource"
    internal.get.metadata("source") shouldBe "external-api"
  }
  
  test("ApiResponseAdapter: 内部形式を外部形式に変換する") {
    val internal = InternalData(
      id = "456",
      name = "Another Resource",
      createdAt = LocalDateTime.of(2024, 1, 15, 10, 30, 0)
    )
    
    val external = ApiResponseAdapter.adaptInternalToExternal(internal)
    val dataMap = external.data("data").asInstanceOf[Map[String, Any]]
    
    dataMap("id") shouldBe "456"
    dataMap("type") shouldBe "resource"
    
    val attributes = dataMap("attributes").asInstanceOf[Map[String, Any]]
    attributes("name") shouldBe "Another Resource"
  }
  
  test("ApiResponseAdapter: 不正なデータではNoneを返す") {
    val external = ExternalApiResponse(Map("invalid" -> "data"))
    ApiResponseAdapter.adaptExternalToInternal(external) shouldBe None
  }

  // ============================================
  // 4. TemperatureAdapter のテスト
  // ============================================
  
  test("TemperatureAdapter: 摂氏を華氏に変換する") {
    val celsius = Celsius(0)
    val fahrenheit = TemperatureAdapter.celsiusToFahrenheit(celsius)
    fahrenheit.value shouldBe 32.0 +- 0.01
    
    val boiling = Celsius(100)
    TemperatureAdapter.celsiusToFahrenheit(boiling).value shouldBe 212.0 +- 0.01
  }
  
  test("TemperatureAdapter: 華氏を摂氏に変換する") {
    val fahrenheit = Fahrenheit(32)
    val celsius = TemperatureAdapter.fahrenheitToCelsius(fahrenheit)
    celsius.value shouldBe 0.0 +- 0.01
  }
  
  test("TemperatureAdapter: 摂氏をケルビンに変換する") {
    val celsius = Celsius(0)
    val kelvin = TemperatureAdapter.celsiusToKelvin(celsius)
    kelvin.value shouldBe 273.15 +- 0.01
  }
  
  test("TemperatureAdapter: ケルビンを摂氏に変換する") {
    val kelvin = Kelvin(273.15)
    val celsius = TemperatureAdapter.kelvinToCelsius(kelvin)
    celsius.value shouldBe 0.0 +- 0.01
  }
  
  test("TemperatureAdapter: ラウンドトリップ変換が正確") {
    val original = Celsius(25)
    val roundtrip = TemperatureAdapter.fahrenheitToCelsius(
      TemperatureAdapter.celsiusToFahrenheit(original)
    )
    roundtrip.value shouldBe original.value +- 0.001
  }

  // ============================================
  // 5. DateTimeAdapter のテスト
  // ============================================
  
  test("DateTimeAdapter: Unixタイムスタンプから変換する") {
    val timestamp = 1705312200L // 2024-01-15T10:30:00 UTC
    val dateTime = DateTimeAdapter.fromUnixTimestamp(timestamp)
    
    dateTime.getYear shouldBe 2024
    dateTime.getMonthValue shouldBe 1
    dateTime.getDayOfMonth shouldBe 15
  }
  
  test("DateTimeAdapter: LocalDateTimeをUnixタイムスタンプに変換する") {
    val dateTime = LocalDateTime.of(2024, 1, 15, 10, 30, 0)
    val timestamp = DateTimeAdapter.toUnixTimestamp(dateTime)
    
    val roundtrip = DateTimeAdapter.fromUnixTimestamp(timestamp)
    roundtrip shouldBe dateTime
  }
  
  test("DateTimeAdapter: ISO 8601文字列から変換する") {
    val str = "2024-01-15T10:30:00"
    val dateTime = DateTimeAdapter.fromIso8601(str)
    
    dateTime shouldBe defined
    dateTime.get.getYear shouldBe 2024
    dateTime.get.getMonthValue shouldBe 1
  }
  
  test("DateTimeAdapter: LocalDateTimeをISO 8601文字列に変換する") {
    val dateTime = LocalDateTime.of(2024, 1, 15, 10, 30, 0)
    val str = DateTimeAdapter.toIso8601(dateTime)
    
    str shouldBe "2024-01-15T10:30:00"
  }
  
  test("DateTimeAdapter: 日本語形式から変換する") {
    val str = "2024年01月15日 10時30分00秒"
    val dateTime = DateTimeAdapter.fromJapanese(str)
    
    dateTime shouldBe defined
    dateTime.get.getYear shouldBe 2024
  }
  
  test("DateTimeAdapter: LocalDateTimeを日本語形式に変換する") {
    val dateTime = LocalDateTime.of(2024, 1, 15, 10, 30, 0)
    val str = DateTimeAdapter.toJapanese(dateTime)
    
    str shouldBe "2024年01月15日 10時30分00秒"
  }

  // ============================================
  // 6. CloudStorageAdapter のテスト
  // ============================================
  
  test("CloudStorageAdapter: ファイルを読み書きできる") {
    val cloudStorage = new InMemoryCloudStorage
    val adapter = new CloudStorageAdapter(cloudStorage, "test-bucket")
    
    adapter.writeFile("test.txt", "Hello, World!")
    adapter.readFile("test.txt") shouldBe "Hello, World!"
  }
  
  test("CloudStorageAdapter: ファイルの存在を確認できる") {
    val cloudStorage = new InMemoryCloudStorage
    val adapter = new CloudStorageAdapter(cloudStorage, "test-bucket")
    
    adapter.exists("test.txt") shouldBe false
    adapter.writeFile("test.txt", "content")
    adapter.exists("test.txt") shouldBe true
  }
  
  test("CloudStorageAdapter: ファイルを削除できる") {
    val cloudStorage = new InMemoryCloudStorage
    val adapter = new CloudStorageAdapter(cloudStorage, "test-bucket")
    
    adapter.writeFile("test.txt", "content")
    adapter.exists("test.txt") shouldBe true
    
    adapter.deleteFile("test.txt")
    adapter.exists("test.txt") shouldBe false
  }

  // ============================================
  // 7. LegacyLoggerAdapter のテスト
  // ============================================
  
  test("LegacyLoggerAdapter: debugをレベル0でログする") {
    val legacyLogger = new TestLegacyLogger
    val adapter = new LegacyLoggerAdapter(legacyLogger)
    
    adapter.debug("debug message")
    
    legacyLogger.logs should contain((LegacyLogger.DEBUG, "debug message"))
  }
  
  test("LegacyLoggerAdapter: infoをレベル1でログする") {
    val legacyLogger = new TestLegacyLogger
    val adapter = new LegacyLoggerAdapter(legacyLogger)
    
    adapter.info("info message")
    
    legacyLogger.logs should contain((LegacyLogger.INFO, "info message"))
  }
  
  test("LegacyLoggerAdapter: warnをレベル2でログする") {
    val legacyLogger = new TestLegacyLogger
    val adapter = new LegacyLoggerAdapter(legacyLogger)
    
    adapter.warn("warn message")
    
    legacyLogger.logs should contain((LegacyLogger.WARN, "warn message"))
  }
  
  test("LegacyLoggerAdapter: errorをレベル3でログする") {
    val legacyLogger = new TestLegacyLogger
    val adapter = new LegacyLoggerAdapter(legacyLogger)
    
    adapter.error("error message")
    
    legacyLogger.logs should contain((LegacyLogger.ERROR, "error message"))
  }

  // ============================================
  // 8. CurrencyAdapter のテスト
  // ============================================
  
  test("CurrencyAdapter: 通貨を変換する") {
    val rates = Map(
      ("USD", "JPY") -> BigDecimal(150),
      ("EUR", "JPY") -> BigDecimal(160)
    )
    val rateProvider = new FixedRateProvider(rates)
    val adapter = new CurrencyAdapter(rateProvider)
    
    val usd = Money(BigDecimal(100), "USD")
    val jpy = adapter.convert(usd, "JPY")
    
    jpy.amount shouldBe BigDecimal(15000)
    jpy.currency shouldBe "JPY"
  }
  
  test("CurrencyAdapter: 同じ通貨への変換は金額を変えない") {
    val rateProvider = new FixedRateProvider(Map.empty)
    val adapter = new CurrencyAdapter(rateProvider)
    
    val usd = Money(BigDecimal(100), "USD")
    val result = adapter.convert(usd, "USD")
    
    result.amount shouldBe BigDecimal(100)
    result.currency shouldBe "USD"
  }
  
  test("CurrencyAdapter: 逆レートを計算する") {
    val rates = Map(("USD", "JPY") -> BigDecimal(150))
    val rateProvider = new FixedRateProvider(rates)
    val adapter = new CurrencyAdapter(rateProvider)
    
    val jpy = Money(BigDecimal(15000), "JPY")
    val usd = adapter.convert(jpy, "USD")
    
    usd.amount shouldBe BigDecimal(100)
    usd.currency shouldBe "USD"
  }

  // ============================================
  // 9. JavaIteratorAdapter のテスト
  // ============================================
  
  test("JavaIteratorAdapter: Java風イテレーターをScalaイテレーターに変換する") {
    val javaIter = new ArrayJavaIterator(Array(1, 2, 3, 4, 5))
    val scalaIter = new JavaIteratorAdapter(javaIter)
    
    scalaIter.toList shouldBe List(1, 2, 3, 4, 5)
  }
  
  test("JavaIteratorAdapter: 空のイテレーターを処理できる") {
    val javaIter = new ArrayJavaIterator(Array.empty[Int])
    val scalaIter = new JavaIteratorAdapter(javaIter)
    
    scalaIter.toList shouldBe empty
  }
  
  test("JavaIteratorAdapter: Scalaの高階関数と組み合わせられる") {
    val javaIter = new ArrayJavaIterator(Array(1, 2, 3, 4, 5))
    val scalaIter = new JavaIteratorAdapter(javaIter)
    
    scalaIter.filter(_ % 2 == 0).toList shouldBe List(2, 4)
  }

  // ============================================
  // 10. FunctionAdapter のテスト
  // ============================================
  
  test("FunctionAdapter: 関数をカリー化する") {
    val add: (Int, Int) => Int = _ + _
    val curriedAdd = FunctionAdapter.curry(add)
    
    curriedAdd(1)(2) shouldBe 3
    
    val add5 = curriedAdd(5)
    add5(10) shouldBe 15
  }
  
  test("FunctionAdapter: 関数をアンカリー化する") {
    val curriedAdd: Int => Int => Int = a => b => a + b
    val uncurriedAdd = FunctionAdapter.uncurry(curriedAdd)
    
    uncurriedAdd(1, 2) shouldBe 3
  }
  
  test("FunctionAdapter: 引数の順序を入れ替える") {
    val divide: (Int, Int) => Int = _ / _
    val flippedDivide = FunctionAdapter.flip(divide)
    
    divide(10, 2) shouldBe 5
    flippedDivide(2, 10) shouldBe 5
  }
  
  test("FunctionAdapter: OptionをEitherに変換する") {
    val some = Some(42)
    val none: Option[Int] = None
    
    FunctionAdapter.optionToEither(some, "error") shouldBe Right(42)
    FunctionAdapter.optionToEither(none, "error") shouldBe Left("error")
  }
  
  test("FunctionAdapter: EitherをOptionに変換する") {
    val right: Either[String, Int] = Right(42)
    val left: Either[String, Int] = Left("error")
    
    FunctionAdapter.eitherToOption(right) shouldBe Some(42)
    FunctionAdapter.eitherToOption(left) shouldBe None
  }
  
  test("FunctionAdapter: TryをEitherに変換する") {
    import scala.util.{Try, Success, Failure}
    
    val success: Try[Int] = Success(42)
    val failure: Try[Int] = Failure(new RuntimeException("error"))
    
    FunctionAdapter.tryToEither(success) shouldBe Right(42)
    FunctionAdapter.tryToEither(failure).isLeft shouldBe true
  }
  
  test("FunctionAdapter: ScalaとJava関数を相互変換する") {
    val scalaFn: Int => Int = _ * 2
    val javaFn = FunctionAdapter.toJavaFunction(scalaFn)
    
    javaFn.apply(5) shouldBe 10
    
    val backToScala = FunctionAdapter.fromJavaFunction(javaFn)
    backToScala(5) shouldBe 10
  }
