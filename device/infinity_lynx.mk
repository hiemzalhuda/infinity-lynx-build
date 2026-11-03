# Infinity-X product makefile for Pixel 7a (lynx), Android 17.
# Adapted 2026-11-01 from LineageOS lineage_lynx.mk (lineage-24.0),
# because Infinity-X-Devices has no branch 17 device tree for lynx.
# Base device config is Lineage 24.0; common config is Infinity-X.

DEVICE_CODENAME := lynx
DEVICE_PATH := device/google/lynx
VENDOR_PATH := vendor/google/lynx

INFINITY_MAINTAINER := HIEMZ

# Inherit Infinity-X common stuff
$(call inherit-product, vendor/infinity/config/common_full_phone.mk)

# Inherit device configuration
$(call inherit-product, $(DEVICE_PATH)/aosp_$(DEVICE_CODENAME).mk)

# Device identifier. This must come after all inclusions
PRODUCT_NAME := infinity_$(DEVICE_CODENAME)
PRODUCT_SYSTEM_BRAND := google
PRODUCT_SYSTEM_MANUFACTURER := Google
PRODUCT_SYSTEM_NAME := generic_system_google

# Boot animation
TARGET_SCREEN_HEIGHT := 2400
TARGET_SCREEN_WIDTH := 1080

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="lynx-user 17 CP3A.261005.002.A1 16269273 release-keys" \
    BuildSystemDesc="generic_system_google-user 17 CP3A.261005.002.A1 16269273 release-keys" \
    BuildFingerprint=google/lynx/lynx:17/CP3A.261005.002.A1/16269273:user/release-keys \
    BuildSystemFingerprint=google/generic_system_google/generic:17/CP3A.261005.002.A1/16269273:user/release-keys \
    DeviceProduct=$(DEVICE_CODENAME)

# Private signing keys (generated 2026-11-01, NOT in any repo)
PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/infinity/security/releasekey

$(call inherit-product, $(VENDOR_PATH)/$(DEVICE_CODENAME)-vendor.mk)

# Build Mainline APEX modules from source (fix build #2: override RELEASE_APEX_CONTRIBUTIONS_* Google prebuilts, 2026-11-01)
PRODUCT_MODULE_BUILD_FROM_SOURCE := true

# Allow GMS system-partition files past generic_system.mk artifact path
# requirement (fix build #6, 2026-11-01: Soong bootstrap failed on these 4
# entries; allowlist is the sanctioned mechanism, cf. vendor/infinity
# config/common.mk precedent; GAPPS files kept, not removed)
PRODUCT_ARTIFACT_PATH_REQUIREMENT_ALLOWED_LIST += \
    system/apex/com.google.android.extservices.apex \
    system/app/GoogleExtShared/GoogleExtShared.apk \
    system/app/GooglePrintRecommendationService/GooglePrintRecommendationService.apk \
    system/priv-app/TagGoogle/TagGoogle.apk \
    system/etc/permissions/privapp-permissions-google.xml \
    system/media/bootanimation.zip
