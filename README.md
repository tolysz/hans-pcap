hans-pcap
========


Network ethernet device for HaNS [hans-2.4](https://github.com/GaloisInc/HaNS), which can tap into a real ethernet interface, all using pcap library and preform raw packet reads & writes.
This is a very naive implementation, however not much more can be squeezed from PCAP.
Top run requires: root - all because we need to use PCAP

example use:

    import Hans.NetworkStack
    import Hans.Device.Pcap

    main :: IO ()
    main = do
      ns  <- newNetworkStack
      -- MAC we want to have; make it unique
      let mac = Mac 1 2 3 4 5 6

      -- device we attach to
      dev <- pcapOpen "eth0" 
      addDevice ns mac (pcapSend dev) (pcapReceiveLoop dev)
      deviceUp ns mac


And we can continue using HaNS as normal.
See example/gal.hs for a working example.
