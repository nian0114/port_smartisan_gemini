DEVICE=gemini;

CPU=arm64;
FSTABLE=3221225472;

USER=`whoami`

echo "Start to Build Smartisan ($DEVICE)"

if [ -d "workspace" ]; then
	echo "Cleaning Up..."
	sudo umount /dev/loop0
	rm -rf workspace $DEVICE-h2os-6.0.zip final/*
else
	rm -rf $DEVICE-h2os-6.0.zip final/*
fi

mkdir -p workspace/output workspace/app

if [ ! -f "stockrom/system.new.dat" ]; then

  if [ ! -f "stockrom/boot.img" ];then
    exit
  else
    cp -rf stockrom/system workspace/
    cp -f stockrom/boot.img workspace/
    export IMG=0
  fi

else

  if [ ! -f "stockrom/boot.img" ];then
    exit
  else
    cp -f stockrom/system.transfer.list workspace/
    cp -f stockrom/system.new.dat workspace/
    cp -f stockrom/boot.img workspace/
    export IMG=1
  fi

fi

cd workspace

if [ ${IMG} = 1 ]; then
  echo "Extract System.img ..."
  ./../tools/sdat2img.py system.transfer.list system.new.dat system.img &> /dev/null
  sudo mount -t ext4 -o loop system.img output/
  sudo chown -R $USER:$USER output
else
  echo "Copy System to Output ..."
  cp -rf ../stockrom/system/* output/
fi

VERSION=`grep "ro.smartisan.version=" output/build.prop | cut -d '=' -f2`

echo "Disable Recovery Auto Install ..."
rm -rf output/recovery-from-boot.p
rm -rf output/bin/install-recovery.sh

echo "Start Xiaomi Port"
rm -rf output/app/LatinIME  output/app/OtaUpdaterInfo output/app/Nfc*  output/app/LiveWallpapers  output/app/NoiseField  output/app/OEMLogKit  output/app/OpenWnn
rm -rf output/bin/qfipsverify  output/bin/qfp-daemon  output/bin/secure_camera_sample_client
rm -rf output/etc/acdbdata/Fluid  output/etc/acdbdata/Liquid  output/etc/acdbdata/MTP  output/etc/acdbdata/QRD
rm -rf output/etc/camera/imx179_chromatix.xml output/etc/cne/wqeclient output/etc/stargate
rm -rf output/etc/firmware/mbn_ota output/etc/firmware/tp
rm -rf output/etc/qdcm_calib_data_samsung* output/etc/policy_nx6p
rm -rf output/lib/libFNVfbEngineHAL.so output/lib/lib_fpc_tac_shared.so output/lib/hw/fingerprint.msm8996.so output/lib/hw/nfc_nci.pn54x.default.so output/lib/hw/sensors.hub.so output/lib/hw/modules/msm-buspm-dev.ko
rm -rf output/lib64/lib_fpc_tac_shared.so output/lib64/hw/fingerprint.msm8996.so output/lib64/hw/sensors.hub.so
rm -rf output/reserve/*
rm -rf output/usr/qfipsverify
rm -rf output/usr/keylayout/fpc1020.kl
rm -rf output/vendor/etc/RIDL/GoldenLogmask.dmc output/vendor/etc/RIDL/OTA-Logs.dmc output/vendor/etc/RIDL/RIDL.db
rm -rf output/vendor/lib/rfsa/adsp/libAMF_hexagon_skel.so output/vendor/lib/rfsa/adsp/libmare_hexagon_skel.so
rm -rf output/vendor/lib/libsensor_thresh.so output/vendor/lib64/libsensor_thresh.so
rm -rf output/vendor/lib64/hw/fingerprint.qcom.so_not_use

cp -rf ../tools/gemini/system/* output/
rm -rf output/app/DiracManager output/app/DiracAudioControlService output/vendor/etc/diracvdd.bin output/vendor/lib/rfsa/adsp/libdirac-appi.so

if [ -d ../tools/third-app ];then
	echo "Add Third App ..."
	rm -rf output/priv-app/KeKeMarket
	cp -rf ../tools/third-app/* output/priv-app
fi

sed -i "/\s*persist.radio.sw_mbn_update.*$/d" output/build.prop
sed -i "/\s*persist.radio.hw_mbn_update.*$/d" output/build.prop
sed -i "/\s*persist.radio.start_ota_daemon.*$/d" output/build.prop
sed -i "/\s*persist.dirac.acs.controller.*$/d" output/build.prop
sed -i "/\s*foss.*$/d" output/build.prop
sed -i "/\s*ro.qualcomm.display.paneltype.*$/d" output/build.prop
sed -i "/\s*persist.radio.rat_on.*$/d" output/build.prop
sed -i "/\s*ro.frp.pst.*$/d" output/build.prop

sed -i -e "s/ro\.dbg\.coresight\.config.*/ro\.dbg\.coresight\.config\=stm_events/g" output/build.prop
sed -i -e "s/ro\.bluetooth\.emb_wp_mode.*/\#ro\.bluetooth\.emb_wp_mode\=false/g" output/build.prop
sed -i -e "s/ro\.bluetooth\.wipower.*/\#ro\.bluetooth\.wipower\=false/g" output/build.prop
sed -i -e "s/audio\.offload\.pcm\.16bit\.enable.*/audio\.offload\.pcm\.16bit\.enable=true/g" output/build.prop
sed -i -e "s/audio\.parser\.ip\.buffer\.size.*/audio\.parser\.ip\.buffer\.size=0/g" output/build.prop
sed -i -e "s/\#telephony\.lteOnCdmaDevice.*/telephony.lteOnCdmaDevice=1/g" output/build.prop
sed -i -e "s/\#ro\.qualcomm\.cabl.*/ro\.qualcomm\.cabl=0/g" output/build.prop
sed -i -e "s/qcom\.hw\.aac\.encoder.*/qcom\.hw\.aac\.encoder=false/g" output/build.prop
sed -i -e "s/ro\.build\.product=.*/ro\.build\.product=gemini/g" output/build.prop
sed -i -e "s/ro\.build\.flavor.*/ro\.build\.flavor=gemini-user/g" output/build.prop
sed -i -e "s/ro\.product\.brand.*/ro\.product\.brand=Xiaomi/g" output/build.prop
sed -i -e "s/ro\.product\.manufacturer=.*/ro\.product\.manufacturer=Xiaomi/g" output/build.prop
sed -i -e "s/ro\.build\.product.*/ro\.build\.product=gemini/g" output/build.prop
sed -i -e "s/ro\.common\.soft.*/ro\.common\.soft=Mi5/g" output/build.prop
sed -i -e "s/ro\.display\.series.*/ro\.display\.series=Mi 5/g" output/build.prop
cat ../tools/build.prop.addition >> output/build.prop

echo "Build system.new.dat ..."

cd ../

echo "Final Step ..."

cp -rf tools/META-INF final/META-INF
cp -rf tools/gemini/boot.img final/boot.img
cp -rf workspace/output final/system 

cd final
zip -q -r "../$DEVICE-smartiscan-$VERSION-6.0.zip" 'boot.img' 'META-INF' 'system'
cd ..

rm -rf workspace final/*
