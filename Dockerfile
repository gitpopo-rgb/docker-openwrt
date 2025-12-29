ARG OPENWRT_VERSION=24.10.5

FROM scratch
ADD https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/x86/64/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-rootfs.img.gz /


# 更新源为aliyun的openwrt源
RUN sed -i 's_downloads.openwrt.org_mirrors.aliyun.com/openwrt_' /etc/opkg/distfeeds.conf \
&& opkg update \
&& opkg upgrade \
&& opkg remove dnsmasq \
&& opkg install dnsmasq-full iptables-mod-tproxy iptables-mod-socket iptables-mod-iprange

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