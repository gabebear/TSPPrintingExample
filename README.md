TSPPrintingExample
==================

This is a modern driver for the TSP100 and TSP650 receipt printers for iOS written using CocoaAsyncSocket. The one supplied by StarMicronics had a number of issues.
 - This driver doesn't lock the main thread while interacting with printer. (Unlike StarMicronic's driver)
 - This driver uses blocks for callbacks. (Unlike StarMicronic's driver)
 - This driver is a couple hundred lines of code:
    - it doesn't bloat your app. (Unlike StarMicronic's driver)
    - no static binary blobs to worry about when ARM64v2 comes out. (Unlike StarMicronic's driver)
 - This driver works when your network blocks ICMP/pings. (Unlike StarMicronic's driver)

I've tried it with the TSP650II/TSP654II and the TSP100LAN/TSP143LAN printers.

This is released under the Creative Commons Attribution-ShareAlike 4.0 International License.
