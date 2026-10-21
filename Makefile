THEOS_PACKAGE_SCHEME = rootless

ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:17.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LilyWhite

LilyWhite_FILES = Tweak.x
LilyWhite_CFLAGS = -fobjc-arc -Wno-unused-parameter -Wno-error=deprecated-declarations
LilyWhite_FRAMEWORKS = UIKit QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
