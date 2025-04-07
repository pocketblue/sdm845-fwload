#!/bin/bash

PART_MODEM=/dev/disk/by-partlabel/modem_a
PART_VENDOR=/dev/disk/by-partlabel/vendor_a
PART_BLUETOOTH=/dev/disk/by-partlabel/bluetooth_a
PART_DSP=/dev/disk/by-partlabel/dsp_a
PART_PERSIST=/dev/disk/by-partlabel/persist

ROOT=/mnt/sdm-fwload

MOUNT_ROOT=$ROOT/mounts

EXTRACT_ROOT=$ROOT/extract
LIB_FIRMWARE=$EXTRACT_ROOT/libfirmware
USR_SHARE=$EXTRACT_ROOT/usrshare

# OnePlus 6 & OnePlus 6T
FW_DIR_DEVICE=$LIB_FIRMWARE/qcom/sdm845/oneplus6
FW_DIR_DEVICE_WLAN=$LIB_FIRMWARE/qca/oneplus6
FW_DIR_OVERRIDE=$LIB_FIRMWARE/updates
FW_DIR_DSP=$USR_SHARE/qcom/sdm845/OnePlus/oneplus6

HEXAGONRPC_SDSP_DESCRIPTOR=$USR_SHARE/hexagonrpcd/hexagonrpcd-sdsp.conf

error() {
  echo "$1" > /dev/stderr
}

mount_partition() {
  PART="$1"
  
  mkdir -p "$MOUNT_ROOT/$PART"

  case "$PART" in
  modem) mount -o ro $PART_MODEM $MOUNT_ROOT/modem;;
  vendor) mount -o ro $PART_VENDOR $MOUNT_ROOT/vendor;;
  bluetooth) mount -o ro $PART_BLUETOOTH $MOUNT_ROOT/bluetooth;;
  dsp) mount -o ro $PART_DSP $MOUNT_ROOT/dsp;;
  persist) mount -o ro $PART_PERSIST $MOUNT_ROOT/persist;;
  "") mount_partition modem
      mount_partition vendor
      mount_partition bluetooth
      mount_partition dsp
      mount_partition persist
  esac
}

unmount_partition() {
  PART="$1"

  case "$PART" in
  "") unmount_partition modem
      unmount_partition vendor
      unmount_partition bluetooth
      unmount_partition dsp
      unmount_partition persist;;
  *) umount "$MOUNT_ROOT/$PART"
  esac
}

extract_file() {
  PART="$1"
  FILE="$2"
  DESTINATION="$3"
  TOLERANT="$4"
  
  # Is file already present? If yes, let's skip the logic
  if [ -r "$DESTINATION" ]; then
    return
  fi
  
  mount_partition "$PART"
  
  mkdir -p "$(dirname "$DESTINATION")"
  
  EXTNAME="${FILE##*.}"
  SOURCE="$MOUNT_ROOT/$PART/$FILE"
  MDT=0
  
  # Special case for handling MBN files. They need to be concatenated first.
  if [ "$EXTNAME" == "mbn" -a ! -f "$SOURCE" ]; then
    SOURCE="${SOURCE%.*}.mdt"
    MDT=1
  fi
  
  if ! [ -r "$SOURCE" ]; then
    unmount_partition "$PART"
    if [ "$TOLERANT" != "tolerant" ]; then
      error "* Firmware ${SOURCE} not present! Some phone functionality may be missing!"
    fi
    return
  fi
  
  if [ $MDT == 1 ]; then
    pil-squasher "$DESTINATION" "$SOURCE"
  else
    cp -a "$SOURCE" "$DESTINATION"
  fi
  
  unmount_partition "$PART"
}

extract_device_fw() {
  extract_file vendor firmware/a630_zap.mbn $FW_DIR_DEVICE/a630_zap.mbn
  extract_file modem image/cdsp.mbn $FW_DIR_DEVICE/cdsp.mbn
  extract_file modem image/modem.mbn $FW_DIR_DEVICE/modem.mbn
  extract_file modem image/slpi.mbn $FW_DIR_DEVICE/slpi.mbn
  extract_file modem image/wlanmdsp.mbn $FW_DIR_DEVICE/wlanmdsp.mbn
  extract_file modem image/adsp.mbn $FW_DIR_DEVICE/adsp.mbn
  extract_file modem image/cdspr.jsn $FW_DIR_DEVICE/cdspr.jsn
  extract_file modem image/modem_pr $FW_DIR_DEVICE/modem_pr
  extract_file modem image/slpir.jsn $FW_DIR_DEVICE/slpir.jsn
  extract_file modem image/adspr.jsn $FW_DIR_DEVICE/adspr.jsn
  extract_file vendor firmware/ipa_fws.mbn $FW_DIR_DEVICE/ipa_fws.mbn
  extract_file modem image/modemr.jsn $FW_DIR_DEVICE/modemr.jsn
  extract_file modem image/slpius.jsn $FW_DIR_DEVICE/slpius.jsn
  extract_file modem image/adspua.jsn $FW_DIR_DEVICE/adspua.jsn
  extract_file modem image/mba.mbn $FW_DIR_DEVICE/mba.mbn
  extract_file modem image/modemuw.jsn $FW_DIR_DEVICE/modemuw.jsn
  extract_file modem image/venus.mbn $FW_DIR_DEVICE/venus.mbn
  extract_file bluetooth image/crnv21.bin $FW_DIR_DEVICE_WLAN/crnv21.bin
  # /lib/firmware/updates/ath10k/WCN3990/hw1.0/board-2.bin
  # -- This file is generated from: https://github.com/jhugo/linux/tree/5.5rc2_wifi and 
  #    https://github.com/qca/qca-swiss-army-knife/blob/master/tools/scripts/ath10k/ath10k-bdencoder
  extract_file bluetooth image/crbtfw21.tlv $FW_DIR_OVERRIDE/qca/crbtfw21.tlv
  extract_file vendor etc/firmware/tfa98xx.cnt $FW_DIR_OVERRIDE/tfa98xx.cnt tolerant # OnePlus 6T only
}

extract_dsp_fw() {
  extract_file vendor etc/sensors/config $FW_DIR_DSP/sensors/config
  extract_file persist sensors/registry/registry $FW_DIR_DSP/sensors/registry
  extract_file persist sensors/sensors_list.txt $FW_DIR_DSP/sensors/sensors_list.txt
  extract_file vendor etc/sensors/sns_reg_config $FW_DIR_DSP/sensors/sns_reg.conf # Missing in old firmware
  extract_file persist sensors/registry/sns_reg_ctrl $FW_DIR_DSP/sensors/sns_reg_ctrl
  extract_file vendor etc/acdbdata $FW_DIR_DSP/acdb
  extract_file dsp adsp $FW_DIR_DSP/dsp/adsp
  extract_file dsp cdsp $FW_DIR_DSP/dsp/cdsp
  extract_file dsp sdsp $FW_DIR_DSP/dsp/sdsp
  
  mkdir -p "$(dirname "$HEXAGONRPC_SDSP_DESCRIPTOR")"
  echo "hexagonrpcd_fw_dir=\"$FW_DIR_DSP\"" > $HEXAGONRPC_SDSP_DESCRIPTOR
}

case "$1" in
extract_device_fw)
  extract_device_fw;;
extract_dsp_fw)
  extract_dsp_fw;;
mount)
  mount_partition;;
unmount)
  unmount_partition;;
*)
  echo "Usage: $0 COMMAND"
  echo ""
  echo "* extract_device_fw - extracts firmware for /lib/firmware"
  echo "* extract_dsp_fw - extracts firmware for /usr/share/qcom"
  echo ""
  echo "Developer/debugging commands:"
  echo "* mount - mounts all partitions in necessary directories"
  echo "* unmount - unmounts all partitions";;
esac
