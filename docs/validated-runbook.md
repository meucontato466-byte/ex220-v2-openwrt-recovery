# Roteiro validado: EX220 V2 para OpenWrt

## 1. Escopo e pré-requisitos

Hardware usado:

- TP-Link EX220 V2;
- adaptador UART TTL **3,3 V** (não ligar VCC ao roteador);
- gravador SPI compatível com W25Q128, como CH341A em modo 3,3 V/25XX;
- clip SOIC-8 ou acesso equivalente à flash;
- terminal serial confiável (Tera Term 4.108 funcionou neste caso).

Configuração serial:

```text
115200 bps, 8 data bits, no parity, 1 stop bit, flow control none
```

Conexão UART: GND comum, TX do adaptador para RX da placa e RX do adaptador para TX da placa. Não conecte VCC.

## 2. Backup obrigatório da SPI

A flash tem 16 MiB. Com o roteador desligado da fonte, conecte o clip corretamente e faça três leituras independentes:

```sh
flashrom -p ch341a_spi -r ex220-read1.bin
flashrom -p ch341a_spi -r ex220-read2.bin
flashrom -p ch341a_spi -r ex220-read3.bin
sha256sum ex220-read*.bin
```

Critérios para seguir:

- cada arquivo tem exatamente `16777216` bytes;
- todos os SHA-256 são idênticos;
- o chip é detectado como Winbond W25Q128 ou equivalente de 16 MiB.

Não publique esses dumps. Além do firmware, eles podem conter MAC, calibração de RF e configurações privadas.

## 3. Mapa de partições observado

| Partição | Faixa na SPI |
| --- | --- |
| boot | `0x000000-0x02FFFF` |
| boot-env | `0x030000-0x03FFFF` |
| factory | `0x040000-0x04FFFF` |
| config / isp_config / rom_file / cloud | `0x050000-0x08FFFF` |
| radio | `0x090000-0x0AFFFF` |
| config_bak | `0x0B0000-0x0BFFFF` |
| firmware | `0x0C0000-0xFFFFFF` |

Para a migração para OpenWrt, não grave bootloader, `factory`, `radio`, `boot-env` ou outras áreas de identidade. O sysupgrade compatível cuida da área de firmware.

## 4. Imagens corretas

Baixe imagens oficiais que correspondam exatamente ao dispositivo `tplink_ex220-v2`:

```text
openwrt-25.12.3-ramips-mt7621-tplink_ex220-v2-initramfs-kernel.bin
openwrt-25.12.3-ramips-mt7621-tplink_ex220-v2-squashfs-sysupgrade.bin
```

Confirme os hashes publicados pelo OpenWrt antes da transferência.

## 5. Inicialização temporária por UART

Interrompa o autoboot e entre no console U-Boot. O TFTP não respondeu de forma confiável neste caso; a transferência **Kermit** pelo Tera Term funcionou.

Use um endereço de carga que não se sobreponha ao endereço de descompressão declarado na FIT:

```text
=> loadb 0x83000000
```

No Tera Term: `File -> Transfer -> Kermit -> Send...`, selecione apenas o arquivo `initramfs-kernel.bin`.

Após concluir, o U-Boot deve informar o tamanho total recebido. Inicie a imagem:

```text
=> bootm 0x83000000
```

### Por que não usar `0x82000000`?

A imagem FIT declara `0x82000000` como endereço de carga do kernel. Quando o arquivo foi recebido também em `0x82000000`, o U-Boot aprovou os hashes, mas falhou em `Uncompressing Kernel Image ... lzma uncompress error 1` por sobreposição de memória. Carregá-la em `0x83000000` eliminou a sobreposição e o boot foi bem-sucedido.

## 6. Validação no modo initramfs

Depois do boot, pressione Enter no console e confira:

```sh
ubus call system board
ip addr show br-lan
ubus call network.interface.lan status
```

O esperado é:

- modelo `TP-Link EX220 v2`;
- `rootfs_type: initramfs`;
- LAN em `192.168.1.1/24`;
- acesso ao LuCI em `http://192.168.1.1/`;
- dois rádios MediaTek MT7915E, 2,4 GHz e 5 GHz.

No PC, use um IPv4 estático válido da mesma rede, por exemplo `192.168.1.100/24`, sem gateway nem DNS. Atenção a erros de digitação no primeiro octeto: `196.168.x.x` não alcança `192.168.1.1`.

## 7. Instalação permanente

Somente depois de validar o modo initramfs:

1. No LuCI, abra a atualização de firmware.
2. Envie **apenas** `...squashfs-sysupgrade.bin`.
3. Não preserve configurações do initramfs.
4. Não force imagem incompatível.
5. Inicie a atualização e não interrompa energia, cabo ou serial até o reinício automático.

O log esperado inclui mensagens equivalentes a:

```text
Writing from <stdin> to firmware ...
upgrade: Upgrade completed
upgrade: Rebooting system...
```

Na primeira inicialização permanente, a preparação do overlay JFFS2 pode levar alguns minutos.

## 8. Verificação final

Após o reinício, confira:

```sh
ubus call system board
```

O sinal de sucesso é:

```json
"model": "TP-Link EX220 v2",
"rootfs_type": "squashfs"
```

Defina imediatamente uma senha para `root`:

```sh
passwd
```

Depois configure WAN, Wi-Fi, atualizações e backups pelo LuCI.

## 9. Troubleshooting aprendido no caso

| Sintoma | Causa ou correção validada |
| --- | --- |
| `flashrom` não é reconhecido no PowerShell | Usar a instalação MSYS2/MinGW e o caminho do executável, ou incluir o diretório no PATH. |
| `No EEPROM/flash device found` | Reposicionar clip, conferir alimentação e usar CH341A no modo SPI/25XX, não TTL. |
| Tera Term exibe lixo, PuTTY fica legível | Usar Tera Term 4.108; confirmar 115200 8N1 e controle de fluxo desativado. |
| TFTP só mostra `T` e expira | Confirmar porta física e firewall; neste caso, Kermit pela UART foi a alternativa confiável. |
| XMODEM/YMODEM mostram zero pacotes | Trocar para `loadb` + Kermit no Tera Term. |
| `lzma uncompress error 1` após hash válido | Recarregar a FIT em `0x83000000` e executar `bootm 0x83000000`. |
| LuCI responde localmente, mas PC não acessa | Conferir se o IPv4 do adaptador físico correto está em `192.168.1.0/24`. |

