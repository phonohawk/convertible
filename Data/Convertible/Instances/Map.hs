{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{- |
   Module     : Data.Convertible.Instances.Map
   Copyright  : Copyright (C) 2009 John Goerzen
   License    : BSD3

   Maintainer : Michael Snoyman <michael@snoyman.com>
   Stability  : provisional
   Portability: portable

Instances to convert between Map and association list.

Copyright (C) 2009 John Goerzen <jgoerzen@complete.org>

All rights reserved.

For license and copyright information, see the file LICENSE

-}

module Data.Convertible.Instances.Map()
where

import Data.Convertible.Base

import qualified Data.Map as Map

instance Ord k => ConvertSuccess [(k, a)] (Map.Map k a) where
    convertSuccess = Map.fromList
instance Ord k => ConvertAttempt [(k, a)] (Map.Map k a) where
    convertAttempt = return . convertSuccess

instance ConvertSuccess (Map.Map k a) [(k, a)] where
    convertSuccess = Map.toList
instance ConvertAttempt (Map.Map k a) [(k, a)] where
    convertAttempt = return . convertSuccess
