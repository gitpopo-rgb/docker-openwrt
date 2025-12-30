ARG OPENWRT_VERSION=24.10.5

FROM ghcr.io/openwrt/rootfs:x86_64-${OPENWRT_VERSION}
ARG PASSWALL_VERSION 
ARG PASSWALL_IPK_VERSION 

# 系统配置：时区、语言、源
RUN set -e && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "export LANG=zh_CN.UTF-8" >> /etc/profile && \
    sed -i 's_downloads.openwrt.org_mirrors.aliyun.com/openwrt_' /etc/opkg/distfeeds.conf && \
    mkdir -p /var/lock

# 系统软件包更新和安装
RUN set -e && \
    opkg update && \
    opkg list-upgradable | cut -f 1 -d ' ' | xargs -r opkg upgrade && \
    opkg remove dnsmasq && \
    opkg install dnsmasq-full kmod-nft-socket kmod-nft-tproxy iptables-mod-tproxy iptables-mod-socket iptables-mod-iprange curl unzip ca-certificates

# 安装 Passwall（下载、安装、清理一次完成）
RUN set -e && \
    echo "Get the passwall latest version: ${PASSWALL_VERSION}, ${PASSWALL_IPK_VERSION}" && \
    curl -L -o luci-app-passwall.ipk "https://github.com/xiaorouji/openwrt-passwall/releases/download/${PASSWALL_VERSION}/luci-app-passwall_${PASSWALL_IPK_VERSION}-r1_all.ipk" && \
    curl -L -o luci-i18n-passwall-zh-cn.ipk "https://github.com/xiaorouji/openwrt-passwall/releases/download/${PASSWALL_VERSION}/luci-i18n-passwall-zh-cn_${PASSWALL_IPK_VERSION}_all.ipk" && \
    curl -L -o passwall_packages_ipk_x86_64.zip "https://github.com/xiaorouji/openwrt-passwall/releases/download/${PASSWALL_VERSION}/passwall_packages_ipk_x86_64.zip" && \
    unzip passwall_packages_ipk_x86_64.zip -d . && \
    ls -1 *.ipk | grep -E 'tcping|geoview|chinadns-ng|dns2socks' | xargs -r opkg install && \
    opkg install luci-app-passwall.ipk luci-i18n-passwall-zh-cn.ipk && \
    rm -f passwall_packages_ipk_x86_64.zip *.ipk

EXPOSE 53 80 443
ENTRYPOINT ["/sbin/init"]
