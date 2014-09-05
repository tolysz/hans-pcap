{-# LANGUAGE BangPatterns #-}

module Hans.Device.Pcap where

import Hans.Layer.Ethernet
import Control.Monad (void)
import qualified Data.ByteString.Lazy     as L
import Network.Pcap

-- | Open device with pcap, will give info about the state,
--   Unless the device is up it will throw errors later
--   Be sure to use fesh mac, otherwise all might fail.
openPcap :: String -> IO PcapHandle
openPcap s = openLive s 1514 True 0

-- | send to deviece 
pcapSend :: PcapHandle -> L.ByteString -> IO ()
pcapSend dev !bd = sendPacketBS dev (L.toStrict bd)

-- | receive from it
pcapReceiveLoop fd eh = void $ loopBS fd (-1) $ \_ packet -> queueEthernet eh packet
