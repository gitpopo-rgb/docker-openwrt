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
RUN opkg install dnsmasq-full iptables-mod-tproxy iptables-mod-socket iptables-mod-iprange

# 安装passwall（在构建阶段动态获取最新版本）
RUN set -e; \
	PASSWALL_VERSION=$(curl -s https://api.github.com/repos/xiaorouji/openwrt-passwall/releases/latest | grep '"tag_name":' | cut -d '"' -f4); \
	PASSWALL_IPK_VERSION=${PASSWALL_VERSION%%-*}; \
	echo "Get the passwall latest version: ${PASSWALL_VERSION}, ${PASSWALL_IPK_VERSION}"; \
	curl -L -o luci-app-passwall.ipk "https://github.com/xiaorouji/openwrt-passwall/releases/download/${PASSWALL_VERSION}/luci-app-passwall-${PASSWALL_IPK_VERSION}-r1.ipk"; \
	curl -L -o luci-i18n-passwall-zh-cn.ipk "https://github.com/xiaorouji/openwrt-passwall/releases/download/${PASSWALL_VERSION}/luci-i18n-passwall-zh-cn-${PASSWALL_IPK_VERSION}.ipk"; \
	curl -L -o passwall_packages_ipk_x86_64.zip "https://github.com/xiaorouji/openwrt-passwall/releases/download/${PASSWALL_VERSION}/passwall_packages_ipk_x86_64.zip"; \
	unzip passwall_packages_ipk_x86_64.zip .; \
	opkg install tcping_*\-r1_x86_64.ipk geoview_*\-r1_x86_64.ipk sing-box_*\-r1_x86_64.ipk luci-app-passwall.ipk luci-i18n-passwall-zh-cn.ipk

# 清理
RUN rm -rf /var/cache/opkg/* \
&& rm -rf /tmp/* \
&& rm -f passwall_packages_ipk_x86_64.zip \
&& rm -f luci-app-passwall.ipk \
&& rm -f luci-i18n-passwall-zh-cn.ipk

EXPOSE 53 80 443
ENTRYPOINT ["/sbin/init"]
