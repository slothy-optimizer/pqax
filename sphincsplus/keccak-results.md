| Approach |   |   |Cortex-X1 | Cortex-A78 | Cortex-A55 |
| -------- | - | - |--------- | ---------- | -----------|
| Reference C | [C][C] | 1x | 811 (811) | 819 (819) | 1935 (1935)
| Scalar | Ours | 1x | 690 (690) | 709 (709) | 1418 (1418)
| Neon | [Ngu][Ngu] | 2x | 1370 (685) | 2409 (1204) | 5222 (2611)
| Neon | Ours | 2x | 1317 (658) | 2197 (1098) | 4560 (2280)
| Scalar/Neon | Ours | 4x | 1524 (381) | 2201 (550) | 7288 (1822)
| Scalar/Neon | Ours | 5x | 2161 (432) | 2191 (438) | 8960 (1792)


| Approach |   |   | Cortex-X2 | Cortex-A710 | Cortex-A510 |
| -------- | - | - | --------- | ----------- | ------------|
| Reference C | [C][C] | 1x | 817 (817) | 820 (820) | 1375 (1375)
| Scalar | Ours | 1x | 687 (687) | 701 (701) | 968 (968)
| Neon | [Ngu][Ngu] | 2x | 1325 (662) | 2391 (1195) | 3397 (1698)
| Neon | Ours | 2x | 1274 (637) | 2044 (1022) | 6970 (3485)
| Neon+SHA-3 | [Wes][Wes] | 2x | 1547 (773) | 1550 (775) | 2268 (1134)
| Neon+SHA-3 | Ours | 2x | 1547 (773) | 1549 (774) | 1144 (572)
| Neon/Neon+SHA-3 | Ours | 2x | 944 (472) | 1502 (751) | 4449 (2224)
| Scalar/Neon/Neon+SHA-3 | Ours | 3x | 985 (328) | 1532 (510) | 4534 (1511)
| Scalar/Neon | Ours | 4x | 1469 (367) | 2229 (557) | 7384 (1846)
| Scalar/Neon+SHA-3 | Ours | 4x | 1551 (387) | 1608 (402) | 3545 (886)
| Scalar/Neon | Ours | 5x | 2152 (430) | 2535 (507) | 7169 (1433)
| Scalar/Neon/Neon+SHA-3 | Ours | 4x | 1439 (359) | 1755 (438) | 4487 (1121)


[C]: https://github.com/XKCP/XKCP
[Ngu]: https://github.com/cothan/NEON-SHA3_2x
[Wes]: https://github.com/bwesterb/armed-keccak
