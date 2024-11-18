# DIY Linux Wireless Router
These configuration files describe how to configure [PC Engines](https://pcengines.ch/) APU2C4 hardware as a wireless router using linux.

Motivation
===========
**Security**

SOHO router firmware is notorious for rarely/never receiving updates. A primary goal of these consumer products is making them user friendly and as a result, a number of services are enabled by default, even if you aren't using them. Examples include things like HTTP (for the fancy GUI) and UPnP (for zeroconf network connectivity). These 2 facts alone lead to easily avoidable [breaches](https://nakedsecurity.sophos.com/2018/11/12/botnet-pwns-100000-routers-using-ancient-security-flaw/) of the device that supposedly protects your home network.

Linux distributions however, receive continuous updates and usually make these updates available within hours of them becoming available upstream.

**Knowledge**

Building your own router is a bit of a right of passage it seems for aspiring sys admins and enthusiasts alike and is a great way to get a handle on some networking basics like DHCP, DNS, firewalls, etc.

It's worth noting that there are some exellent, 3rd party open source router solutions out there. Things like OpenWrt, PFSense and others are a great compromise if you're not looking to roll your own solution, but still want to improve your security posture.

Hardware
=========
You can turn any PC with a couple of NICs into a router. Drop a Wireless card with AP support in it and you can add wireless support. The PC Engines boards, however have a number of great features for this project:
* x86 based - So you can treat it just like any other PC in your home lab. If you're running your favourite distro on a number of machines in your lab, perhaps you're caching packages to avoid downloading them from a mirror on each machine. Your APU becomes just another one of those machines, updated the same way, using the same packages.
* networking specific - It's purpose built for network plumbing and includes 3 Intel NICs and support for AES-NI which will speed up OpenVPN (and other software using AES crypto) if you're into that kind of thing.
* expandable - With 2 USB 3.0 ports you can attach an external USB drive and add some network attached storage to your local network. Also, included is are SD-card and mSATA slots for your choice of storage.
* wireless cards - These are Linux-supported and tested mini PCIe cards that will *just work* if you choose to include them in your build. The configuration described here is specifically for the Compex [WLE200NX](https://pcengines.ch/wle200nx.htm) (802.11n/2.4GHz) and [WLE900VX](https://www.pcengines.ch/wle900vx.htm) (802.11ac/5GHz) cards. ([mikrotik](https://mikrotik.com) mini PCIe cards are known to work as well.) Do yourself a favour and spend the extra money to get yourself mini PCIe cards that are known to work. No faffing around with USB wifi dongles! 

Software
========
This build sticks to a reasonably new-school set of tools:
* OS - [Archlinux](https://www.archlinux.org/), but any systemd-based distro should work. You may need to adjust paths and a few other details.
* network manager - [systemd-networkd](https://wiki.archlinux.org/index.php/Systemd-networkd), simple INI-style config files which again, should work on any systemd-based distro.
* firewall/routing - [nftables](https://wiki.nftables.org/wiki-nftables/index.php/Main_Page), supposedly the successor to iptables and definitely a much friendlier and concise configuration format
* DHCP - [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html), the go to for small networks and includes PXE & TFTP support in the event you want to add net/pxe boot to your game. Note that dnsmasq also provides a caching DNS server which is disabled in this setup.
* DNS - [unbound](https://nlnetlabs.nl/projects/unbound/about/), modern validating, recursive, caching DNS server.
* AP - [hostapd](https://w1.fi/hostapd/), the standard for Linux AP support.

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
* For the LED configuration to work you need a recent-ish (>4.16) kernel.
* No services are available on the WAN/public facing interface. Only DHCP, DNS and SSH are available on the LAN side.
* Both wireless APs and 2 of the wireless NICs are bridged and represent the local LAN. Bridge traffic is then NAT'd to provide internet access.
* The remaining wired NIC is public facing and obtains it's IP from your ISP via DHCP.
* Unbound is configured to block ad domains for the entire network. If you notice services that are no longer accessible check the list in */etc/unbound/ad_servers* and comment out the relevant domain.

References
==========
* https://wiki.archlinux.org/
* https://arstechnica.com/gadgets/2016/04/the-ars-guide-to-building-a-linux-router-from-scratch/
* https://medium.com/@renaudcerrato/how-to-build-your-own-wireless-router-from-scratch-c06fa7199d95
* https://openwrt.org/
