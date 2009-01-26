{- |
   Module     : Data.Convertible.Instances.Time
   Copyright  : Copyright (C) 2009 John Goerzen
   License    : LGPL

   Maintainer : John Goerzen <jgoerzen@complete.org>
   Stability  : provisional
   Portability: portable

Instances to convert between various time structures, both old- and new-style.

At present, this module does not do full input validation.  That is, it is possible
to get an exception rather than a Left result from these functions if your input is
invalid, particularly when converting from the old-style System.Time structures.

Copyright (C) 2009 John Goerzen <jgoerzen@complete.org>

All rights reserved.

For license and copyright information, see the file COPYRIGHT

-}

module Data.Convertible.Instances.Time()
where

import Data.Convertible.Base
import Data.Convertible.Utils
import Data.Convertible.Instances.Num()
import qualified System.Time as ST
import Data.Time
import Data.Time.Clock
import Data.Time.Clock.POSIX
import Data.Time.Calendar.OrdinalDate
import Data.Typeable
import Data.Ratio

----------------------------------------------------------------------
-- Intra-System.Time stuff
----------------------------------------------------------------------

instance Convertible ST.ClockTime ST.CalendarTime where
    safeConvert = return . ST.toUTCTime

instance Convertible ST.CalendarTime ST.ClockTime where
    safeConvert = return . ST.toClockTime

instance Convertible ST.ClockTime Integer where
    safeConvert (ST.TOD x _) = return x

instance Convertible Integer ST.ClockTime where
    safeConvert x = return $ ST.TOD x 0

----------------------------------------------------------------------
-- Intra-Data.Time stuff
----------------------------------------------------------------------

------------------------------ POSIX and UTC times

instance Typeable NominalDiffTime where
    typeOf _ = mkTypeName "NominalDiffTime"

instance Typeable UTCTime where
    typeOf _ = mkTypeName "UTCTime"

{- Covered under Real a
instance Convertible Rational POSIXTime where
    safeConvert = return . fromRational
-}

instance Convertible Rational POSIXTime where
    safeConvert = return . fromRational
instance Convertible Integer POSIXTime where
    safeConvert = return . fromInteger
instance Convertible Int POSIXTime where
    safeConvert = return . fromIntegral
instance Convertible Double POSIXTime where
    safeConvert = return . fromRational . toRational

instance Convertible POSIXTime Integer where
    safeConvert = return . truncate
instance Convertible POSIXTime Rational where
    safeConvert = return . toRational
instance Convertible POSIXTime Double where
    safeConvert = return . fromRational . toRational
instance Convertible POSIXTime Int where
    safeConvert = boundedConversion (return . truncate)

instance Convertible POSIXTime UTCTime where
    safeConvert = return . posixSecondsToUTCTime
instance Convertible UTCTime POSIXTime where
    safeConvert = return . utcTimeToPOSIXSeconds

instance Convertible Rational UTCTime where
    safeConvert a = safeConvert a >>= return . posixSecondsToUTCTime
instance Convertible Integer UTCTime where
    safeConvert a = safeConvert a >>= return . posixSecondsToUTCTime
instance Convertible Int UTCTime where
    safeConvert a = safeConvert a >>= return . posixSecondsToUTCTime
instance Convertible Double UTCTime where
    safeConvert a = safeConvert a >>= return . posixSecondsToUTCTime

instance Convertible UTCTime Rational where
    safeConvert = safeConvert . utcTimeToPOSIXSeconds
instance Convertible UTCTime Integer where
    safeConvert = safeConvert . utcTimeToPOSIXSeconds
instance Convertible UTCTime Double where
    safeConvert = safeConvert . utcTimeToPOSIXSeconds
instance Convertible UTCTime Int where
    safeConvert = boundedConversion (safeConvert . utcTimeToPOSIXSeconds)

------------------------------ LocalTime stuff

instance Convertible UTCTime ZonedTime where
    safeConvert = return . utcToZonedTime utc
instance Convertible POSIXTime ZonedTime where
    safeConvert = return . utcToZonedTime utc . posixSecondsToUTCTime
instance Convertible ZonedTime UTCTime where
    safeConvert = return . zonedTimeToUTC
instance Convertible ZonedTime POSIXTime where
    safeConvert = return . utcTimeToPOSIXSeconds . zonedTimeToUTC
instance Convertible LocalTime Day where
    safeConvert = return . localDay
instance Convertible LocalTime TimeOfDay where
    safeConvert = return . localTimeOfDay

----------------------------------------------------------------------
-- Conversions between old and new time
----------------------------------------------------------------------
instance Convertible ST.CalendarTime ZonedTime where
    safeConvert ct = return $ ZonedTime {
     zonedTimeToLocalTime = LocalTime {
       localDay = fromGregorian (fromIntegral $ ST.ctYear ct) 
                  (1 + (fromEnum $ ST.ctMonth ct))
                  (ST.ctDay ct),
       localTimeOfDay = TimeOfDay {
         todHour = ST.ctHour ct,
         todMin = ST.ctMin ct,
         todSec = (fromIntegral $ ST.ctSec ct) + 
                  fromRational (ST.ctPicosec ct % 1000000000000)
                        }
                            },
     zonedTimeZone = TimeZone {
                       timeZoneMinutes = ST.ctTZ ct `div` 60,
                       timeZoneSummerOnly = ST.ctIsDST ct,
                       timeZoneName = ST.ctTZName ct}
}

instance Convertible ST.CalendarTime POSIXTime where
    safeConvert a = do r <- (safeConvert a)::ConvertResult ST.ClockTime
                       safeConvert r
instance Convertible ST.CalendarTime UTCTime where
    safeConvert a = do r <- (safeConvert a)::ConvertResult POSIXTime
                       safeConvert r

instance Convertible ST.ClockTime POSIXTime where
    safeConvert (ST.TOD x y) = return $ fromRational $ 
                                        fromInteger x + fromRational (y % 1000000000000)
instance Convertible ST.ClockTime UTCTime where
    safeConvert a = do r <- (safeConvert a)::ConvertResult POSIXTime
                       safeConvert r
instance Convertible ST.ClockTime ZonedTime where
    safeConvert a = do r <- (safeConvert a)::ConvertResult UTCTime
                       safeConvert r

instance Convertible POSIXTime ST.ClockTime where
    -- FIXME: 1-second precision via Integer
    safeConvert x = safeConvert x >>= (\z -> return $ ST.TOD z 0)
instance Convertible UTCTime ST.ClockTime where
    safeConvert = safeConvert . utcTimeToPOSIXSeconds

instance Convertible ZonedTime ST.CalendarTime where
    safeConvert zt = return $ ST.CalendarTime {
            ST.ctYear = fromIntegral year,
            ST.ctMonth = toEnum (month - 1),
            ST.ctDay = day,
            ST.ctHour = todHour ltod,
            ST.ctMin = todMin ltod,
            ST.ctSec = secs,
            ST.ctPicosec = truncate $ (((toRational (todSec ltod) - (toRational secs)) * 1000000000000)::Rational),
            ST.ctWDay = toEnum . snd . sundayStartWeek . localDay . zonedTimeToLocalTime $ zt,
            ST.ctYDay = snd . toOrdinalDate . localDay . zonedTimeToLocalTime $ zt,
            ST.ctTZName = timeZoneName . zonedTimeZone $ zt,
            ST.ctTZ = (timeZoneMinutes . zonedTimeZone $ zt) * 60,
            ST.ctIsDST = timeZoneSummerOnly . zonedTimeZone $ zt
          }
        where (year, month, day) = toGregorian . localDay . zonedTimeToLocalTime $ zt
              ltod = localTimeOfDay . zonedTimeToLocalTime $ zt
              secs = (truncate . todSec $ ltod)::Int
instance Convertible POSIXTime ST.CalendarTime where
    safeConvert pt = do r <- (safeConvert pt)::ConvertResult ZonedTime
                        safeConvert r
instance Convertible UTCTime ST.CalendarTime where
    safeConvert = safeConvert . utcTimeToPOSIXSeconds

testUTC :: UTCTime
testUTC = convert (51351::Int)
