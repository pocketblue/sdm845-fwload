# sdm845-fwload

A tool to extract firmware from a running SDM845 device.

This tool is designed to ensure that we don't need to ship firmware that is of
dubious copyright status and so that our images could work on multiple devices.

While Linux Firmware contains a lot of the equivalents to ones present on the
device, the devices we try to support require the device-class-specific
cryptographic signatures.

The downside is that now the user is responsible for updating the device, as
old firmware may contain bugs.

Currently supported devices:

* OnePlus 6
* OnePlus 6T
* Poco F1

Example configuration for OnePlus 6/6T (`/etc/sdm845-fwload.conf`):

```
SLOT_SUFFIX=_a
DEVICE_VENDOR=OnePlus
DEVICE_NAME=oneplus6
MODULES=ipa hci_uart apr wcd934x soundwire-qcom slim-qcom-ngd-ctrl snd-soc-tfa98xx q6voice
```

Inspired by: https://gitlab.postmarketos.org/postmarketOS/msm-firmware-loader

See also: https://gitlab.com/sdm845-mainline/firmware-oneplus-sdm845
