#!/usr/bin/env python3
"""
生成 Water Tracker App 图标
- 蓝色渐变背景 + 白色水滴图标
- 生成 Android 和 iOS 所需的所有尺寸
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
import math

# 使用相对路径，兼容 CI 环境
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(SCRIPT_DIR, '..', 'assets')
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Android 图标尺寸
ANDROID_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
    "playstore": 512,  # Google Play 商店图标
}

# iOS 图标尺寸
IOS_SIZES = {
    "Icon-App-20x20@1x": 20,
    "Icon-App-20x20@2x": 40,
    "Icon-App-20x20@3x": 60,
    "Icon-App-29x29@1x": 29,
    "Icon-App-29x29@2x": 58,
    "Icon-App-29x29@3x": 87,
    "Icon-App-40x40@1x": 40,
    "Icon-App-40x40@2x": 80,
    "Icon-App-40x40@3x": 120,
    "Icon-App-60x60@2x": 120,
    "Icon-App-60x60@3x": 180,
    "Icon-App-76x76@1x": 76,
    "Icon-App-76x76@2x": 152,
    "Icon-App-83.5x83.5@2x": 167,
    "Icon-App-1024x1024@1x": 1024,  # App Store
}


def create_gradient_background(size, color1=(41, 128, 185), color2=(52, 152, 219)):
    """创建蓝色渐变背景"""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    for y in range(size):
        ratio = y / size
        r = int(color1[0] + (color2[0] - color1[0]) * ratio)
        g = int(color1[1] + (color2[1] - color1[1]) * ratio)
        b = int(color1[2] + (color2[2] - color1[2]) * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    return img


def draw_water_drop(draw, cx, cy, size, color=(255, 255, 255, 255)):
    """绘制水滴形状"""
    # 水滴路径
    drop_width = size * 0.35
    drop_height = size * 0.5
    
    # 水滴主体（椭圆形）
    body_top = cy - drop_height * 0.1
    body_bottom = cy + drop_height * 0.45
    body_left = cx - drop_width * 0.5
    body_right = cx + drop_width * 0.5
    
    # 绘制水滴主体
    draw.ellipse(
        [body_left, body_top, body_right, body_bottom],
        fill=color
    )
    
    # 水滴尖端（三角形）
    tip_top = cy - drop_height * 0.45
    tip_left = cx - drop_width * 0.3
    tip_right = cx + drop_width * 0.3
    
    draw.polygon([
        (cx, tip_top),
        (tip_left, cy - drop_height * 0.05),
        (tip_right, cy - drop_height * 0.05),
    ], fill=color)
    
    # 高光效果
    highlight_color = (255, 255, 255, 80)
    highlight_size = drop_width * 0.25
    highlight_cx = cx - drop_width * 0.15
    highlight_cy = body_top + (body_bottom - body_top) * 0.3
    draw.ellipse(
        [highlight_cx - highlight_size, highlight_cy - highlight_size,
         highlight_cx + highlight_size, highlight_cy + highlight_size],
        fill=highlight_color
    )


def create_icon(size, is_rounded=True):
    """创建一个图标"""
    img = create_gradient_background(size)
    draw = ImageDraw.Draw(img)
    
    # 绘制水滴
    draw_water_drop(draw, size // 2, size // 2, size)
    
    # 圆角处理
    if is_rounded:
        # 创建圆角遮罩
        mask = Image.new("L", (size, size), 0)
        mask_draw = ImageDraw.Draw(mask)
        radius = size // 4
        mask_draw.rounded_rectangle([0, 0, size, size], radius=radius, fill=255)
        
        # 应用圆角
        output = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        output.paste(img, (0, 0), mask)
        return output
    
    return img


def generate_android_icons():
    """生成 Android 图标"""
    print("📱 生成 Android 图标...")
    
    for folder, size in ANDROID_SIZES.items():
        if folder == "playstore":
            # Play 商店图标单独存放
            icon = create_icon(size, is_rounded=False)
            path = os.path.join(OUTPUT_DIR, "playstore-icon.png")
            icon.save(path, "PNG")
            print(f"  ✅ {folder}: {size}x{size} -> {path}")
        else:
            # Android mipmap 图标
            icon = create_icon(size, is_rounded=True)
            path = os.path.join(OUTPUT_DIR, f"android-{folder}-icon.png")
            icon.save(path, "PNG")
            print(f"  ✅ {folder}: {size}x{size}")


def generate_ios_icons():
    """生成 iOS 图标"""
    print("🍎 生成 iOS 图标...")
    
    for name, size in IOS_SIZES.items():
        icon = create_icon(size, is_rounded=True)
        path = os.path.join(OUTPUT_DIR, f"{name}.png")
        icon.save(path, "PNG")
        print(f"  ✅ {name}: {size}x{size}")


def generate_splash_background():
    """生成启动页背景"""
    print("🖼️ 生成启动页背景...")
    
    # iPhone 启动页尺寸
    sizes = [
        ("splash-750x1334", 750, 1334),    # iPhone 8/SE
        ("splash-1125x2436", 1125, 2436),   # iPhone X/11 Pro
        ("splash-1170x2532", 1170, 2532),   # iPhone 12/13/14
        ("splash-1284x2778", 1284, 2778),   # iPhone 12/13/14 Pro Max
        ("splash-1920x1080", 1920, 1080),   # Android 1080p
        ("splash-1440x2560", 1440, 2560),   # Android 2K
    ]
    
    for name, w, h in sizes:
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # 渐变背景
        for y in range(h):
            ratio = y / h
            r = int(41 + (52 - 41) * ratio)
            g = int(128 + (152 - 128) * ratio)
            b = int(185 + (219 - 185) * ratio)
            draw.line([(0, y), (w, y)], fill=(r, g, b, 255))
        
        # 中央大水滴
        drop_size = min(w, h) * 0.3
        draw_water_drop(draw, w // 2, h // 2, int(drop_size))
        
        path = os.path.join(OUTPUT_DIR, f"{name}.png")
        img.save(path, "PNG")
        print(f"  ✅ {name}: {w}x{h}")


if __name__ == "__main__":
    print("🎨 Water Tracker 图标生成器")
    print("=" * 40)
    
    generate_android_icons()
    generate_ios_icons()
    generate_splash_background()
    
    print("=" * 40)
    print(f"✅ 所有图标已生成到 {OUTPUT_DIR}/")
    print(f"📁 文件列表:")
    for f in sorted(os.listdir(OUTPUT_DIR)):
        path = os.path.join(OUTPUT_DIR, f)
        size_kb = os.path.getsize(path) // 1024
        print(f"   {f} ({size_kb}KB)")
