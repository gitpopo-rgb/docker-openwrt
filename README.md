# docker-openwrt
Build a openwrt docker image, add some custom packages.

## Steps
1. 指定openwrt版本号ARG变量`OPENWRT_VERSION`
2. 指定基础镜像
```Dockfile
FROM scratch
ADD https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/x86/64/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-rootfs.img.gz /

EXPOSE 80
```
3. 修改源为aliyun的openwrt源，并更新以及升级
```
# 更新源为aliyun的openwrt源
RUN sed -i 's_downloads.openwrt.org_mirrors.aliyun.com/openwrt_' /etc/opkg/distfeeds.conf \
&& opkg update \
&& opkg upgrade \
&& opkg remove dnsmasq \
&& opkg install dnsmasq-full iptables-mod-tproxy iptables-mod-socket iptables-mod-iprange
```
4. 获取passwall最新版本，并安装
```bash
PASSWALL_VERSION=${curl -s https://api.github.com/repos/xiaorouji/openwrt-passwall/releases/latest | grep '"tag_name":' | cut -d'"' -f4}
PASSWALL_IPK_VERSION=${PASSWALL_VERSION%%-*}
echo Get the passwall latest version: ${PASSWALL_VERSION}, ${PASSWALL_IPK_VERSION}
curl -L -o luci-app-passwall.ipk https://github.com/xiaorouji/openwrt-passwall/releases/download/${PASSWALL_VERSION}/luci-app-passwall-${PASSWALL_IPK_VERSION}-r1.ipk \
&& curl -L -o luci-i18n-passwall-zh-cn.ipk https://github.com/xiaorouji/openwrt-passwall/releases/download/${PASSWALL_VERSION}/luci-i18n-passwall-zh-cn-${PASSWALL_IPK_VERSION}.ipk \
&& curl -L -o passwall_packages_ipk_x86_64.zip https://github.com/xiaorouji/openwrt-passwall/releases/download/${PASSWALL_VERSION}/passwall_packages_ipk_x86_64.zip \
&& unzip passwall_packages_ipk_x86_64.zip . \
&& opkg install tcping_*-r1_x86_64.ipk geoview_*-r1_x86_64.ipk sing-box_*-r1_x86_64.ipk luci-app-passwall.ipk luci-i18n-passwall-zh-cn.ipk
```

## Github Action
写一个Github Action，基于项目中的Dockerfile构建镜像。遵循以下步骤：
1. 获取当前的分支号或者版本号，作为镜像的构建参数OPENWRT_VERSION的值传入，如果获取失败则不传。
2. 以步骤一中获取的分支号或者版本号作为该镜像的tag版本号，如果没有则使用默认值***24.10.5***
3. 上传镜像到ghcr.io