
module Hans.Device.Pcap (pcapOpen, pcapSend, pcapReceiveLoop) where

import Prelude              (String, IO, Bool(..), const, (.))
import Hans.Layer.Ethernet  (EthernetHandle, queueEthernet)
import Control.Monad        (void)
import Data.ByteString.Lazy (ByteString, toStrict)
import Network.Pcap         (PcapHandle, openLive, loopBS, sendPacketBS)

-- | Open device with pcap, will give info about the state,
--   Unless the device is up it will throw errors later
--   Be sure to use fesh mac, otherwise all might fail.
pcapOpen :: String -> IO PcapHandle
pcapOpen s = openLive s 1514 True 0

-- | send to deviece 
pcapSend :: PcapHandle -> ByteString -> IO ()
pcapSend dev = sendPacketBS dev . toStrict

-- | receive from it
pcapReceiveLoop :: PcapHandle -> EthernetHandle -> IO ()
pcapReceiveLoop dev = void . loopBS dev (-1) . const . queueEthernet
