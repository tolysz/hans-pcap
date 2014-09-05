hans-pcap
========


Network ethernet device for HaNS [hans-2.4](https://github.com/GaloisInc/HaNS), which can tap into a real ethernet interface, all using pcap library and preform raw packet reads & writes.
It is using ghc 7.8, thus the high dependencies.
This is a very naive implementation, It uses nonblocking read, but there is no way to wait for data - so we sleep.
Top run requires: root - all because we need to use PCAP

example use:

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


And we can continue using HaNS as normal.
