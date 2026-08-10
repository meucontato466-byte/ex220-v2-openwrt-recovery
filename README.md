# Recuperação do TP-Link EX220 AX1800 V2 com OpenWrt

Registro prático e reproduzível de uma recuperação completa de um **TP-Link EX220 V2** (MediaTek MT7621) com migração para **OpenWrt 25.12.3**.

O caso começou com corrupção do firmware de fábrica (`SQUASHFS error: xz decompression failed, data probably corrupt`) e terminou com o OpenWrt instalado e validado na flash.

> [!WARNING]
> Este roteiro é para o **EX220 V2**. Não aplique imagens ou offsets de outro modelo/revisão. Antes de qualquer escrita, faça e valide um backup integral da SPI.

## Resultado validado

- Modelo: TP-Link EX220 V2
- SoC: MediaTek MT7621
- RAM: 128 MiB
- Flash: Winbond W25Q128 (16 MiB SPI)
- Console: UART TTL 3,3 V, 115200 8N1
- Sistema final: OpenWrt 25.12.3 (`ramips/mt7621`)
- Raiz após reinício: `squashfs` — confirmação de instalação permanente
- LAN, LuCI e rádios 2,4/5 GHz detectados com sucesso

## Caminho seguro, em resumo

1. Confirmar o hardware por UART e **ler a flash inteira três vezes**.
2. Comparar tamanho e SHA-256 dos três dumps; só seguir se forem idênticos.
3. Carregar o `initramfs-kernel.bin` oficial em RAM por serial, sem gravar flash.
4. Validar hashes da imagem no U-Boot e iniciar em modo temporário.
5. Confirmar LAN, LuCI e os dois rádios Wi-Fi.
6. Enviar somente a imagem `squashfs-sysupgrade.bin` pelo LuCI do modo initramfs, sem preservar configurações.
7. Confirmar, depois do reinício, que `ubus call system board` informa `rootfs_type: squashfs`.

O procedimento completo, inclusive os problemas encontrados e as correções, está em [docs/validated-runbook.md](docs/validated-runbook.md).

## Segurança e privacidade

Este repositório deliberadamente **não inclui**:

- dumps SPI, firmware de terceiros ou binários de calibração;
- senhas, tokens, MACs, PINs, números de série ou etiquetas do equipamento;
- métodos para contornar autenticação de painéis administrativos.

Mantenha o backup SPI fora de repositórios públicos. Ele contém informações exclusivas do aparelho, como calibração de rádio e identidade de rede.

## Fontes

- [OpenWrt – TP-Link EX220 V2](https://openwrt.org/toh/hwdata/tp-link/tp-link%20ex220%20v2)
- [Suporte inicial do EX220 V2 no OpenWrt](https://git.openwrt.org/openwrt/openwrt/commit/?id=dd15117dab568c7ebeaa8d3963f041bd8747e4ab)

## Licença

Documentação sob licença [MIT](LICENSE).
