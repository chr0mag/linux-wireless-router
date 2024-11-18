# DIY Linux Wireless Router
These configuration files describe how to configure [PC Engines](https://pcengines.ch/) APU2C4 hardware as a wireless router using Arch linux.

Usage
=====
This repo contains only the configuration files required to setup a basic wireless router. It assumes you've installed your Linux system and have SSH access. You'll probably want internet access to download and install packages although this isn't necessarily required if you're installation media contains all the required software and the configuration files from this repo.

* File paths are relative to '/'. So *etc/nftables.conf* should be copied to */etc/nftables.conf* on your target device.
* You'll need to update the *[Match]* sections for the files in *etc/systemd/network/.* to match the MAC addresses of your NICs. Additionally, you must ensure that the *wan0* interface is the one that is actually plugged in to your upstream modem.
* Similarly, you'll need to set the SSID name and passphrase in the 2 *hostapd* configuration files. (I use the same SSID/passphrase for both bands so clients can move between the 2 depending on signal strength.)
* The network interface names and private IP subnet (10.14.14.0/24) are used in various config files so if you change them, make sure you update them everywhere.

The following systemd units should be enabled:
* systemd-networkd.service
* systemd-networkd-wait-online.service (should get pulled in when you enable systemd-networkd, but just in case)
* nftables.service
* dnsmasq.service
* unbound.service
* roothints.timer
* adservers.timer
* hostapd@wifi0.service
* hostapd@wifi1.service


Notes
=====
* This configuration assumes IPv6 is disabled. You can do this using kernel parameter *ipv6.disable=1*.
* For the LED configuration to work you need a recent (>=5.1) kernel.
* No services are available on the WAN/public facing interface. Only DHCP, DNS and SSH are available on the LAN side.
* Both wireless APs and 2 of the wired NICs are bridged and represent the local LAN. Bridge traffic is then NAT'd to provide internet access.
* The remaining wired NIC is public facing and obtains it's IP from your ISP via DHCP.
* Unbound is configured to block ad domains for the entire network. If you notice services that are no longer accessible check the list in */etc/unbound/ad_servers* and comment out the relevant domain.

References
==========
* https://wiki.archlinux.org/
* https://arstechnica.com/gadgets/2016/04/the-ars-guide-to-building-a-linux-router-from-scratch/
* https://medium.com/@renaudcerrato/how-to-build-your-own-wireless-router-from-scratch-c06fa7199d95
* https://openwrt.org/
