{-# LANGUAGE ViewPatterns
           , RecordWildCards #-}

module Hans.Device.Pcap where

import Hans.Layer.Ethernet
import Hans.Address.Mac

import Control.Monad (forever)
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

-- | Open device with pcap, will give info about the state,
-- | Unless the device is up it will throw errors later
openPcap :: String -> IO (Maybe (PcapHandle, NetDev))
openPcap s = do
       dev <- openLive s 65535 True 0
       setNonBlock dev True
       a@(NetDev{..}) <- populateDev s
       return $ case  ndMAC of
          Nothing -> Nothing
          Just m -> Just (dev, a)

pcapSend :: PcapHandle -> L.ByteString -> IO ()
pcapSend dev bd = sendPacketBS dev (L.toStrict bd)

pcapReceiveLoop :: PcapHandle -> EthernetHandle -> IO ()
pcapReceiveLoop fd eh = forever (k =<< pcapReceive fd)
  where k pkt = queueEthernet eh pkt

-- | Recieve an ethernet frame from a pcap device.
pcapReceive :: PcapHandle -> IO S.ByteString
pcapReceive fd = do
  (PktHdr{..}, packet) <- toBS =<< next fd
  if S.length packet <= 14
   then (threadDelay 10000) >> pcapReceive fd
   else return $ S.take 1514 packet
