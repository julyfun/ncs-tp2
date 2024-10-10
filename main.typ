#set page(paper: "us-letter")
#set heading(numbering: "1.1.")
#set figure(numbering: "1")

#import "@preview/codelst:2.0.0": sourcecode
#show raw.where(block: true): it => {
  set text(size: 10pt)
  sourcecode(it)
}

// 这是注释
#figure(image("sjtu.png", width: 50%), numbering: none) \ \ \

#align(center, text(17pt)[
  NCS TP2 \ \
  #table(
      columns: 2,
      stroke: none,
      rows: (2.5em),
      // align: (x, y) =>
      //   if x == 0 { right } else { left },
      align: (right, left),
      [Name:], [Junjie Fang (Florian)],
      [Student ID:], [521260910018],
      [Date:], [#datetime.today().display()],
    )
])

#pagebreak()

#set page(header: align(right)[
  DB Lab1 Report - Junjie FANG
], numbering: "1")

#show outline.entry.where(
  level: 1
): it => {
  v(12pt, weak: true)
  strong(it)
}

#outline(indent: 1.5em)

#set text(12pt)
#show heading.where(level: 1): it => {
  it.body
}

= Q1

We consider the router as a "machine" in the network, so in subnet A, there is 7 devices, each of which needs an IP address. We need 2 additional addresses for the broadcast address and the reserved address. So 9 addresses are needed in total. The smallest subnet that can provide 9 addresses is a /28 subnet, which has 16 addresses in total.

Likewise, in subnet B, we need $3 + 2 = 5$ addresses and the smallest subnet that can provide 5 addresses is a /29 subnet, which has 8 addresses in total. In subnet C, we need $6 + 2 = 8$ addresses and the smallest subnet that can provide 8 addresses is a /29 subnet.

Therefore, the minimum size of the global address range should contain at least $16 + 8 + 8 = 32$ addresses, and the smallest subnet that can provide 32 addresses is a /27 subnet.

= Q2

Let's address 10.0.0.0/28 (from 10.0.0.0 to 10.0.0.15) to subnet A, 10.0.0.16/28 (from 10.0.0.16 to 10.0.0.31) to subnet B and 10.0.0.32/28 (from 10.0.0.32 to 10.0.0.47) to subnet C. The IP address assignment is shown in @t1. Command lines for these configurations are shown in @cli1.

#import "@preview/tablem:0.1.0": tablem

#let three-line-table = tablem.with(
  render: (columns: auto, ..args) => {
    table(
      columns: columns,
      stroke: none,
      align: center + horizon,
      table.hline(y: 0),
      table.hline(y: 1, stroke: .5pt),
      table.hline(y: 4, stroke: .5pt),
      table.hline(y: 7, stroke: .5pt),
      ..args,
      table.hline(),
    )
  }
)


#figure(
three-line-table[
| *Machine*   | *Interface*  | *IP/mask* |
| ---- | ---- | ---- |
|  A1    | eth0     | 10.0.0.1/28     |
|  A2    | eth0     | 10.0.0.2/28     |
|  R1    | eth0     | 10.0.0.14/28     |
|  C1    | eth0     | 10.0.0.17/28    |
|  R1    | eth1     | 10.0.0.30/28     |
|  R2    | eth0     | 10.0.0.29/28     |
|  B1    | eth0     | 10.0.0.33/28     |
|  R2    | eth1     | 10.0.0.46/28     |
|  R3    | eth0     | 10.0.0.45/28     |
], caption: "IP Address Assignment"
) <t1>

The ping results from A1 to A2 and B2 are shown in @ping1. We can see from the results that A1 and A2 can communicate with each other through `ping` but A1 cannot communicate with B1.

= Q3

Let's add R1's `eth0` address for A1 and A2 as their default gateways, and add R2's `eth0` address for C1 as its default gateway. The command lines for these configurations are shown in @cli2.

`ping` from A1 to C1 failed, as shown in @ping2.

*We can observe* from the `tcpdump` results that in each attempt, there is one request packet forwarded to R1 and C1, and one reply packet from C1. 

*Interpretation*:
- A1 trys to reach C1 which is not in the same subnet and not in the routing table, it forwards the packet to its default gateway R1.
- R1 forwards the packet to C1 through its `eth0` interface as C1 and R1 are in the same subnet.
- C1 forwards its reply packet to its default gateway R2. 
- R2 has no idea where to forward the packet, it has no default gateway, so the communication failed. 

= Q4

Like in @c4, let's add R1's default gateway to R2 and update the routing table of R2 to subnet A with gateway R1 using device `eth0`.

`ping` from A1 to C1 succeeds. Using `tcpdump` and `traceroute`, we can observe the path is: 

$
"A1" -->^("request") "R1" -->^"request" "C1" -->^"reply" "R2" -->^"reply" "R1" -->^"reply" "A"
$

The paths of requests and replies are not the same.

= Q5

Finally we need to add R2 and B1's default gateways to R3, and update the routing table of R3 to subnet A and B with gateway R2 using device `eth1`.

With configurations in @c5, `ping` from A1 to B1 succeeds. The path is:

```
root@a1:/# traceroute 10.0.0.33
traceroute to 10.0.0.33 (10.0.0.33), 30 hops max, 60 byte packets
 1  10.0.0.14 (10.0.0.14)  0.727 ms  0.899 ms  1.200 ms
 2  10.0.0.29 (10.0.0.29)  1.874 ms  2.194 ms  2.524 ms
 3  10.0.0.33 (10.0.0.33)  6.272 ms  6.716 ms  7.071 ms
```

= Appendix

== Configurations for Q2 <cli1>


```
# a1
ifconfig eth0 10.0.0.1/28
# a2
ifconfig eth0 10.0.0.2/28
# r1
ifconfig eth0 10.0.0.14/28
ifconfig eth1 10.0.0.30/28
# c1
ifconfig eth0 10.0.0.17/28
# r2
ifconfig eth0 10.0.0.29/28
ifconfig eth1 10.0.0.46/28
# b1
ifconfig eth0 10.0.0.33/28
# r3
ifconfig eth0 10.0.0.45/28
```

== Ping results in Q2 <ping1>

```
# a1 try to ping a2
root@a1:/# ping -c 5 10.0.0.2
PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=0.342 ms
64 bytes from 10.0.0.2: icmp_seq=2 ttl=64 time=0.500 ms
64 bytes from 10.0.0.2: icmp_seq=3 ttl=64 time=0.313 ms
64 bytes from 10.0.0.2: icmp_seq=4 ttl=64 time=0.466 ms
64 bytes from 10.0.0.2: icmp_seq=5 ttl=64 time=0.375 ms

--- 10.0.0.2 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4084ms
rtt min/avg/max/mdev = 0.313/0.399/0.500/0.071 ms

# a1 try to ping b1
root@a1:/# ping -c 5 10.0.0.33
ping: connect: Network is unreachable
```

== Configurations for Q3 <cli2>

```
# a1
route add default gw 10.0.0.14
# a2
route add default gw 10.0.0.14
# c1
route add default gw 10.0.0.29
```

== Ping and tcpdump results in Q3 <ping2>

```
# a1
root@a1:/# ping 10.0.0.17 -c 4
PING 10.0.0.17 (10.0.0.17) 56(84) bytes of data.

--- 10.0.0.17 ping statistics ---
4 packets transmitted, 0 received, 100% packet loss, time 3055ms

# r1 tcpdump
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
07:06:31.483814 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 26, seq 1, length 64
07:06:32.486765 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 26, seq 2, length 64
07:06:33.510743 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 26, seq 3, length 64
07:06:34.538570 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 26, seq 4, length 64

# c1 tcpdump
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
07:06:31.483949 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 26, seq 1, length 64
07:06:31.483973 IP 10.0.0.17 > 10.0.0.1: ICMP echo reply, id 26, seq 1, length 64
07:06:31.484241 IP 10.0.0.29 > 10.0.0.17: ICMP net 10.0.0.1 unreachable, length 92
07:06:32.487085 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 26, seq 2, length 64
07:06:32.487116 IP 10.0.0.17 > 10.0.0.1: ICMP echo reply, id 26, seq 2, length 64
07:06:32.487520 IP 10.0.0.29 > 10.0.0.17: ICMP net 10.0.0.1 unreachable, length 92
07:06:33.511041 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 26, seq 3, length 64
07:06:33.511070 IP 10.0.0.17 > 10.0.0.1: ICMP echo reply, id 26, seq 3, length 64
07:06:33.511396 IP 10.0.0.29 > 10.0.0.17: ICMP net 10.0.0.1 unreachable, length 92
```

== Configurations for Q4 <c4>

```
# r1
route add default gw 10.0.0.29

# r2
route add -net 10.0.0.0/28 gw 10.0.0.30 dev eth0
```

== Ping and tcpdump and traceroute results in Q4

```
# a1
root@a1:/# ping 10.0.0.17 -c 4
PING 10.0.0.17 (10.0.0.17) 56(84) bytes of data.
64 bytes from 10.0.0.17: icmp_seq=1 ttl=62 time=1.79 ms
64 bytes from 10.0.0.17: icmp_seq=2 ttl=62 time=1.22 ms
64 bytes from 10.0.0.17: icmp_seq=3 ttl=62 time=0.884 ms
64 bytes from 10.0.0.17: icmp_seq=4 ttl=62 time=1.03 ms

--- 10.0.0.17 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3011ms
rtt min/avg/max/mdev = 0.884/1.229/1.786/0.342 ms

# r1
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
07:25:22.691142 ARP, Request who-has 10.0.0.14 tell 10.0.0.1, length 46
07:25:22.691166 ARP, Reply 10.0.0.14 is-at 3e:99:66:06:4f:34 (oui Unknown), length 28
07:25:22.691466 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 29, seq 1, length 64
07:25:22.692660 IP 10.0.0.17 > 10.0.0.1: ICMP echo reply, id 29, seq 1, length 64
07:25:23.693239 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 29, seq 2, length 64
07:25:23.693877 IP 10.0.0.17 > 10.0.0.1: ICMP echo reply, id 29, seq 2, length 64
07:25:24.694492 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 29, seq 3, length 64
07:25:24.695022 IP 10.0.0.17 > 10.0.0.1: ICMP echo reply, id 29, seq 3, length 64
07:25:25.702752 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 29, seq 4, length 64
07:25:25.703242 IP 10.0.0.17 > 10.0.0.1: ICMP echo reply, id 29, seq 4, length 64

# c1
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
07:25:22.691142 ARP, Request who-has 10.0.0.14 tell 10.0.0.1, length 46
07:25:22.691166 ARP, Reply 10.0.0.14 is-at 3e:99:66:06:4f:34 (oui Unknown), length 28
07:25:22.691466 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 29, seq 1, length 64
07:25:22.692660 IP 10.0.0.17 > 10.0.0.1: ICMP echo reply, id 29, seq 1, length 64
07:25:23.693239 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 29, seq 2, length 64
07:25:23.693877 IP 10.0.0.17 > 10.0.0.1: ICMP echo reply, id 29, seq 2, length 64
07:25:24.694492 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 29, seq 3, length 64
07:25:24.695022 IP 10.0.0.17 > 10.0.0.1: ICMP echo reply, id 29, seq 3, length 64
07:25:25.702752 IP 10.0.0.1 > 10.0.0.17: ICMP echo request, id 29, seq 4, length 64
07:25:25.703242 IP 10.0.0.17 > 10.0.0.1: ICMP echo reply, id 29, seq 4, length 64

# a1
root@a1:/# traceroute 10.0.0.17
traceroute to 10.0.0.17 (10.0.0.17), 30 hops max, 60 byte packets
 1  10.0.0.14 (10.0.0.14)  0.436 ms  0.659 ms  0.910 ms
 2  10.0.0.17 (10.0.0.17)  1.477 ms  2.155 ms  2.532 ms

# c1
root@c1:/# traceroute 10.0.0.1
traceroute to 10.0.0.1 (10.0.0.1), 30 hops max, 60 byte packets
 1  10.0.0.29 (10.0.0.29)  0.607 ms  0.815 ms  1.311 ms
 2  10.0.0.30 (10.0.0.30)  5.104 ms  5.234 ms  5.741 ms
 3  10.0.0.1 (10.0.0.1)  5.873 ms  5.943 ms  6.003 ms
```

== Configurations for Q5 <c5>

```
# r2
route add default gw 10.0.0.45

# b1
route add default gw 10.0.0.45

# r3
route add -net 10.0.0.16/28 gw 10.0.0.46 eth0
route add -net 10.0.0.0/28 gw 10.0.0.46 eth0
```
