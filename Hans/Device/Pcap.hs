{-# LANGUAGE ViewPatterns
           , BangPatterns
           , RecordWildCards #-}

module Hans.Device.Pcap where

import Hans.Layer.Ethernet
import Hans.Address.Mac

import Control.Monad (forever, void)
import qualified Data.ByteString          as S
import qualified Data.ByteString.Internal as S
import qualified Data.ByteString.Lazy     as L
import qualified System.IO.Strict as Strict
import Data.Either
import Control.Exception
import Control.Applicative
import Control.Concurrent

import Network.Pcap

devs = "/sys/class/net"

tryRead :: String  -> IO (Maybe String)
tryRead f = either ((const Nothing) :: SomeException -> Maybe String ) Just <$> try ( head . lines <$> Strict.readFile f)

-- | Structure to keep gathered info from the filesystem
data NetDev = NetDev
  { ndName    :: String
  , ndMAC     :: Maybe Mac
  , ndState   :: Maybe String
  , ndCarrier :: Maybe String
  , ndDormant   :: Maybe String
  , ndFlags     :: Maybe String
  , ndLinks     :: [Link]
  } deriving Show

isValidND (ndMAC -> Nothing) = False
isValidND (ndState -> Just "unknown") = False
isValidND (ndCarrier -> Nothing) = False
isValidND _ = True

-- | Read info from the sys subsystem
populateDev s = do
   let b a = tryRead $ devs ++ "/" ++ s ++ "/" ++ a
   NetDev <$> pure s
          <*> ((read <$>) <$> b "address")
          <*> b "operstate"
          <*> b "carrier"
          <*> b "dormant"
          <*> b "flags"
          <*> pure []

-- | Open device with pcap, will give info about the state,
--   Unless the device is up it will throw errors later
--   Be sure to use fesh mac, otherwise all might fail.
openPcap :: String -> Maybe Mac -> IO (Maybe (PcapHandle, NetDev))
openPcap s mm = do
       dev <- openLive s 1514 True 0
--       setNonBlock dev True
       dl <- listDatalinks dev
       a@(NetDev{..}) <- populateDev s
       return $ case  (mm <|> ndMAC) of
          Nothing -> Nothing
          Just m -> Just (dev, a{ndLinks=dl, ndMAC=Just m})

-- | send to deviece 
pcapSend :: PcapHandle -> L.ByteString -> IO ()
pcapSend dev !bd = sendPacketBS dev (L.toStrict bd)

-- | receive from it
pcapReceiveLoop fd eh = void $ loopBS fd (-1) $ \_ packet -> queueEthernet eh packet
