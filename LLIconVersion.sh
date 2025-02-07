#!/bin/bash

echo "✅  ==========APPicon添加版本号开始=========="
#######################################################
# 1、检查是否安装了ImageMagick
#######################################################
echo "🐛 Checking installed ImageMagick"

convertPath=`which convert`

if [[ ! -f ${convertPath} || -z ${convertPath} ]]; then
    convertValidation=true;
else
    convertValidation=false;
fi

# 未安装 提示并退出
if [ "$convertValidation" == true ]; then
    echo "❌ ImageMagick 未安装,请使用命令安装\n brew  install  imagemagick"
    exit 0;
else
    echo "✅ ImageMagick 已安装"
fi

# Assets中的appIcon文件名
APPICON_NAME="AppIcon"

# Assets中CI环境的appIcon文件名
DEBUG_APPICON_NAME="${APPICON_NAME}-CI"

FONT_PATH="/Users/effort/Library/Fonts/HackNerdFont-Bold.ttf"

## 右上角Badge参数
BADGE_CAPTION="CI"
ICON_BADGE_BACKGROUND_COLOR="rgba(255,222,111,1.0)"
ICON_BADGE_TEXT_COLOR="rgba(255,255,255,1.0)"
ICON_BADGE_FONT_SIZE=18
ICON_BADGE_HEIGHT=28

## 底部app信息参数
APP_VERSION="$MARKETING_VERSION"
APP_BUILD_NUM="$CURRENT_PROJECT_VERSION"
CAPTION="$APP_VERSION($APP_BUILD_NUM)"

ICON_INFO_TEXT_COLOR="rgba(255,255,255,1.0)"
ICON_INFO_FONT_SIZE=13
ICON_INFO_HEIGHT=20

######################################################
# 3. 复制AppIcon到AppIcon-Debug
######################################################
echo "🐛 Begin copy icon files"

# appicon路径
APPICON_SET_PATH=`find $SRCROOT -name "${APPICON_NAME}.appiconset"`

echo "🐛 APPICON_SET_PATH=$APPICON_SET_PATH"
if [ "$APPICON_SET_PATH" = "" ]; then
    exitWithMessage "❌  Get APPICON_SET_PATH failed." 0
fi

# appicon_debug路径
ASSET_PATH=`echo $(dirname ${APPICON_SET_PATH})`
DEBUG_APPICON_SET_PATH="${ASSET_PATH}/${DEBUG_APPICON_NAME}.appiconset"
echo "🐛 DEBUG_APPICON_SET_PATH=$DEBUG_APPICON_SET_PATH"
if [ "$DEBUG_APPICON_SET_PATH" = "" ]; then
    exitWithMessage "❌  Get DEBUG_APPICON_SET_PATH failed." 0
fi


# 删除appicon_debug里的文件
rm -rf $DEBUG_APPICON_SET_PATH
if [ $? != 0 ];then
    exitWithMessage "❌  Remove ${DEBUG_APPICON_SET_PATH} failed." 0
fi

# 复制appicon到appicon_debug
cp -rf $APPICON_SET_PATH $DEBUG_APPICON_SET_PATH
if [ $? != 0 ];then
    exitWithMessage "❌  Copy ${APPICON_NAME} to ${DEBUG_APPICON_NAME} failed." 0
fi

echo "✅  Finish copy icon files."

# # 处理icon,添加水印
# # Processing icon
function processIcon() {

    BASE_IMAGE_PATH=$1
    echo "BASE_IMAGE_PATH=$BASE_IMAGE_PATH"

    BASE_FLODER_PATH=`dirname $BASE_IMAGE_PATH`
    cd "$BASE_FLODER_PATH"

    # 获取图片宽度
    width=$(identify -format %w ${BASE_IMAGE_PATH})
    height=$(identify -format %h ${BASE_IMAGE_PATH})
    echo "width $width"
    echo "height $height"

    band_height=$((($height * $ICON_INFO_HEIGHT)/100))
    band_position=$(($height - $band_height))

    text_position=$(($band_position - 3))
    point_size=$((($ICON_INFO_FONT_SIZE * $width) / 100))

    badge_width=$((($width * 200) / 100))
    badge_height=$((($height * $ICON_BADGE_HEIGHT) / 100))
    badge_point_size=$((($ICON_BADGE_FONT_SIZE * $width) / 100))

    echo "band_position $band_position"
    echo "band_height $band_height"

    FONT_SIZE=$(echo "$width * .15" | bc -l)
    echo "font size $FONT_SIZE"

    ## 毛玻璃效果
    magick ${BASE_IMAGE_PATH} -blur 10x8 blurred.png

    ## 添加文字
    magick -size ${width}x${band_height} xc:none -fill 'rgba(0,0,0,0.2)' -draw "rectangle 0,0,$width,$band_height" labels-base.png
    magick -background none -size ${width}x${band_height} -pointsize $point_size -fill $ICON_INFO_TEXT_COLOR -gravity center -font $FONT_PATH caption:"$CAPTION" labels.png
    magick blurred.png labels-base.png -geometry +0+$band_position -composite labels.png -geometry +0+$text_position -geometry +${w}-${h} -composite blurred.png

    ## 角标
    magick -background $ICON_BADGE_BACKGROUND_COLOR -size ${badge_width}x${badge_height} -pointsize $badge_point_size -fill $ICON_BADGE_TEXT_COLOR -gravity center -font $FONT_PATH caption:$BADGE_CAPTION badge.png
    magick badge.png -background none -rotate 45 badge.png
    magick blurred.png badge.png -gravity SouthWest -composite ${BASE_IMAGE_PATH}

    rm blurred.png
    rm labels-base.png
    rm labels.png
    rm badge.png
}



#######################################################
# 4. 处理AppIcon-Debug
#######################################################
find "$DEBUG_APPICON_SET_PATH" -type f -name "*.png" -print0 |

while IFS= read -r -d '' file; do

echo "🐛🐛 ${file}"
# 调用 processIcon 方法
processIcon "${file}"

done

echo "✅  ==========APPicon添加版本号结束=========="
