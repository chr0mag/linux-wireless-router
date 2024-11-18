# DIY Linux Wireless Router
These configuration files describe how to configure [PC Engines](https://pcengines.ch/) APU2C4 hardware as a wireless router using Arch linux.

Usage
=====
This repo contains only the configuration files required to setup a basic wireless router. It assumes you've installed your Linux system and have SSH access. You'll probably want internet access to download and install packages although this isn't necessarily required if you're installation media contains all the required software and the configuration files from this repo.

* File paths are relative to '/'. So *etc/nftables.conf* should be copied to */etc/nftables.conf* on your target device.
* You'll need to update the *[Match]* sections for the files in *etc/systemd/network/.* to match the MAC addresses of your NICs. Additionally, you must ensure that the *wan0* interface is the one that is actually connected to your upstream service provider.
* Similarly, you'll need to set your 'wpa_passphrase=' in both hostapd*.conf files.
* The network interface names and private IP subnets (10.14.14.0/24, 10.10.10.0/24) are used in various config files so if you change them, make sure you update them everywhere.

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
* For the LED configuration to work you need a kernel >=5.1.
* No services are available on the WAN/public facing interface. DHCP, DNS, NTP and SSH are available on the wired LAN and only DHCP and DNS on the wireless LAN.
* 2 of the wired NICs are bridged (br0) and represent the local wired LAN. Bridge traffic is then NAT'd to provide internet access.
* The remaining wired NIC is public facing and obtains it's IP from your ISP via DHCP.
* Both wireless interfaces are bridged (wbr0) on a separate network and also NAT'd to provide internet access.
* Hosts on the wired network can access hosts on the wireless network but not vice versa. ie. Wireless hosts can only access the internet and cannot access hosts on the wired network.
* Unbound is configured to block ad domains for both wired and wireless networks. If you notice services that are no longer accessible check the list in */etc/unbound/ad_servers* and comment out the relevant domain.
* *hairpin* mode is enabled on the wireless bridge (wbr0) to allow wireless clients to communicate. This is how the OpenWrt folks handle this as opposed to using *hostapd*'s *ap_isolate* option.

References
==========
* https://wiki.archlinux.org/
* https://arstechnica.com/gadgets/2016/04/the-ars-guide-to-building-a-linux-router-from-scratch/
* https://medium.com/@renaudcerrato/how-to-build-your-own-wireless-router-from-scratch-c06fa7199d95
* https://openwrt.org/
