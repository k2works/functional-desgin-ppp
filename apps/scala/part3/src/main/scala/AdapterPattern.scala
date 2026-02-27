/**
 * 第9章: Adapter パターン
 * 
 * Adapter パターンは、既存のクラスのインターフェースを、
 * クライアントが期待する別のインターフェースに変換するパターンです。
 */
package adapterpattern

import java.time.{LocalDateTime, ZonedDateTime, ZoneId, Instant}
import java.time.format.DateTimeFormatter
import scala.util.Try

// ============================================
// 1. Switchable インターフェース (Target)
// ============================================

/** スイッチの共通インターフェース */
trait Switchable:
  def turnOn(): Switchable
  def turnOff(): Switchable
  def isOn: Boolean

// ============================================
// 2. VariableLight (Adaptee)
// ============================================

/** 可変強度ライト - 強度を0-100で設定する既存クラス */
case class VariableLight(intensity: Int = 0):
  require(intensity >= 0 && intensity <= 100, "Intensity must be 0-100")
  
  def setIntensity(value: Int): VariableLight =
    copy(intensity = math.max(0, math.min(100, value)))
  
  def brighten(amount: Int): VariableLight =
    setIntensity(intensity + amount)
  
  def dim(amount: Int): VariableLight =
    setIntensity(intensity - amount)

// ============================================
// 3. VariableLightAdapter (Adapter)
// ============================================

/** VariableLight を Switchable インターフェースに適応させるアダプター */
case class VariableLightAdapter(
  light: VariableLight,
  minIntensity: Int = 0,
  maxIntensity: Int = 100
) extends Switchable:
  
  def turnOn(): VariableLightAdapter =
    copy(light = light.setIntensity(maxIntensity))
  
  def turnOff(): VariableLightAdapter =
    copy(light = light.setIntensity(minIntensity))
  
  def isOn: Boolean = light.intensity > minIntensity
  
  /** アダプター固有：強度を取得 */
  def getIntensity: Int = light.intensity

object VariableLightAdapter:
  def apply(minIntensity: Int, maxIntensity: Int): VariableLightAdapter =
    VariableLightAdapter(VariableLight(minIntensity), minIntensity, maxIntensity)

// ============================================
// 4. データフォーマットアダプター
// ============================================

/** 旧ユーザーフォーマット */
case class OldUserFormat(
  firstName: String,
  lastName: String,
  emailAddress: String,
  phoneNumber: String
)

/** 新ユーザーフォーマット */
case class NewUserFormat(
  name: String,
  email: String,
  phone: String,
  metadata: Map[String, Any] = Map.empty
)

/** ユーザーフォーマットアダプター */
object UserFormatAdapter:
  /** 旧フォーマット → 新フォーマット */
  def adaptOldToNew(old: OldUserFormat): NewUserFormat =
    NewUserFormat(
      name = s"${old.lastName} ${old.firstName}",
      email = old.emailAddress,
      phone = old.phoneNumber,
      metadata = Map(
        "migrated" -> true,
        "originalFormat" -> "old"
      )
    )
  
  /** 新フォーマット → 旧フォーマット */
  def adaptNewToOld(newUser: NewUserFormat): OldUserFormat =
    val nameParts = newUser.name.split(" ", 2)
    val lastName = nameParts.headOption.getOrElse("")
    val firstName = if nameParts.length > 1 then nameParts(1) else ""
    OldUserFormat(
      firstName = firstName,
      lastName = lastName,
      emailAddress = newUser.email,
      phoneNumber = newUser.phone
    )

// ============================================
// 5. 外部 API レスポンスアダプター
// ============================================

/** 外部 API のレスポンス形式 */
case class ExternalApiResponse(
  data: Map[String, Any]
)

/** 内部データ形式 */
case class InternalData(
  id: String,
  name: String,
  createdAt: LocalDateTime,
  metadata: Map[String, Any] = Map.empty
)

/** API レスポンスアダプター */
object ApiResponseAdapter:
  /** 外部レスポンス → 内部形式 */
  def adaptExternalToInternal(external: ExternalApiResponse): Option[InternalData] =
    for
      dataObj <- external.data.get("data").collect { case m: Map[_, _] => m.asInstanceOf[Map[String, Any]] }
      id <- dataObj.get("identifier").collect { case s: String => s }
      attributes <- dataObj.get("attributes").collect { case m: Map[_, _] => m.asInstanceOf[Map[String, Any]] }
      name <- attributes.get("name").collect { case s: String => s }
      createdAtStr <- attributes.get("createdAt").collect { case s: String => s }
      createdAt <- Try(LocalDateTime.parse(createdAtStr, DateTimeFormatter.ISO_DATE_TIME)).toOption
    yield InternalData(
      id = id,
      name = name,
      createdAt = createdAt,
      metadata = Map(
        "source" -> "external-api",
        "originalId" -> dataObj.getOrElse("id", "")
      )
    )
  
  /** 内部形式 → 外部形式 */
  def adaptInternalToExternal(internal: InternalData): ExternalApiResponse =
    ExternalApiResponse(
      data = Map(
        "data" -> Map(
          "type" -> "resource",
          "id" -> internal.id,
          "identifier" -> internal.id,
          "attributes" -> Map(
            "name" -> internal.name,
            "createdAt" -> internal.createdAt.format(DateTimeFormatter.ISO_DATE_TIME)
          )
        )
      )
    )

// ============================================
// 6. 温度単位アダプター
// ============================================

/** 摂氏温度 */
case class Celsius(value: Double)

/** 華氏温度 */
case class Fahrenheit(value: Double)

/** ケルビン温度 */
case class Kelvin(value: Double)

/** 温度変換アダプター */
object TemperatureAdapter:
  def celsiusToFahrenheit(c: Celsius): Fahrenheit =
    Fahrenheit(c.value * 9.0 / 5.0 + 32)
  
  def fahrenheitToCelsius(f: Fahrenheit): Celsius =
    Celsius((f.value - 32) * 5.0 / 9.0)
  
  def celsiusToKelvin(c: Celsius): Kelvin =
    Kelvin(c.value + 273.15)
  
  def kelvinToCelsius(k: Kelvin): Celsius =
    Celsius(k.value - 273.15)
  
  def fahrenheitToKelvin(f: Fahrenheit): Kelvin =
    celsiusToKelvin(fahrenheitToCelsius(f))
  
  def kelvinToFahrenheit(k: Kelvin): Fahrenheit =
    celsiusToFahrenheit(kelvinToCelsius(k))

// ============================================
// 7. 日時フォーマットアダプター
// ============================================

/** 日時アダプター */
object DateTimeAdapter:
  /** Unix タイムスタンプ → LocalDateTime */
  def fromUnixTimestamp(timestamp: Long): LocalDateTime =
    LocalDateTime.ofInstant(Instant.ofEpochSecond(timestamp), ZoneId.systemDefault())
  
  /** LocalDateTime → Unix タイムスタンプ */
  def toUnixTimestamp(dateTime: LocalDateTime): Long =
    dateTime.atZone(ZoneId.systemDefault()).toEpochSecond
  
  /** ISO 8601 文字列 → LocalDateTime */
  def fromIso8601(str: String): Option[LocalDateTime] =
    Try(LocalDateTime.parse(str, DateTimeFormatter.ISO_DATE_TIME)).toOption
  
  /** LocalDateTime → ISO 8601 文字列 */
  def toIso8601(dateTime: LocalDateTime): String =
    dateTime.format(DateTimeFormatter.ISO_DATE_TIME)
  
  /** 日本語形式 → LocalDateTime */
  def fromJapanese(str: String): Option[LocalDateTime] =
    val formatter = DateTimeFormatter.ofPattern("yyyy年MM月dd日 HH時mm分ss秒")
    Try(LocalDateTime.parse(str, formatter)).toOption
  
  /** LocalDateTime → 日本語形式 */
  def toJapanese(dateTime: LocalDateTime): String =
    val formatter = DateTimeFormatter.ofPattern("yyyy年MM月dd日 HH時mm分ss秒")
    dateTime.format(formatter)

// ============================================
// 8. ファイルシステムアダプター
// ============================================

/** ローカルファイルシステム（既存インターフェース） */
trait LocalFileSystem:
  def readFile(path: String): String
  def writeFile(path: String, content: String): Unit
  def deleteFile(path: String): Unit
  def exists(path: String): Boolean

/** クラウドストレージ（異なるインターフェース） */
trait CloudStorage:
  def getObject(bucket: String, key: String): Array[Byte]
  def putObject(bucket: String, key: String, data: Array[Byte]): Unit
  def deleteObject(bucket: String, key: String): Unit
  def objectExists(bucket: String, key: String): Boolean

/** クラウドストレージをローカルファイルシステムとして使用するアダプター */
class CloudStorageAdapter(
  cloudStorage: CloudStorage,
  bucket: String
) extends LocalFileSystem:
  
  def readFile(path: String): String =
    new String(cloudStorage.getObject(bucket, path), "UTF-8")
  
  def writeFile(path: String, content: String): Unit =
    cloudStorage.putObject(bucket, path, content.getBytes("UTF-8"))
  
  def deleteFile(path: String): Unit =
    cloudStorage.deleteObject(bucket, path)
  
  def exists(path: String): Boolean =
    cloudStorage.objectExists(bucket, path)

/** シンプルなインメモリクラウドストレージ（テスト用） */
class InMemoryCloudStorage extends CloudStorage:
  private val storage = scala.collection.mutable.Map.empty[(String, String), Array[Byte]]
  
  def getObject(bucket: String, key: String): Array[Byte] =
    storage.getOrElse((bucket, key), throw new NoSuchElementException(s"$bucket/$key not found"))
  
  def putObject(bucket: String, key: String, data: Array[Byte]): Unit =
    storage((bucket, key)) = data
  
  def deleteObject(bucket: String, key: String): Unit =
    storage.remove((bucket, key))
  
  def objectExists(bucket: String, key: String): Boolean =
    storage.contains((bucket, key))

// ============================================
// 9. ロガーアダプター
// ============================================

/** 標準ロガーインターフェース */
trait StandardLogger:
  def debug(message: String): Unit
  def info(message: String): Unit
  def warn(message: String): Unit
  def error(message: String): Unit

/** レガシーロガー（異なるインターフェース） */
trait LegacyLogger:
  def log(level: Int, message: String): Unit

object LegacyLogger:
  val DEBUG = 0
  val INFO = 1
  val WARN = 2
  val ERROR = 3

/** レガシーロガーを標準ロガーとして使用するアダプター */
class LegacyLoggerAdapter(legacyLogger: LegacyLogger) extends StandardLogger:
  def debug(message: String): Unit = legacyLogger.log(LegacyLogger.DEBUG, message)
  def info(message: String): Unit = legacyLogger.log(LegacyLogger.INFO, message)
  def warn(message: String): Unit = legacyLogger.log(LegacyLogger.WARN, message)
  def error(message: String): Unit = legacyLogger.log(LegacyLogger.ERROR, message)

/** テスト用レガシーロガー */
class TestLegacyLogger extends LegacyLogger:
  val logs = scala.collection.mutable.ListBuffer.empty[(Int, String)]
  def log(level: Int, message: String): Unit = logs += ((level, message))
  def clear(): Unit = logs.clear()

// ============================================
// 10. 通貨アダプター
// ============================================

/** 通貨 */
case class Money(amount: BigDecimal, currency: String)

/** 為替レートプロバイダー */
trait ExchangeRateProvider:
  def getRate(from: String, to: String): BigDecimal

/** 固定レートプロバイダー（テスト用） */
class FixedRateProvider(rates: Map[(String, String), BigDecimal]) extends ExchangeRateProvider:
  def getRate(from: String, to: String): BigDecimal =
    if from == to then BigDecimal(1)
    else rates.getOrElse((from, to), 
      rates.get((to, from)).map(r => BigDecimal(1) / r).getOrElse(
        throw new IllegalArgumentException(s"No rate for $from -> $to")
      )
    )

/** 通貨変換アダプター */
class CurrencyAdapter(rateProvider: ExchangeRateProvider):
  def convert(money: Money, toCurrency: String): Money =
    if money.currency == toCurrency then money
    else
      val rate = rateProvider.getRate(money.currency, toCurrency)
      Money(money.amount * rate, toCurrency)

// ============================================
// 11. イテレーターアダプター
// ============================================

/** Java 風イテレーター */
trait JavaStyleIterator[A]:
  def hasNext: Boolean
  def next(): A

/** Scala 風イテレーター（Iterator）へのアダプター */
class JavaIteratorAdapter[A](javaIter: JavaStyleIterator[A]) extends Iterator[A]:
  def hasNext: Boolean = javaIter.hasNext
  def next(): A = javaIter.next()

/** テスト用 Java 風イテレーター */
class ArrayJavaIterator[A](array: Array[A]) extends JavaStyleIterator[A]:
  private var index = 0
  def hasNext: Boolean = index < array.length
  def next(): A =
    val result = array(index)
    index += 1
    result

// ============================================
// 12. 関数アダプター
// ============================================

object FunctionAdapter:
  /** (A, B) => C を A => B => C にカリー化 */
  def curry[A, B, C](f: (A, B) => C): A => B => C =
    a => b => f(a, b)
  
  /** A => B => C を (A, B) => C にアンカリー化 */
  def uncurry[A, B, C](f: A => B => C): (A, B) => C =
    (a, b) => f(a)(b)
  
  /** 引数の順序を入れ替え */
  def flip[A, B, C](f: (A, B) => C): (B, A) => C =
    (b, a) => f(a, b)
  
  /** Option を Either に変換するアダプター */
  def optionToEither[A, E](option: Option[A], error: => E): Either[E, A] =
    option.toRight(error)
  
  /** Either を Option に変換するアダプター */
  def eitherToOption[E, A](either: Either[E, A]): Option[A] =
    either.toOption
  
  /** Try を Either に変換するアダプター */
  def tryToEither[A](t: Try[A]): Either[Throwable, A] =
    t.toEither
  
  /** Scala 関数を Java 関数に変換 */
  def toJavaFunction[A, B](f: A => B): java.util.function.Function[A, B] =
    new java.util.function.Function[A, B]:
      def apply(a: A): B = f(a)
  
  /** Java 関数を Scala 関数に変換 */
  def fromJavaFunction[A, B](f: java.util.function.Function[A, B]): A => B =
    a => f.apply(a)
