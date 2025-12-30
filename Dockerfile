ARG OPENWRT_VERSION=24.10.5

FROM ghcr.io/openwrt/rootfs:x86_64-${OPENWRT_VERSION}

# 设置时区为上海
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
# 设置语言为中文
RUN echo "export LANG=zh_CN.UTF-8" >> /etc/profile

# 更新源为aliyun的openwrt源
RUN sed -i 's_downloads.openwrt.org_mirrors.aliyun.com/openwrt_' /etc/opkg/distfeeds.conf
RUN mkdir /var/lock/
RUN opkg update 
RUN opkg list-upgradable | cut -f 1 -d ' ' | xargs -r opkg upgrade
RUN opkg remove dnsmasq 
RUN opkg install dnsmasq-full iptables-mod-tproxy iptables-mod-socket iptables-mod-iprange curl unzip ca-certificates

# 安装passwall（在构建阶段动态获取最新版本）
RUN set -e;
ARG PASSWALL_VERSION 
ARG PASSWALL_IPK_VERSION 
RUN	echo "Get the passwall latest version: ${PASSWALL_VERSION}, ${PASSWALL_IPK_VERSION}"; 
RUN curl -L -o luci-app-passwall.ipk "https://github.com/xiaorouji/openwrt-passwall/releases/download/${PASSWALL_VERSION}/luci-app-passwall-${PASSWALL_IPK_VERSION}-r1.ipk"; 
RUN curl -L -o luci-i18n-passwall-zh-cn.ipk "https://github.com/xiaorouji/openwrt-passwall/releases/download/${PASSWALL_VERSION}/luci-i18n-passwall-zh-cn-${PASSWALL_IPK_VERSION}.ipk"; 
RUN curl -L -o passwall_packages_ipk_x86_64.zip "https://github.com/xiaorouji/openwrt-passwall/releases/download/${PASSWALL_VERSION}/passwall_packages_ipk_x86_64.zip"; 
RUN ls *
RUN unzip passwall_packages_ipk_x86_64.zip -d .
RUN ls -1 *.ipk | grep -E 'tcping|geoview'
RUN ls -1 *.ipk | grep -E 'tcping|geoview' | xargs -I {} opkg install "{}" 
RUN opkg install luci-app-passwall.ipk luci-i18n-passwall-zh-cn.ipk

# 清理
RUN rm -rf /var/cache/opkg/* \
&& rm -rf /tmp/* \
&& rm -f passwall_packages_ipk_x86_64.zip \
&& rm -f luci-app-passwall.ipk \
&& rm -f luci-i18n-passwall-zh-cn.ipk

EXPOSE 53 80 443
ENTRYPOINT ["/sbin/init"]
