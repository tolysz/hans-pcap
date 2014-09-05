
module Main where

import Hans.NetworkStack
import qualified Hans.Layer.Ethernet as Eth
import Hans.Device.Pcap

main :: IO ()
main = do
  ns  <- newNetworkStack
  Just (dev,nd) <- openPcap "eth0" $ Just $ Mac 1 2 3 4 5 6
  print nd
  let Just mac = (ndMAC nd)
  Eth.addEthernetDevice (nsEthernet ns) mac (pcapSend dev) (pcapReceiveLoop dev)
  Eth.startEthernetDevice (nsEthernet ns) mac
  -- and we can do whatever we could earlier